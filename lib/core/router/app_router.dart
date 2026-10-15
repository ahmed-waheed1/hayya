import 'package:go_router/go_router.dart';

import '../../features/design_preview/presentation/design_preview_screen.dart';

abstract final class AppRoutes {
  // TEMPORARY: the design-system preview is the start route until real
  // screens exist. Remove with lib/features/design_preview/.
  static const designPreview = '/';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.designPreview,
  routes: [
    GoRoute(
      path: AppRoutes.designPreview,
      builder: (context, state) => const DesignPreviewScreen(),
    ),
  ],
);
