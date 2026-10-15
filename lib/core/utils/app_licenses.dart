import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The package name the adhan recording's credit is listed under on the
/// licenses page.
const adhanRecordingLicenseName = 'Adhan recording';

bool _registered = false;

/// Adds what the app bundles beyond Dart packages to the licenses page
/// (Settings → About → Licenses): the SIL OFL licenses the bundled fonts
/// require to ship with the app, and the adhan recording's credit. Loaded
/// lazily, only when that page opens. Safe to call more than once.
void registerAppLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Manrope', 'Cairo']) {
      final text = await rootBundle.loadString('assets/fonts/$family-OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
    yield LicenseEntryWithLineBreaks([
      adhanRecordingLicenseName,
    ], await rootBundle.loadString('assets/licenses/adhan.txt'));
  });
}
