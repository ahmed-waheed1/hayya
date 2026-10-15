import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/theme/hayya_colors.dart';
import 'package:hayya/core/utils/responsive.dart';

void main() {
  group('HayyaColors', () {
    test('lerp hits both endpoints', () {
      const light = HayyaColors.light;
      const dark = HayyaColors.dark;
      expect(light.lerp(dark, 0).primary, light.primary);
      expect(light.lerp(dark, 1).primary, dark.primary);
    });

    test('every prayer period has a palette in both themes', () {
      for (final palette in [HayyaColors.light, HayyaColors.dark]) {
        expect(palette.periods.keys, containsAll(PrayerPeriod.values));
        expect(palette.heatmap, hasLength(6));
      }
    });

    test('dark theme drops card shadows', () {
      expect(HayyaColors.dark.cardShadow, isEmpty);
      expect(HayyaColors.light.cardShadow, isNotEmpty);
    });
  });

  test('tablet breakpoint is 600', () {
    expect(const BoxConstraints(maxWidth: 599).isTablet, isFalse);
    expect(const BoxConstraints(maxWidth: 600).isTablet, isTrue);
  });
}
