import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/prayer_times/data/adhan_prayer_times_repository.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/timetable_link.dart';
import 'package:hayya/features/timetable/presentation/timetable_screen.dart';
import 'package:hayya/features/timetable/presentation/widgets/timetable_table.dart';

import '../../../helpers/fake_location_service.dart';
import '../../../helpers/pump_app.dart';

const smallPhone = Size(320, 568);
const tabletPortrait = Size(834, 1194);
const phoneLandscape = Size(844, 390);

/// Boots the app at [now] and opens the timetable from Home's link.
///
/// [homeMayOverflow] drops an overflow Home itself reports before the
/// timetable opens: Home's PrayerRow is a few pixels too short in Arabic
/// in phone landscape and with large text (as on master), which is
/// outside this screen.
Future<void> openTimetable(
  WidgetTester tester, {
  DateTime? now,
  String lang = 'en',
  String theme = 'light',
  Size size = phoneSize,
  Map<String, Object> prefs = const {},
  bool homeMayOverflow = false,
}) async {
  final clock = now ?? DateTime(2026, 10, 28, 13);
  await pumpHayyaApp(
    tester,
    size: size,
    prefs: {'language_code': lang, 'theme_mode': theme, ...prefs},
    now: () => clock,
  );
  if (homeMayOverflow) {
    final error = tester.takeException();
    expect(error, anyOf(isNull, predicate((e) => '$e'.contains('overflowed'))));
  }
  await tapVisible(tester, find.byType(TimetableLink));
  await settle(tester, rounds: 3);
  expect(find.byType(TimetableScreen), findsOneWidget);
}

Finder get rows => find.byType(TimetableRow);

Finder get todayRow => find.byWidgetPredicate(
  (widget) => widget is TimetableRow && widget.isToday,
);

/// The "h:mm" text of [prayer] on [date] in Cairo, 12-hour.
String timeOf(Prayer prayer, DateTime date) {
  final time = const AdhanPrayerTimesRepository()
      .timesFor(
        date,
        cairo.coordinates,
        const PrayerCalculationSettings(),
      )[prayer]
      .time;
  return '${(time.hour + 11) % 12 + 1}:${time.minute.toString().padLeft(2, '0')}';
}

/// How far the [FittedBox]es in [finder] shrink their content: 1 when
/// everything fits at full size.
double smallestScale(WidgetTester tester, Finder finder) {
  var smallest = 1.0;
  for (final element
      in find
          .descendant(of: finder, matching: find.byType(FittedBox))
          .evaluate()) {
    final box = element.renderObject! as RenderBox;
    final child = (box as RenderObjectWithChildMixin<RenderBox>).child!;
    final scale = math.min(
      box.size.width / child.size.width,
      box.size.height / child.size.height,
    );
    smallest = math.min(smallest, scale);
  }
  return smallest;
}

