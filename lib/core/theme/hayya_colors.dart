import 'package:flutter/material.dart';

/// Prayer window that drives the Home header gradient.
enum PrayerPeriod { fajr, dhuhr, maghrib, isha }

/// Gradient + ink for one [PrayerPeriod] header.
@immutable
class PeriodPalette {
  const PeriodPalette({
    required this.colors,
    required this.stops,
    required this.ink,
    required this.pattern,
    required this.chip,
  });

  final List<Color> colors;
  final List<double> stops;

  /// Foreground text color, chosen per period to keep contrast >= 4.5:1.
  final Color ink;
  final Color pattern;
  final Color chip;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: colors,
    stops: stops,
  );
}

/// Color tokens from the "Design system" frame (`HayyaColors.light` / `.dark`).
///
/// Read with `context.colors` (see `theme_context.dart`).
@immutable
class HayyaColors extends ThemeExtension<HayyaColors> {
  const HayyaColors({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.text,
    required this.muted,
    required this.faint,
    required this.primary,
    required this.primaryInk,
    required this.primarySoft,
    required this.onPrimary,
    required this.gold,
    required this.goldInk,
    required this.goldSoft,
    required this.onGold,
    required this.danger,
    required this.dangerSoft,
    required this.nav,
    required this.heatmap,
    required this.flatShadow,
    required this.cardShadow,
    required this.heroShadow,
    required this.periods,
  });

  final Color background;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color text;
  final Color muted;
  final Color faint;
  final Color primary;
  final Color primaryInk;
  final Color primarySoft;
  final Color onPrimary;
  final Color gold;
  final Color goldInk;
  final Color goldSoft;
  final Color onGold;
  final Color danger;
  final Color dangerSoft;
  final Color nav;

  /// Tracker heatmap levels, index = prayers prayed that day (0–5).
  final List<Color> heatmap;

  /// shadow.none · flat — rows inside a card, settings groups.
  final List<BoxShadow> flatShadow;

  /// shadow.card — all cards.
  final List<BoxShadow> cardShadow;

  /// shadow.hero — next-prayer card only, teal-tinted.
  final List<BoxShadow> heroShadow;

  final Map<PrayerPeriod, PeriodPalette> periods;

