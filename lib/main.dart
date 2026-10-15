import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts are bundled in assets/fonts/; never fall back to the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  _registerFontLicenses();

  await EasyLocalization.ensureInitialized();
  await configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const HayyaApp(),
    ),
  );
}

/// Bundled fonts are SIL OFL; their licenses must ship with the app and
/// appear on the licenses page. Loaded lazily, only when that page opens.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Manrope', 'Cairo']) {
      final text = await rootBundle.loadString('assets/fonts/$family-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
