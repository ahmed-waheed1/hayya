import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  /// Phone below, tablet at or above.
  static const double tablet = 600;
}

extension BoxConstraintsBreakpoints on BoxConstraints {
  bool get isTablet => maxWidth >= Breakpoints.tablet;
}

/// Picks a layout from the space actually available to it (not the screen),
/// so it also works inside split views and side panels.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.phone,
    required this.tablet,
  });

  final WidgetBuilder phone;
  final WidgetBuilder tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.isTablet ? tablet(context) : phone(context),
    );
  }
}