  static const light = HayyaColors(
    background: Color(0xFFF5F3EC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF1EC),
    line: Color(0xFFE2E5DE),
    text: Color(0xFF11241F),
    muted: Color(0xFF56665F),
    faint: Color(0xFF8A9690),
    primary: Color(0xFF0D5C52),
    primaryInk: Color(0xFF0D5C52),
    primarySoft: Color(0xFFE0EEE9),
    onPrimary: Color(0xFFFFFFFF),
    gold: Color(0xFFC49A45),
    goldInk: Color(0xFF8A6418),
    goldSoft: Color(0xFFF6ECD6),
    onGold: Color(0xFF2A1D05),
    danger: Color(0xFFB4442F),
    dangerSoft: Color(0xFFF8E4DE),
    nav: Color(0xFFFFFFFF),
    heatmap: [
      Color(0xFFE4E7E0),
      Color(0xFFCFE3DC),
      Color(0xFF9CCBBE),
      Color(0xFF5DA696),
      Color(0xFF2A7E70),
      Color(0xFF0D5C52),
    ],
    flatShadow: [
      BoxShadow(color: Color(0x0F11241F), offset: Offset(0, 1), blurRadius: 2),
    ],
    cardShadow: [
      BoxShadow(color: Color(0x0A11241F), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x1211241F), offset: Offset(0, 8), blurRadius: 24),
    ],
    heroShadow: [
      BoxShadow(color: Color(0x0D11241F), offset: Offset(0, 2), blurRadius: 4),
      BoxShadow(
        color: Color(0x290D5C52),
        offset: Offset(0, 18),
        blurRadius: 40,
      ),
    ],
    periods: {
      PrayerPeriod.fajr: PeriodPalette(
        colors: [Color(0xFF22335C), Color(0xFF55638F), Color(0xFFC99A92)],
        stops: [0, 0.58, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x24FFFFFF),
      ),
      PrayerPeriod.dhuhr: PeriodPalette(
        colors: [Color(0xFFBFE3DA), Color(0xFFDCEFE8), Color(0xFFF1F2EA)],
        stops: [0, 0.6, 1],
        ink: Color(0xFF11241F),
        pattern: Color(0xFF0D5C52),
        chip: Color(0x99FFFFFF),
      ),
      PrayerPeriod.maghrib: PeriodPalette(
        colors: [Color(0xFF5E3346), Color(0xFFA65A45), Color(0xFFD99A62)],
        stops: [0, 0.58, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x29FFFFFF),
      ),
      PrayerPeriod.isha: PeriodPalette(
        colors: [Color(0xFF060B1A), Color(0xFF0F1A38), Color(0xFF1A2850)],
        stops: [0, 0.6, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x1FFFFFFF),
      ),
    },
  );

  /// Dark theme: shadows off, surfaces step up instead (#111A2C → #17223A).
  static const dark = HayyaColors(
    background: Color(0xFF0A1120),
    surface: Color(0xFF111A2C),
    surface2: Color(0xFF17223A),
    line: Color(0xFF202C44),
    text: Color(0xFFE8EDF0),
    muted: Color(0xFF9AA7B6),
    faint: Color(0xFF6C7A8C),
    primary: Color(0xFF2FA58F),
    primaryInk: Color(0xFF5CCAB4),
    primarySoft: Color(0xFF14303A),
    onPrimary: Color(0xFF04211B),
    gold: Color(0xFFD9AE5B),
    goldInk: Color(0xFFE6C27E),
    goldSoft: Color(0xFF2E2A22),
    onGold: Color(0xFF2A1D05),
    danger: Color(0xFFE07A62),
    dangerSoft: Color(0xFF33212A),
    nav: Color(0xFF0E1627),
    heatmap: [
      Color(0xFF1A2438),
      Color(0xFF173A3C),
      Color(0xFF1C5A52),
      Color(0xFF22796B),
      Color(0xFF2C9B86),
      Color(0xFF4CC4AC),
    ],
    flatShadow: [],
    cardShadow: [],
    heroShadow: [
      BoxShadow(
        color: Color(0x73000000),
        offset: Offset(0, 18),
        blurRadius: 40,
      ),
    ],
    periods: {
      PrayerPeriod.fajr: PeriodPalette(
        colors: [Color(0xFF121C38), Color(0xFF323D63), Color(0xFF7A6070)],
        stops: [0, 0.58, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x1FFFFFFF),
      ),
      PrayerPeriod.dhuhr: PeriodPalette(
        colors: [Color(0xFF1B4A55), Color(0xFF163545), Color(0xFF0F2235)],
        stops: [0, 0.6, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x1FFFFFFF),
      ),
      PrayerPeriod.maghrib: PeriodPalette(
        colors: [Color(0xFF2E1A2E), Color(0xFF5E3238), Color(0xFF8E5440)],
        stops: [0, 0.58, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x1FFFFFFF),
      ),
      PrayerPeriod.isha: PeriodPalette(
        colors: [Color(0xFF04081A), Color(0xFF0B1430), Color(0xFF14213F)],
        stops: [0, 0.6, 1],
        ink: Color(0xFFFFFFFF),
        pattern: Color(0xFFFFFFFF),
        chip: Color(0x1AFFFFFF),
      ),
    },
  );

  @override
  HayyaColors copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? text,
    Color? muted,
    Color? faint,
    Color? primary,
    Color? primaryInk,
    Color? primarySoft,
    Color? onPrimary,
    Color? gold,
    Color? goldInk,
    Color? goldSoft,
    Color? onGold,
    Color? danger,
    Color? dangerSoft,
    Color? nav,
    List<Color>? heatmap,
    List<BoxShadow>? flatShadow,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? heroShadow,
    Map<PrayerPeriod, PeriodPalette>? periods,
  }) {
    return HayyaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      primary: primary ?? this.primary,
      primaryInk: primaryInk ?? this.primaryInk,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      gold: gold ?? this.gold,
      goldInk: goldInk ?? this.goldInk,
      goldSoft: goldSoft ?? this.goldSoft,
      onGold: onGold ?? this.onGold,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      nav: nav ?? this.nav,
      heatmap: heatmap ?? this.heatmap,
      flatShadow: flatShadow ?? this.flatShadow,
      cardShadow: cardShadow ?? this.cardShadow,
      heroShadow: heroShadow ?? this.heroShadow,
      periods: periods ?? this.periods,
    );
  }

  @override
  HayyaColors lerp(HayyaColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    // Lists and maps snap at the midpoint; only flat colors animate.
    final snap = t < 0.5 ? this : other;
    return HayyaColors(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      line: c(line, other.line),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      primary: c(primary, other.primary),
      primaryInk: c(primaryInk, other.primaryInk),
      primarySoft: c(primarySoft, other.primarySoft),
      onPrimary: c(onPrimary, other.onPrimary),
      gold: c(gold, other.gold),
      goldInk: c(goldInk, other.goldInk),
      goldSoft: c(goldSoft, other.goldSoft),
      onGold: c(onGold, other.onGold),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      nav: c(nav, other.nav),
      heatmap: snap.heatmap,
      flatShadow: snap.flatShadow,
      cardShadow: snap.cardShadow,
      heroShadow: snap.heroShadow,
      periods: snap.periods,
    );
  }
}
