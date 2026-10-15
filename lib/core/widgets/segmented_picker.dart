import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';

@immutable
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// `SegmentedPicker<T>`: surface-2 track, selected segment lifts to surface.
/// Segment order follows the ambient Directionality. Segments shrink and
/// ellipsize when the parent is narrower than their natural width.
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
    return Container(
      padding: EdgeInsetsDirectional.all(4.r),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(HayyaRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4.r,
        children: [
          for (final option in options)
            Flexible(
              child: _Segment(
                label: option.label,
                selected: option.value == value,
                onTap: () => onChanged(option.value),
                selectedStyle: type
                    .style(14, FontWeight.w700, height: 1.2)
                    .copyWith(color: c.text),
                idleStyle: type
                    .style(14, FontWeight.w600, height: 1.2)
                    .copyWith(color: c.muted),
                selectedColor: c.surface,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedStyle,
    required this.idleStyle,
    required this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle selectedStyle;
  final TextStyle idleStyle;
  final Color selectedColor;

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
          height: 40.r,
          padding: EdgeInsetsDirectional.symmetric(horizontal: 16.r),
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
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: selected ? selectedStyle : idleStyle,
          ),
        ),
      ),
    );
  }
}
