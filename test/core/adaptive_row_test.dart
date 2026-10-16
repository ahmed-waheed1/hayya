import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/widgets/adaptive_row.dart';

const labelKey = Key('label');
const trailingKey = Key('trailing');
const leadingKey = Key('leading');

Future<void> pumpRow(
  WidgetTester tester, {
  required String label,
  double width = 300,
  Widget? trailing,
  TextDirection direction = TextDirection.ltr,
  bool intrinsic = false,
  double fontSize = 10,
}) async {
  Widget row = AdaptiveRow(
    gap: 10,
    runGap: 4,
    leading: const SizedBox(key: leadingKey, width: 20, height: 20),
    label: Text(
      label,
      key: labelKey,
      style: TextStyle(fontSize: fontSize, height: 1),
    ),
    trailing:
        trailing ?? const SizedBox(key: trailingKey, width: 100, height: 40),
  );
  if (intrinsic) row = IntrinsicHeight(child: row);
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: row),
      ),
    ),
  );
}

void main() {
  // The test font draws every glyph 1 em wide: "aaaa" at 10 px is 40 px.

  testWidgets('side by side when the label fits, like a Row', (tester) async {
    await pumpRow(tester, label: 'aaaa bbbb');
    final label = tester.getRect(find.byKey(labelKey));
    final trailing = tester.getRect(find.byKey(trailingKey));
    expect(tester.getTopLeft(find.byKey(leadingKey)).dx, 0);
    expect(label.left, 30); // after the leading and the gap
    expect(trailing.right, 300);
    expect(trailing.top, 0);
    // The label takes the rest of the row, as in an Expanded.
    expect(label.width, 300 - 30 - 10 - 100);
    expect(tester.getSize(find.byType(AdaptiveRow)).height, 40);
  });

  testWidgets('a trailing Align keeps its natural width', (tester) async {
    await pumpRow(
      tester,
      label: 'aaaa',
      trailing: Container(
        key: trailingKey,
        alignment: Alignment.center,
        child: const SizedBox(width: 60, height: 30),
      ),
    );
    final trailing = tester.getRect(find.byKey(trailingKey));
    expect(trailing.width, 60);
    expect(trailing.right, 300);
    expect(trailing.top, 0, reason: 'still beside the label');
  });

  testWidgets('stacks when a word would break beside the trailing', (
    tester,
  ) async {
    // 180 px left for the label; the word is 200 px.
    await pumpRow(tester, label: 'a' * 20);
    final label = tester.getRect(find.byKey(labelKey));
    final trailing = tester.getRect(find.byKey(trailingKey));
    expect(label.width, 300 - 30);
    // The first line is as tall as the 20 px leading.
    expect(trailing.top, 20 + 4);
    expect(trailing.right, 300, reason: 'aligned to the end');
    expect(tester.getSize(find.byType(AdaptiveRow)).height, 20 + 4 + 40);
  });

  testWidgets('stacks when beside would be taller than stacked', (
    tester,
  ) async {
    // At 20 px each "aaa" is 60 px. Beside a 140 px trailing the label
    // has 120 px: one word per line, 12 lines (240 px). Stacked, 270 px
    // holds 3 words a line: 4 lines + 4 + 20 = 104 px. No word breaks
    // either way.
    await pumpRow(
      tester,
      label: List.filled(12, 'aaa').join(' '),
      fontSize: 20,
      trailing: const SizedBox(key: trailingKey, width: 140, height: 20),
    );
    final label = tester.getRect(find.byKey(labelKey));
    final trailing = tester.getRect(find.byKey(trailingKey));
    expect(label.height, 80);
    expect(trailing.top, label.bottom + 4);
  });

  testWidgets('mirrors in RTL', (tester) async {
    await pumpRow(tester, label: 'aaaa', direction: TextDirection.rtl);
    expect(tester.getTopRight(find.byKey(leadingKey)).dx, 300);
    expect(tester.getTopLeft(find.byKey(trailingKey)).dx, 0);
    expect(tester.getTopRight(find.byKey(labelKey)).dx, 300 - 30);

    await pumpRow(tester, label: 'a' * 20, direction: TextDirection.rtl);
    expect(tester.getTopLeft(find.byKey(trailingKey)).dx, 0);
    expect(tester.getRect(find.byKey(trailingKey)).top, greaterThan(0));
  });

  testWidgets('reports its height to IntrinsicHeight', (tester) async {
    await pumpRow(tester, label: 'a' * 20, intrinsic: true);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AdaptiveRow)).height, 20 + 4 + 40);
  });
}
