import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/prayer_times/presentation/home_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/timetable/presentation/timetable_screen.dart';
import '../../features/tracker/presentation/tracker_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const timetable = '/home/timetable';
  static const qibla = '/qibla';
  static const tracker = '/tracker';
  static const settings = '/settings';
}

/// Builds a fresh router; [HayyaApp] creates one for its lifetime. It
/// opens on onboarding when [onboarding] is true (first launch), else Home.
GoRouter createAppRouter({bool onboarding = false}) {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: onboarding ? AppRoutes.onboarding : AppRoutes.home,
    routes: [
      // Full screen, without the navigation bar or rail. Leaving it goes
      // to Home, so it never comes back with Back.
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // Inside the Home branch: the bar/rail stays, Home selected.
                  GoRoute(
                    path: 'timetable',
                    builder: (context, state) => const TimetableScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.qibla,
                builder: (context, state) => const QiblaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tracker,
                builder: (context, state) => const TrackerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
