// easy_localization doesn't export Localization or Translations, but loading
// translations without a widget tree (in the background isolate) needs them.
// ignore_for_file: implementation_imports

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';

/// The languages the app is translated into.
const appLocales = [Locale('en'), Locale('ar')];

/// Used when the device's language isn't one of [appLocales].
const fallbackLocale = Locale('en');

/// Where the translation files live (`en.json`, `ar.json`).
const translationsPath = 'assets/translations';

/// The language the app opens in: [languageCode] when the user picked one,
/// otherwise [deviceLocale] if the app has it, otherwise [fallbackLocale].
/// The same choice `EasyLocalization` makes in `app.dart`.
Locale resolveAppLocale(String? languageCode, Locale deviceLocale) {
  final wanted = languageCode == null ? deviceLocale : Locale(languageCode);
  return appLocales.firstWhere(
    (l) => l.languageCode == wanted.languageCode,
    orElse: () => fallbackLocale,
  );
}

/// Makes `.tr()` and `.plural()` answer in [locale] without a
/// `BuildContext`, for code that runs outside the app's widget tree.
///
/// Matches the app's `EasyLocalization` setup: Arabic plural forms on, and
/// no fallback translations.
Future<void> loadTranslationsWithoutContext(
  Locale locale, {
  AssetLoader assetLoader = const RootBundleAssetLoader(),
}) async {
  final map = await assetLoader.load(translationsPath, locale);
  Localization.load(
    locale,
    translations: map == null ? null : Translations(map),
    ignorePluralRules: false,
  );
}
