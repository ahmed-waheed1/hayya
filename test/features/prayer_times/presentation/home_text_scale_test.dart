import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/widgets/widgets.dart';

import '../../../helpers/pump_app.dart';

const smallPhone = Size(320, 568);
const phoneLandscape = Size(844, 390);
const tabletPortrait = Size(834, 1194);

/// Maghrib is current: the longest name, with the NOW badge under it.
final evening = DateTime(2026, 10, 15, 18, 30);

/// How much the [FittedBox] around [text] shrinks it (1 = not at all).
double shrinkOf(WidgetTester tester, Finder text) {
  final box = tester.renderObject<RenderBox>(
    find.ancestor(of: text, matching: find.byType(FittedBox)).first,
  );
  final child = (box as RenderObjectWithChildMixin<RenderBox>).child!;
  return box.size.width / child.size.width;
}

void main() {
  for (final (name, size) in [
    ('phone', phoneSize),
    ('small phone', smallPhone),
    ('phone landscape', phoneLandscape),
    ('tablet', tabletSize),
    ('tablet portrait', tabletPortrait),
  ]) {
    for (final lang in ['en', 'ar']) {
      for (final scale in [1.0, 1.3, 1.6, 2.0]) {
        testWidgets('$name · $lang · ${scale}x text: Home rows fit', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpHayyaApp(
            tester,
            size: size,
            prefs: {'language_code': lang},
            now: () => evening,
          );

          expect(tester.takeException(), isNull);

          // Titles keep to one line; the link moves under "Today" instead.
          for (final title in [
            lang == 'ar' ? 'اليوم' : 'Today',
            lang == 'ar' ? 'جدول الشهر' : 'Monthly timetable',
          ]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(title),
            );
            expect(
              paragraph.size.width,
              greaterThanOrEqualTo(
                paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
              ),
              reason: '"$title" wraps',
            );
          }

          final rows = find.byType(PrayerRow);
          expect(rows, findsNWidgets(6));

          for (final element in rows.evaluate()) {
            final row = find.byWidget(element.widget);
            final widget = element.widget as PrayerRow;
            final name = find.descendant(
              of: row,
              matching: find.text(widget.name),
            );
            final time = find.descendant(
              of: row,
              matching: find.textContaining(widget.time, findRichText: true),
            );

            // Neither is cut short, nor drawn smaller than at 1.0x (so
            // not shrunk at all at 1.0x).
            expect(
              tester.renderObject<RenderParagraph>(name).didExceedMaxLines,
              isFalse,
              reason: '${widget.name} is truncated',
            );
            for (final (label, text) in [('name', name), ('time', time)]) {
              final drawn = shrinkOf(tester, text) * scale;
              expect(
                drawn,
                greaterThanOrEqualTo(0.999),
                reason: '${widget.name} $label drawn at ${drawn}x',
              );
            }

            // At 1.0x the time sits beside the name, as designed.
            if (scale == 1.0) {
              expect(
                tester.getRect(time).top,
                lessThan(tester.getRect(name).bottom),
                reason: '${widget.name}: time wrapped under the name',
              );
            }
          }
        });
      }
    }
  }
}
