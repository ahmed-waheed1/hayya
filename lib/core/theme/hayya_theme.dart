import 'package:flutter/material.dart';

import 'hayya_colors.dart';
import 'hayya_radius.dart';
import 'hayya_typography.dart';

/// Builds Material [ThemeData] from the Hayya tokens.
///
/// Typography depends on the locale, so rebuild when it changes.
/// Must be called below `ScreenUtilInit`.
abstract final class HayyaTheme {
  static ThemeData light(Locale locale) =>
      _build(HayyaColors.light, Brightness.light, locale);

  static ThemeData dark(Locale locale) =>
      _build(HayyaColors.dark, Brightness.dark, locale);

  static ThemeData _build(HayyaColors c, Brightness brightness, Locale locale) {
    final type = HayyaTypography.forLocale(locale);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primaryInk,
      secondary: c.gold,
      onSecondary: c.onGold,
      secondaryContainer: c.goldSoft,
      onSecondaryContainer: c.goldInk,
      error: c.danger,
      onError: c.surface,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface2,
      surfaceContainerHigh: c.surface2,
      surfaceContainerHighest: c.surface2,
      outline: c.faint,
      outlineVariant: c.line,
      shadow: const Color(0xFF11241F),
    );

    final textTheme = TextTheme(
      displayLarge: type.timeDisplay,
      headlineMedium: type.titleLarge,
      titleLarge: type.title,
      bodyLarge: type.body,
      bodyMedium: type.body,
      labelLarge: type.label,
      labelSmall: type.overline,
    ).apply(bodyColor: c.text, displayColor: c.text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.line,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.text),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: type.title.copyWith(color: c.text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HayyaRadius.xxl),
          ),
        ),
      ),
      extensions: [c, type],
    );
  }
}
