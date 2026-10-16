import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale from the design system. Manrope for Latin, Cairo for Arabic.
///
/// Arabic gets ~15% more line-height and never gets letter-spacing.
/// Times are always tabular. Read with `context.type`.
@immutable
class HayyaTypography extends ThemeExtension<HayyaTypography> {
  const HayyaTypography._({
    required this.isArabic,
    required this.timeDisplay,
    required this.titleLarge,
    required this.title,
    required this.body,
    required this.label,
    required this.overline,
  });

  factory HayyaTypography.forLocale(Locale locale) {
    final isArabic = locale.languageCode == 'ar';
    TextStyle s(
      double size,
      double lineHeight,
      FontWeight weight, {
      double trackingEm = 0,
      bool tabular = false,
    }) => _font(
      isArabic,
      size: size,
      height: lineHeight / size,
      weight: weight,
      trackingEm: trackingEm,
      tabular: tabular,
    );

    if (isArabic) {
      return HayyaTypography._(
        isArabic: true,
        timeDisplay: s(44, 56, FontWeight.w800, tabular: true),
        titleLarge: s(28, 42, FontWeight.w800),
        title: s(20, 32, FontWeight.w700),
        body: s(16, 28, FontWeight.w500),
        label: s(14, 22, FontWeight.w700),
        overline: s(13, 20, FontWeight.w700),
      );
    }
    return HayyaTypography._(
      isArabic: false,
      timeDisplay: s(44, 48, FontWeight.w800, trackingEm: -0.01, tabular: true),
      titleLarge: s(28, 36, FontWeight.w800),
      title: s(20, 28, FontWeight.w700),
      body: s(16, 24, FontWeight.w500),
      label: s(14, 20, FontWeight.w700),
      overline: s(12, 16, FontWeight.w800, trackingEm: 0.08),
    );
  }

  final bool isArabic;

  /// time.display · 44 · 800 · tabular
  final TextStyle timeDisplay;

  /// title.large · 28 · 800
  final TextStyle titleLarge;

  /// title · 20 · 700
  final TextStyle title;

  /// body · 16 · 500
  final TextStyle body;

  /// label · 14 · 700
  final TextStyle label;

  /// overline · 12 · 800 · +8% tracking (EN only). Uppercase lives in the
  /// English translation strings, never applied in code.
  final TextStyle overline;

  /// Component-level style outside the six named tokens (e.g. the 17 px row
  /// time). Use the named tokens whenever one fits.
  ///
  /// Always build a new weight through this instead of `copyWith`:
  /// google_fonts binds each weight to its own font file.
  TextStyle style(
    double size,
    FontWeight weight, {
    double trackingEm = 0,
    bool tabular = false,
    double? height,
  }) => _font(
    isArabic,
    size: size,
    height: height ?? (isArabic ? 1.5 : 1.3),
    weight: weight,
    trackingEm: trackingEm,
    tabular: tabular,
  );

  /// Cairo in every locale, for Arabic text that doesn't follow the UI
  /// language (the "حيّ" brand mark).
  TextStyle arabic(double size, FontWeight weight, {double height = 1.2}) =>
      _font(
        true,
        size: size,
        height: height,
        weight: weight,
        trackingEm: 0,
        tabular: false,
      );

  static TextStyle _font(
    bool isArabic, {
    required double size,
    required double height,
    required FontWeight weight,
    required double trackingEm,
    required bool tabular,
  }) {
    final fontSize = size.sp;
    final style = GoogleFonts.getFont(
      isArabic ? 'Cairo' : 'Manrope',
      fontSize: fontSize,
      height: height,
      fontWeight: weight,
      letterSpacing: isArabic ? 0 : trackingEm * fontSize,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
    if (isArabic) return style;
    // Arabic inside English text (the "العربية" language option) is set in
    // Cairo too, not the system's Arabic font.
    final cairo = GoogleFonts.getFont('Cairo', fontWeight: weight).fontFamily;
    return style.copyWith(fontFamilyFallback: [?cairo]);
  }

  @override
  HayyaTypography copyWith({
    TextStyle? timeDisplay,
    TextStyle? titleLarge,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? overline,
  }) {
    return HayyaTypography._(
      isArabic: isArabic,
      timeDisplay: timeDisplay ?? this.timeDisplay,
      titleLarge: titleLarge ?? this.titleLarge,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      overline: overline ?? this.overline,
    );
  }

  @override
  HayyaTypography lerp(HayyaTypography? other, double t) {
    // Fonts switch with the locale, not with an animation; snap.
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
