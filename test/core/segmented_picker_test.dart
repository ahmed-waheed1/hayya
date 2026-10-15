import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/theme/hayya_colors.dart';
import 'package:hayya/core/theme/hayya_theme.dart';
import 'package:hayya/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    required List<String> labels,
    double? width,
    String lang = 'en',
    Brightness brightness = Brightness.light,
  }) async {
    tester.view
      ..physicalSize = phoneSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadFonts(tester);

    final locale = Locale(lang);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: phoneSize,
        builder: (context, _) => MaterialApp(
          locale: locale,
          theme: brightness == Brightness.light
              ? HayyaTheme.light(locale)
              : HayyaTheme.dark(locale),
          home: Directionality(
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: width,
                  child: SegmentedPicker<int>(
                    options: [
                      for (final (i, l) in labels.indexed)
                        SegmentOption(value: i, label: l),
                    ],
                    value: 0,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester, rounds: 2);
  }

  List<double> segmentWidths(WidgetTester tester) => [
    for (final e in find.byType(AnimatedContainer).evaluate())
      tester.getSize(find.byWidget(e.widget)).width,
  ];

  testWidgets('short labels split the width equally', (tester) async {
    await pumpPicker(tester, labels: ['Light', 'Dark', 'System'], width: 358);

    expect(tester.getSize(find.byType(SegmentedPicker<int>)).width, 358);
    final widths = segmentWidths(tester);
    expect(widths[0], moreOrLessEquals(widths[1], epsilon: 0.01));
    expect(widths[1], moreOrLessEquals(widths[2], epsilon: 0.01));
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['en', 'ar']) {
    testWidgets('a long label keeps its width when it fits ($lang)', (
      tester,
    ) async {
      final labels = lang == 'ar'
          ? ['فاتح', 'داكن', 'حسب إعدادات النظام']
          : ['Light', 'Dark', 'Follow the system setting'];
      await pumpPicker(tester, labels: labels, width: 358, lang: lang);

      final widths = segmentWidths(tester);
      expect(widths[2], greaterThan(widths[0]));
      // Still fills the track.
      expect(tester.getSize(find.byType(SegmentedPicker<int>)).width, 358);
      expect(tester.takeException(), isNull);
    });

    testWidgets('too narrow: shrinks and ellipsizes, no overflow ($lang)', (
      tester,
    ) async {
      final labels = lang == 'ar'
          ? ['فاتح', 'داكن', 'حسب إعدادات النظام']
          : ['Light', 'Dark', 'Follow the system setting'];
      await pumpPicker(tester, labels: labels, width: 180, lang: lang);

      expect(tester.getSize(find.byType(SegmentedPicker<int>)).width, 180);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unbounded width sizes to content', (tester) async {
    tester.view
      ..physicalSize = phoneSize
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadFonts(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: phoneSize,
        builder: (context, _) => MaterialApp(
          theme: HayyaTheme.light(const Locale('en')),
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedPicker<int>(
                options: const [
                  SegmentOption(value: 0, label: 'A'),
                  SegmentOption(value: 1, label: 'B'),
                ],
                value: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester, rounds: 2);
    expect(
      tester.getSize(find.byType(SegmentedPicker<int>)).width,
      lessThan(200),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected segment uses selectedSurface', (tester) async {
    await pumpPicker(
      tester,
      labels: ['Light', 'Dark'],
      width: 358,
      brightness: Brightness.dark,
    );
    final selected = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer).first,
    );
    expect(
      (selected.decoration! as BoxDecoration).color,
      HayyaColors.dark.selectedSurface,
    );
    expect(HayyaColors.dark.selectedSurface, const Color(0xFF26344F));
  });
}
