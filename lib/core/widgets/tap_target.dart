import 'package:flutter/widgets.dart';

import '../theme/hayya_spacing.dart';

/// Gives a small visual control the 44 × 44 minimum hit area without
/// changing how it looks.
class TapTarget extends StatelessWidget {
  const TapTarget({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: HayyaSpacing.minTouchTarget,
          minHeight: HayyaSpacing.minTouchTarget,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}
