import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/di/injection.dart';
import 'package:hayya/core/preferences/app_preferences.dart';
import 'package:hayya/core/services/location_service.dart';
import 'package:hayya/features/onboarding/presentation/onboarding_screen.dart';
import 'package:hayya/features/prayer_times/presentation/home_screen.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/location_status_view.dart';
import 'package:hayya/features/prayer_times/presentation/widgets/next_prayer_card.dart';

import '../../helpers/fake_location_service.dart';
import '../../helpers/fake_notification_service.dart';
import '../../helpers/pump_app.dart';

final midday = DateTime(2026, 10, 15, 13);

late FakeLocationService location;
late FakeNotificationService notifications;

/// A first launch: nothing known, nothing asked yet.
Future<void> pumpFirstLaunch(
  WidgetTester tester, {
  List<LocationResult>? results,
  bool notificationsAllowed = true,
  String lang = 'en',
}) async {
  location = FakeLocationService(results: results, places: [alexandria]);
  notifications = FakeNotificationService(
    allowed: false,
    grantOnRequest: notificationsAllowed,
  );
  await pumpHayyaApp(
    tester,
    onboarding: true,
    location: location,
    notifications: notifications,
    now: () => midday,
    prefs: {'language_code': lang},
  );
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tapVisible(tester, find.text(text));
  await settle(tester, rounds: 2);
}

bool get saved => getIt<AppPreferences>().onboardingDone;

void main() {
  testWidgets('first launch opens on the welcome slide', (tester) async {
    await pumpFirstLaunch(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Welcome to Hayya'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    // No prompts before the slides explain them.
    expect(location.permissionRequests, isEmpty);
    expect(notifications.permissionRequests, 0);
  });

  testWidgets('later launches open on Home', (tester) async {
    await pumpHayyaApp(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the language toggle switches to Arabic', (tester) async {
    await pumpFirstLaunch(tester);
    await tapText(tester, 'العربية');
    expect(find.text('أهلًا بك في حيّ'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.rtl,
    );
    expect(getIt<AppPreferences>().languageCode, 'ar');
  });

  testWidgets('allowing both: Home opens with prayer times ready', (
    tester,
  ) async {
    await pumpFirstLaunch(tester);
    await tapText(tester, 'Get started');
    expect(find.text('STEP 1 OF 2'), findsOneWidget);
    await tapText(tester, 'Allow location');

    expect(location.permissionRequests, [true]);
    expect(find.text('Never miss the adhan'), findsOneWidget);
    // The next prayer at 13:00 in Cairo, as a preview.
    expect(find.textContaining('Asr ·'), findsOneWidget);

    await tapText(tester, 'Allow notifications');
    expect(notifications.permissionRequests, 1);
    expect(saved, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(NextPrayerCard), findsOneWidget);
    // Home doesn't ask again.
    expect(location.permissionRequests, [true, false]);
    expect(notifications.permissionRequests, 1);
  });

  testWidgets('location denied: choose a city manually', (tester) async {
    await pumpFirstLaunch(
      tester,
      results: [const LocationFailed(LocationFailure.permissionDenied)],
    );
    await tapText(tester, 'Get started');
    await tapText(tester, 'Allow location');
    expect(
      find.textContaining('Without your location, choose your city'),
      findsOneWidget,
    );
    expect(find.text('Continue without location'), findsOneWidget);

    await tapText(tester, 'Choose a city manually');
    await tester.enterText(find.byType(TextField), 'Alex');
    await settle(tester, rounds: 3);
    await tapText(tester, 'Alexandria');

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Never miss the adhan'), findsOneWidget);
    await tapText(tester, 'Maybe later');
    expect(saved, isTrue);
    expect(find.text('Alexandria'), findsOneWidget); // Home's city chip
    expect(find.byType(NextPrayerCard), findsOneWidget);
    expect(notifications.permissionRequests, 0);
  });

  testWidgets('continuing without location: Home explains and can ask', (
    tester,
  ) async {
    await pumpFirstLaunch(
      tester,
      results: [const LocationFailed(LocationFailure.permissionDenied)],
    );
    await tapText(tester, 'Get started');
    await tapText(tester, 'Allow location');
    await tapText(tester, 'Continue without location');
    await tapText(tester, 'Maybe later');

    expect(find.byType(LocationErrorView), findsOneWidget);
    expect(find.text('Allow location'), findsOneWidget);
    // Home didn't prompt again on its own.
    expect(location.permissionRequests, [true, false]);
  });

  testWidgets('notifications refused: explains, then Home', (tester) async {
    await pumpFirstLaunch(tester, notificationsAllowed: false);
    await tapText(tester, 'Get started');
    await tapText(tester, 'Allow location');
    await tapText(tester, 'Allow notifications');

    expect(
      find.textContaining('You can turn on the adhan any time in Settings'),
      findsOneWidget,
    );
    expect(saved, isFalse);
    await tapText(tester, 'Continue');
    expect(saved, isTrue);
    expect(find.byType(NextPrayerCard), findsOneWidget);
  });

  testWidgets('blocked for good: a link to the system settings', (
    tester,
  ) async {
    await pumpFirstLaunch(
      tester,
      results: [
        const LocationFailed(LocationFailure.permissionDeniedForever),
        LocationFound(cairo),
      ],
    );
    await tapText(tester, 'Get started');
    await tapText(tester, 'Allow location');
    await tapText(tester, 'Open Settings');
    expect(location.appSettingsOpened, 1);

    // Back in the app, it checks again without prompting.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester, rounds: 2);
    expect(location.permissionRequests, [true, false]);
    expect(find.text('Never miss the adhan'), findsOneWidget);
  });

  testWidgets('Skip goes straight to Home, for good', (tester) async {
    await pumpFirstLaunch(tester);
    await tapText(tester, 'Skip');
    expect(saved, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(location.permissionRequests, [false]);
    expect(notifications.permissionRequests, 0);
  });

  testWidgets('back returns to the previous slide', (tester) async {
    await pumpFirstLaunch(tester);
    await tapText(tester, 'Get started');
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester, rounds: 2);
    expect(find.text('Welcome to Hayya'), findsOneWidget);
  });
}
