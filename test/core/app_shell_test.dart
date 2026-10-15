import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/widgets/widgets.dart';
import 'package:hayya/features/design_preview/presentation/design_preview_screen.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/qibla/presentation/qibla_screen.dart';
import 'package:hayya/features/settings/presentation/settings_screen.dart';
import 'package:hayya/features/tracker/presentation/tracker_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  group('phone', () {
    testWidgets('bottom bar switches between the four tabs', (tester) async {
      await pumpHayyaApp(tester);

      expect(find.byType(HayyaNavBar), findsOneWidget);
      expect(find.byType(HayyaNavRail), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);

      for (final (label, screen) in [
        ('Qibla', QiblaScreen),
        ('Tracker', TrackerScreen),
        ('Settings', SettingsScreen),
        ('Home', HomeScreen),
      ]) {
        await tester.tap(
          find.descendant(
            of: find.byType(HayyaNavBar),
            matching: find.text(label),
          ),
        );
        await settle(tester, rounds: 2);
        expect(find.byType(screen), findsOneWidget, reason: label);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('language switch applies and persists', (tester) async {
      await pumpHayyaApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester, rounds: 2);

      await tester.tap(find.text('العربية'));
      await settle(tester);

      expect(getIt<AppPreferences>().languageCode, 'ar');
      expect(find.text('الإعدادات'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.byType(HayyaNavBar))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('theme switch applies and persists', (tester) async {
      await pumpHayyaApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester, rounds: 2);

      await tester.tap(find.text('Dark'));
      await settle(tester);

      expect(getIt<AppPreferences>().themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
    });

    testWidgets('starts in the saved language and theme', (tester) async {
      await pumpHayyaApp(
        tester,
        prefs: {'language_code': 'ar', 'theme_mode': 'dark'},
      );
      expect(find.text('الرئيسية'), findsWidgets);
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('design preview opens from Settings in debug', (tester) async {
      await pumpHayyaApp(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester, rounds: 2);

      await tapVisible(tester, find.text('Design system'));
      await settle(tester);
      expect(find.byType(DesignPreviewScreen), findsOneWidget);
      // Full screen: the bar is covered.
      expect(find.byType(HayyaNavBar).hitTestable(), findsNothing);
    });
  });

  group('tablet', () {
    for (final lang in ['en', 'ar']) {
      testWidgets('rail on the start edge ($lang)', (tester) async {
        await pumpHayyaApp(
          tester,
          size: tabletSize,
          prefs: {'language_code': lang},
        );

        expect(find.byType(HayyaNavRail), findsOneWidget);
        expect(find.byType(HayyaNavBar), findsNothing);

        final rail = tester.getRect(find.byType(HayyaNavRail));
        final body = tester.getRect(find.byType(HomeScreen));
        if (lang == 'ar') {
          expect(rail.left, greaterThanOrEqualTo(body.right));
        } else {
          expect(rail.right, lessThanOrEqualTo(body.left));
        }

        await tester.tap(
          find.descendant(
            of: find.byType(HayyaNavRail),
            matching: find.text(lang == 'ar' ? 'القبلة' : 'Qibla'),
          ),
        );
        await settle(tester, rounds: 2);
        expect(find.byType(QiblaScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
