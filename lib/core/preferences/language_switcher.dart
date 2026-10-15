import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../di/injection.dart';
import 'app_preferences.dart';

/// easy_localization owns the current locale; [AppPreferences] owns its
/// persistence (`saveLocale` is off in `main.dart`). Always switch through
/// here so the two never disagree.
extension LanguageSwitcher on BuildContext {
  Future<void> switchLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
    await getIt<AppPreferences>().setLanguageCode(languageCode);
  }
}
