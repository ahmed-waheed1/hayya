import 'package:flutter/material.dart';

import '../theme/hayya_radius.dart';
import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';

enum HayyaElevation {
  /// Rows inside a card, settings groups.
  flat,

  /// All cards.
  card,

  /// Next-prayer card only.
  hero,
}

/// Surface container with the design system's radius and shadow tokens.
/// In dark theme the card/flat shadows are empty by design.
class HayyaCard extends StatelessWidget {
  const HayyaCard({
    super.key,
    required this.child,
    this.elevation = HayyaElevation.card,
    this.padding,
    this.radius,
    this.color,
    this.onTap,
  });

  final Widget child;
  final HayyaElevation elevation;

  /// Defaults to the 20 px card padding.
  final EdgeInsetsGeometry? padding;

  /// Defaults to radius xl (20).
  final double? radius;

  /// Defaults to surface.
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final borderRadius = BorderRadius.circular(radius ?? HayyaRadius.xl);
    final shadows = switch (elevation) {
      HayyaElevation.flat => c.flatShadow,
      HayyaElevation.card => c.cardShadow,
      HayyaElevation.hero => c.heroShadow,
    };

    Widget content = Padding(
      padding: padding ?? EdgeInsetsDirectional.all(HayyaSpacing.cardPadding),
      child: child,
    );
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: Material(
        color: color ?? c.surface,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
