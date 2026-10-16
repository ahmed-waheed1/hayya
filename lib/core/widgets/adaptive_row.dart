import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum AdaptiveRowSlot { leading, label, trailing }

/// [leading] (an icon), [label] and [trailing] controls side by side, like
/// a Row with the label in an Expanded.
///
/// With large accessibility text the controls can move under the label,
/// aligned to the end, and the row grows taller. That happens when beside
/// them the label would have to break a word, or would end up taller than
/// the label and controls stacked (squeezed into a narrow column). At
/// normal sizes the layout is the same as the Row's.
class AdaptiveRow
    extends SlottedMultiChildRenderObjectWidget<AdaptiveRowSlot, RenderBox> {
  const AdaptiveRow({
    super.key,
    this.leading,
    required this.label,
    required this.trailing,
    required this.gap,
    this.runGap = 4,
  });

  final Widget? leading;
  final Widget label;
  final Widget trailing;

  /// Between the leading, label and trailing.
  final double gap;

  /// Between the label and the trailing when stacked.
  final double runGap;

  @override
  Iterable<AdaptiveRowSlot> get slots => AdaptiveRowSlot.values;

  @override
  Widget? childForSlot(AdaptiveRowSlot slot) => switch (slot) {
    AdaptiveRowSlot.leading => leading,
    AdaptiveRowSlot.label => label,
    AdaptiveRowSlot.trailing => trailing,
  };

  @override
  RenderAdaptiveRow createRenderObject(BuildContext context) =>
      RenderAdaptiveRow(
        gap: gap,
        runGap: runGap,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAdaptiveRow renderObject,
  ) => renderObject
    ..gap = gap
    ..runGap = runGap
    ..textDirection = Directionality.of(context);
}

class RenderAdaptiveRow extends RenderBox
    with SlottedContainerRenderObjectMixin<AdaptiveRowSlot, RenderBox> {
  RenderAdaptiveRow({
    required this._gap,
    required this._runGap,
    required this._textDirection,
  });

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _runGap;
  set runGap(double value) {
    if (value == _runGap) return;
    _runGap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(AdaptiveRowSlot.leading);
  RenderBox get _label => childForSlot(AdaptiveRowSlot.label)!;
  RenderBox get _trailing => childForSlot(AdaptiveRowSlot.trailing)!;

  /// Whether the label goes beside the trailing: its words stay whole
  /// there, and the row is no taller than with the two stacked.
  bool _fitsInline(double width, Size leading, Size trailing) {
    final inlineWidth = _labelWidth(
      width,
      leading.width,
      trailing.width,
      inline: true,
    );
    if (_label.getMinIntrinsicWidth(double.infinity) > inlineWidth + 0.5) {
      return false;
    }
    final stackedWidth = _labelWidth(
      width,
      leading.width,
      trailing.width,
      inline: false,
    );
    final inlineHeight = math.max(
      math.max(leading.height, trailing.height),
      _label.getMaxIntrinsicHeight(inlineWidth),
    );
    final stackedHeight =
        math.max(leading.height, _label.getMaxIntrinsicHeight(stackedWidth)) +
        _runGap +
        trailing.height;
    return inlineHeight <= stackedHeight;
  }

  double _labelWidth(
    double width,
    double leadingWidth,
    double trailingWidth, {
    required bool inline,
  }) {
    final start = leadingWidth > 0 ? leadingWidth + _gap : 0.0;
    final end = inline ? trailingWidth + _gap : 0.0;
    return math.max(0.0, width - start - end);
  }

  /// Sizes the children with [size] (a dry or real layout) and returns
  /// the row's size and the children's offsets.
  ({Size size, Offset leading, Offset label, Offset trailing}) _compute(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints constraints) size,
  ) {
    final width = constraints.maxWidth;
    // Like a Row: the leading and trailing at their natural width (an Align
    // inside would otherwise stretch to the whole row).
    BoxConstraints natural(RenderBox child) => BoxConstraints(
      maxWidth: math.min(width, child.getMaxIntrinsicWidth(double.infinity)),
    );
    final leading = _leading == null
        ? Size.zero
        : size(_leading!, natural(_leading!));
    final trailing = size(_trailing, natural(_trailing));
    final inline = _fitsInline(width, leading, trailing);
    final labelWidth = _labelWidth(
      width,
      leading.width,
      trailing.width,
      inline: inline,
    );
    final label = size(_label, BoxConstraints.tightFor(width: labelWidth));

    final topHeight = math.max(leading.height, label.height);
    final height = inline
        ? math.max(topHeight, trailing.height)
        : topHeight + _runGap + trailing.height;
    final rowHeight = constraints.constrainHeight(height);
    final firstRun = inline ? rowHeight : topHeight;

    // Start-to-end positions, mirrored for RTL.
    double x(double start, double childWidth) =>
        _textDirection == TextDirection.ltr
        ? start
        : width - start - childWidth;
    final labelStart = leading.width > 0 ? leading.width + _gap : 0.0;
    return (
      size: Size(width, rowHeight),
      leading: Offset(x(0, leading.width), (firstRun - leading.height) / 2),
      label: Offset(x(labelStart, label.width), (firstRun - label.height) / 2),
      trailing: Offset(
        x(width - trailing.width, trailing.width),
        inline ? (rowHeight - trailing.height) / 2 : topHeight + _runGap,
      ),
    );
  }

  @override
  void performLayout() {
    final result = _compute(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = result.size;
    _offset(_leading, result.leading);
    _offset(_label, result.label);
    _offset(_trailing, result.trailing);
  }

  void _offset(RenderBox? child, Offset offset) {
    if (child != null) (child.parentData! as BoxParentData).offset = offset;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _compute(constraints, (child, c) => child.getDryLayout(c)).size;

  @override
  double computeMinIntrinsicWidth(double height) {
    final leading = _leading?.getMinIntrinsicWidth(height) ?? 0;
    return math.max(
      (leading > 0 ? leading + _gap : 0) + _label.getMinIntrinsicWidth(height),
      _trailing.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final leading = _leading?.getMaxIntrinsicWidth(height) ?? 0;
    return (leading > 0 ? leading + _gap : 0) +
        _label.getMaxIntrinsicWidth(height) +
        _gap +
        _trailing.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in [_leading, _label, _trailing]) {
      if (child == null) continue;
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_trailing, _label, _leading]) {
      if (child == null) continue;
      final hit = result.addWithPaintOffset(
        offset: (child.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
