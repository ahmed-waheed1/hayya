import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/preferences/app_preferences.dart';
import 'core/services/background_tasks.dart';
import 'core/utils/app_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts are bundled in assets/fonts/; never fall back to the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  registerAppLicenses();

  await EasyLocalization.ensureInitialized();
  await configureDependencies();
  // Keeps the adhan scheduled while the app isn't opened. Idempotent, so
  // every launch (the first one included) makes sure it is registered.
  unawaited(getIt<BackgroundTasks>().ensureRegistered());

  runApp(localizedApp(getIt<AppPreferences>().languageCode));
}
