import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/design_preview/presentation/design_preview_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/qibla/presentation/qibla_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tracker/presentation/tracker_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const home = '/home';
  static const qibla = '/qibla';
  static const tracker = '/tracker';
  static const settings = '/settings';

  // TEMPORARY, debug builds only: opened from Settings. Remove with
  // lib/features/design_preview/.
  static const designPreview = '/settings/design-preview';
}

/// Builds a fresh router; [HayyaApp] creates one for its lifetime.
GoRouter createAppRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
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
                routes: [
                  if (kDebugMode)
                    GoRoute(
                      path: 'design-preview',
                      // Full screen, above the navigation bar/rail.
                      parentNavigatorKey: rootKey,
                      builder: (context, state) => const DesignPreviewScreen(),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