void main() {
  testWidgets('opens from Home with today highlighted and scrolled into view', (
    tester,
  ) async {
    await openTimetable(tester);

    expect(find.text('Monthly timetable'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Rabi al-Thani – Jumada al-Ula 1448'), findsOneWidget);
    expect(
      find.textContaining('Cairo · Egyptian General Authority'),
      findsOneWidget,
    );

    expect(todayRow, findsOneWidget);
    final today = tester.widget<TimetableRow>(todayRow);
    expect(today.day.date, DateTime(2026, 10, 28));

    // The 28th is far below the first screenful; it was scrolled to.
    final list = tester.getRect(find.byType(ListView));
    final row = tester.getRect(todayRow);
    expect(row.top, greaterThanOrEqualTo(list.top));
    expect(row.bottom, lessThanOrEqualTo(list.bottom));
    expect(
      find.descendant(of: rows, matching: find.text('1')),
      findsNothing,
      reason: 'the first rows are scrolled away',
    );

    // Times as Home calculates them, without AM/PM on a phone.
    for (final prayer in Prayer.values) {
      expect(
        find.descendant(
          of: todayRow,
          matching: find.text(
            timeOf(prayer, DateTime(2026, 10, 28)),
            findRichText: true,
          ),
        ),
        findsOneWidget,
        reason: prayer.name,
      );
    }
    expect(
      find.descendant(
        of: find.byType(TimetableTable),
        matching: find.textContaining(RegExp('AM|PM'), findRichText: true),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('each row shows the Gregorian day, weekday and Hijri day', (
    tester,
  ) async {
    await openTimetable(tester);
    final row = find.ancestor(of: find.text('28'), matching: rows);
    expect(find.descendant(of: row, matching: find.text('We')), findsOneWidget);
    // 28 October 2026 is 17 Jumada al-Ula 1448.
    expect(find.descendant(of: row, matching: find.text('17')), findsOneWidget);
    expect(
      tester.getSemantics(row.first).label,
      startsWith('Today, Wednesday, 28 October 2026, 17 Jumada al-Ula 1448 AH'),
    );
  });

  testWidgets('pages through months, across the end of the year', (
    tester,
  ) async {
    await openTimetable(tester, now: DateTime(2026, 12, 20, 9));
    expect(find.text('December 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pump();
    expect(find.text('January 2027'), findsOneWidget);
    expect(find.text('Rajab – Sha’ban 1448'), findsOneWidget);
    expect(todayRow, findsNothing);
    // Another month opens at its first day.
    expect(find.descendant(of: rows, matching: find.text('1')), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Previous month'));
    await tester.pump();
    expect(find.text('November 2026'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pump();
    expect(find.text('December 2026'), findsOneWidget);
    expect(todayRow, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a Hijri year change in the month card', (tester) async {
    await openTimetable(tester, now: DateTime(2026, 6, 10, 9));
    expect(find.text('Dhu al-Hijjah 1447 – Muharram 1448'), findsOneWidget);
  });

  testWidgets('back returns to Home', (tester) async {
    await openTimetable(tester);
    await tester.tap(find.bySemanticsLabel('Back to Home'));
    await settle(tester, rounds: 3);
    expect(find.byType(TimetableScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  group('formatting', () {
    testWidgets('Arabic uses Arabic-Indic digits and Arabic names', (
      tester,
    ) async {
      await openTimetable(tester, lang: 'ar');
      expect(find.text('جدول الشهر'), findsOneWidget);
      expect(find.text('أكتوبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('ربيع الآخر – جمادى الأولى ١٤٤٨'), findsOneWidget);
      expect(
        find.descendant(of: todayRow, matching: find.text('٢٨')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: todayRow, matching: find.text('أرب')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arabic with Western numerals', (tester) async {
      await openTimetable(tester, lang: 'ar', prefs: {'numerals': 'western'});
      expect(find.text('أكتوبر 2026'), findsOneWidget);
      expect(
        find.descendant(of: todayRow, matching: find.text('28')),
        findsOneWidget,
      );
    });

    testWidgets('24-hour times', (tester) async {
      await openTimetable(tester, prefs: {'time_format': 'twentyFourHour'});
      final maghrib = const AdhanPrayerTimesRepository()
          .timesFor(
            DateTime(2026, 10, 28),
            cairo.coordinates,
            const PrayerCalculationSettings(),
          )[Prayer.maghrib]
          .time;
      expect(
        find.descendant(
          of: todayRow,
          matching: find.text(
            '${maghrib.hour}:${maghrib.minute.toString().padLeft(2, '0')}',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('24-hour'), findsOneWidget);
    });

    testWidgets('tablets have room for AM/PM', (tester) async {
      await openTimetable(tester, size: tabletSize);
      expect(
        find.descendant(
          of: todayRow,
          matching: find.text(
            '${timeOf(Prayer.fajr, DateTime(2026, 10, 28))} AM',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('layout', () {
    for (final (name, size) in [
      ('phone', phoneSize),
      ('small phone', smallPhone),
      ('phone landscape', phoneLandscape),
      ('tablet', tabletSize),
      ('tablet portrait', tabletPortrait),
    ]) {
      for (final lang in ['en', 'ar']) {
        for (final theme in ['light', 'dark']) {
          testWidgets('$name · $lang · $theme fits without overflow', (
            tester,
          ) async {
            await openTimetable(
              tester,
              size: size,
              lang: lang,
              theme: theme,
              homeMayOverflow: size == phoneLandscape,
            );
            expect(tester.takeException(), isNull);
            expect(todayRow, findsOneWidget);
            // Every cell fits at full size, or close to it on the smallest
            // phone.
            final scale = smallestScale(tester, find.byType(TimetableTable));
            expect(
              scale,
              greaterThanOrEqualTo(size == smallPhone ? 0.9 : 1.0),
              reason: 'cells shrink to ${scale.toStringAsFixed(2)}',
            );
          });
        }
      }
    }

    testWidgets('large text keeps rows readable', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openTimetable(tester, lang: 'ar', homeMayOverflow: true);
      expect(tester.takeException(), isNull);
      expect(todayRow, findsOneWidget);
    });
  });

  testWidgets('Home links to the timetable on phones and tablets', (
    tester,
  ) async {
    for (final size in [phoneSize, tabletSize]) {
      await pumpHayyaApp(tester, size: size);
      expect(find.byType(TimetableLink), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TimetableLink),
          matching: find.byType(HayyaIcon),
        ),
        findsNWidgets(size == phoneSize ? 2 : 1),
      );
    }
  });
}
