import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum OverlapSlot { header, body }

/// [header] above [body], with [body] pulled up by [overlap] so it covers
/// the bottom of the header: Home's card over the gradient.
///
/// The header is at least [minHeaderHeight] tall, and taller when its
/// content plus [overlap] needs more (large accessibility text), so the
/// card never covers the dates. The body moves down with it.
class OverlapLayout
    extends SlottedMultiChildRenderObjectWidget<OverlapSlot, RenderBox> {
  const OverlapLayout({
    super.key,
    required this.header,
    required this.body,
    required this.minHeaderHeight,
    required this.overlap,
  });

  final Widget header;
  final Widget body;
  final double minHeaderHeight;
  final double overlap;

  @override
  Iterable<OverlapSlot> get slots => OverlapSlot.values;

  @override
  Widget? childForSlot(OverlapSlot slot) => switch (slot) {
    OverlapSlot.header => header,
    OverlapSlot.body => body,
  };

  @override
  RenderOverlapLayout createRenderObject(BuildContext context) =>
      RenderOverlapLayout(minHeaderHeight, overlap);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOverlapLayout renderObject,
  ) => renderObject
    ..minHeaderHeight = minHeaderHeight
    ..overlap = overlap;
}

class RenderOverlapLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<OverlapSlot, RenderBox> {
  RenderOverlapLayout(this._minHeaderHeight, this._overlap);

  double _minHeaderHeight;
  set minHeaderHeight(double value) {
    if (value == _minHeaderHeight) return;
    _minHeaderHeight = value;
    markNeedsLayout();
  }

  double _overlap;
  set overlap(double value) {
    if (value == _overlap) return;
    _overlap = value;
    markNeedsLayout();
  }

  RenderBox get _header => childForSlot(OverlapSlot.header)!;
  RenderBox get _body => childForSlot(OverlapSlot.body)!;

  BoxParentData _data(RenderBox child) => child.parentData! as BoxParentData;

  @override
  void performLayout() {
    final width = constraints.maxWidth;

    // Measure the header's content, then give it its final height so its
    // background fills the part the body covers.
    _header.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
    final headerHeight = math.max(
      _minHeaderHeight,
      _header.size.height + _overlap,
    );
    _header.layout(
      BoxConstraints.tightFor(width: width, height: headerHeight),
      parentUsesSize: true,
    );
    _body.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);

    final bodyTop = headerHeight - _overlap;
    _data(_header).offset = Offset.zero;
    _data(_body).offset = Offset(0, bodyTop);
    size = constraints.constrain(
      Size(width, math.max(headerHeight, bodyTop + _body.size.height)),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context
      ..paintChild(_header, offset + _data(_header).offset)
      ..paintChild(_body, offset + _data(_body).offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // The body is painted on top, so it gets the first chance.
    for (final child in [_body, _header]) {
      final hit = result.addWithPaintOffset(
        offset: _data(child).offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
