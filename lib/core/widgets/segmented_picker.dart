import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';

@immutable
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.sublabel,
  });

  final T value;
  final String label;

  /// A smaller second line ("Later Asr"). With any, every segment is 44
  /// tall instead of 40.
  final String? sublabel;
}

/// `SegmentedPicker<T>`: surface-2 track, selected segment lifts to
/// selectedSurface. Segment order follows the ambient Directionality.
///
/// With a bounded width the segments fill it: equal widths when every label
/// fits that way, otherwise each keeps its natural width plus an equal share
/// of what is left. When even the natural widths don't fit, segments shrink
/// in proportion and ellipsize. Unbounded, it sizes to its content.
class SegmentedPicker<T> extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final selectedStyle = type
        .style(14, FontWeight.w700, height: 1.2)
        .copyWith(color: c.text);
    final idleStyle = type
        .style(14, FontWeight.w600, height: 1.2)
        .copyWith(color: c.muted);
    final subStyle = type
        .style(11, FontWeight.w600, height: 1.2)
        .copyWith(color: c.muted);
    final twoLines = options.any((o) => o.sublabel != null);
    final trackPadding = 4.r;
    final gap = 4.r;
    final segmentPadding = 16.r;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = constraints.hasBoundedWidth
            ? _segmentWidths(
                context,
                // Measure bold so the selection never changes the layout.
                style: selectedStyle,
                subStyle: subStyle,
                padding: segmentPadding,
                available:
                    constraints.maxWidth -
                    2 * trackPadding -
                    gap * (options.length - 1),
              )
            : null;
        return Container(
          padding: EdgeInsetsDirectional.all(trackPadding),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(HayyaRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              for (final (i, option) in options.indexed)
                SizedBox(
                  width: widths?[i],
                  child: _Segment(
                    label: option.label,
                    selected: option.value == value,
                    onTap: () => onChanged(option.value),
                    selectedStyle: selectedStyle,
                    idleStyle: idleStyle,
                    sublabel: option.sublabel,
                    subStyle: subStyle,
                    height: twoLines ? 44.r : 40.r,
                    selectedColor: c.selectedSurface,
                    padding: segmentPadding,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<double> _segmentWidths(
    BuildContext context, {
    required TextStyle style,
    required TextStyle subStyle,
    required double padding,
    required double available,
  }) {
    final natural = [
      for (final option in options)
        math.max(
              _textWidth(context, option.label, style),
              option.sublabel == null
                  ? 0.0
                  : _textWidth(context, option.sublabel!, subStyle),
            ) +
            2 * padding,
    ];
    final n = natural.length;
    final total = natural.fold<double>(0, (a, b) => a + b);
    final widest = natural.fold<double>(0, (a, b) => a > b ? a : b);
    if (available <= 0) return List.filled(n, 0);
    if (widest * n <= available) return List.filled(n, available / n);
    if (total <= available) {
      final extra = (available - total) / n;
      return [for (final w in natural) w + extra];
    }
    return [for (final w in natural) available * w / total];
  }

  static double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    // Round up so sub-pixel layout differences never force an ellipsis.
    return width.ceilToDouble();
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedStyle,
    required this.idleStyle,
    required this.sublabel,
    required this.subStyle,
    required this.height,
    required this.selectedColor,
    required this.padding,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle selectedStyle;
  final TextStyle idleStyle;
  final String? sublabel;
  final TextStyle subStyle;
  final double height;
  final Color selectedColor;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: height,
          padding: EdgeInsetsDirectional.symmetric(horizontal: padding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected ? selectedStyle : idleStyle,
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subStyle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
