import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

/// Text sizes the app must handle, from the default to the largest common
/// accessibility setting.
const textScales = [1.0, 1.3, 1.6, 2.0];

/// Every screen is tested at these sizes.
const textScaleSizes = [
  ('phone', phoneSize),
  ('small phone', Size(320, 568)),
  ('phone landscape', Size(844, 390)),
  ('tablet', tabletSize),
  ('tablet portrait', Size(834, 1194)),
];

/// One case of the text-scale matrix.
typedef TextScaleCase = ({
  String sizeName,
  Size size,
  String lang,
  double scale,
});

/// Registers [body] for every size × language × text scale. The text scale
/// is set before [body] runs.
void textScaleMatrix(
  String description,
  Future<void> Function(WidgetTester tester, TextScaleCase c) body,
) {
  for (final (sizeName, size) in textScaleSizes) {
    for (final lang in ['en', 'ar']) {
      for (final scale in textScales) {
        testWidgets('$description · $sizeName · $lang · ${scale}x', (
          tester,
        ) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await body(tester, (
            sizeName: sizeName,
            size: size,
            lang: lang,
            scale: scale,
          ));
        });
      }
    }
  }
}

/// Fails on a layout exception or any text that isn't fully readable.
/// See [readabilityIssues].
void expectReadable(WidgetTester tester, {required double scale}) {
  expect(tester.takeException(), isNull);
  final issues = readabilityIssues(tester, scale: scale);
  expect(issues, isEmpty, reason: issues.join('\n'));
}

/// Every laid-out text that is:
/// - truncated (ellipsis or past its maxLines),
/// - taller than the box it got (clipped or drawn over its neighbours),
/// - broken in the middle of a word (narrower than its longest word), or
/// - shrunk by a [FittedBox] below its size at 1.0x text.
///
/// Texts that aren't painted (other tabs in the shell) are skipped.
List<String> readabilityIssues(WidgetTester tester, {required double scale}) {
  final issues = <String>[];
  for (final object in tester.allRenderObjects) {
    if (object is! RenderParagraph || !object.attached || !object.hasSize) {
      continue;
    }
    if (!_isPainted(object)) continue;
    final text = object.text.toPlainText().replaceAll('\n', ' ');
    if (text.trim().isEmpty) continue;
    String where() => _creator(object);

    if (object.didExceedMaxLines) {
      issues.add('truncated: "$text" (${where()})');
      continue;
    }
    // A hair wider: a paragraph sized to its own text can wrap one more
    // line when measured again at exactly that width.
    final needed = object.getMaxIntrinsicHeight(object.size.width + 0.5);
    if (object.size.height < needed - 0.5) {
      issues.add(
        'clipped: "$text" ${object.size.height.toStringAsFixed(1)} of '
        '${needed.toStringAsFixed(1)} px (${where()})',
      );
    }
    final longestWord = object.getMinIntrinsicWidth(double.infinity);
    if (object.size.width < longestWord - 0.5) {
      issues.add('word broken: "$text" (${where()})');
    }
    final drawn = _fittedScale(object) * scale;
    if (drawn < 0.995) {
      issues.add(
        'shrunk: "$text" drawn at ${drawn.toStringAsFixed(2)}x (${where()})',
      );
    }
  }
  return issues;
}

/// False under an Offstage or an IndexedStack child that isn't showing.
bool _isPainted(RenderObject object) {
  RenderObject? child = object;
  var parent = object.parent;
  while (parent != null) {
    if (parent is RenderOffstage && parent.offstage) return false;
    if (parent is RenderIndexedStack && child is RenderBox) {
      final index = parent.index;
      var i = 0;
      var visible = false;
      parent.visitChildren((c) {
        if (identical(c, child) && i == index) visible = true;
        i++;
      });
      if (!visible) return false;
    }
    child = parent;
    parent = parent.parent;
  }
  return true;
}

/// The product of every [FittedBox] scale above [object] (1 = none).
double _fittedScale(RenderObject object) {
  var scale = 1.0;
  var parent = object.parent;
  while (parent != null) {
    if (parent is RenderFittedBox && parent.hasSize) {
      final child = parent.child;
      if (child != null && child.hasSize && child.size.width > 0) {
        scale *= math
            .min(
              parent.size.width / child.size.width,
              child.size.height > 0
                  ? parent.size.height / child.size.height
                  : 1,
            )
            .clamp(0.0, 1.0);
      }
    }
    parent = parent.parent;
  }
  return scale;
}

/// The nearest app widgets above [object], for failure messages.
String _creator(RenderParagraph object) {
  final creator = object.debugCreator;
  if (creator is! DebugCreator) return '?';
  final names = <String>[];
  creator.element.visitAncestorElements((e) {
    final name = e.widget.runtimeType.toString();
    if (!name.startsWith('_') || names.length < 2) names.add(name);
    return names.length < 6;
  });
  return names.join(' < ');
}
