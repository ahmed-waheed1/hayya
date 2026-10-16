# Releasing (Android)

Release builds are signed with the upload key, shrunk with R8 and
obfuscated. Debug builds are unchanged and need none of this.

## The signing key

`android/app/build.gradle.kts` reads `android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=…
storeFile=/absolute/path/to/upload-keystore.jks
```

A relative `storeFile` resolves against `android/app/`. Keep the keystore
outside the repository.

- `key.properties`, `*.jks` and `*.keystore` are gitignored (in
  `.gitignore` and `android/.gitignore`). Never commit them or paste their
  contents anywhere.
- Without `key.properties`, any release build (`flutter build appbundle`,
  `flutter build apk`, `flutter run --release`) stops at `preReleaseBuild`
  with "Release signing is not configured". It never falls back to the
  debug key.
- **Back up the keystore and both passwords** somewhere safe and offline,
  such as a password manager plus an encrypted copy off this machine. If
  they're lost, Play can't accept updates signed by anything else. With Play
  App Signing it's only the upload key and can be reset through Play
  support, but that takes days. For APKs installed outside Play, there is
  no recovery: users have to uninstall, which deletes their data.

## Releasing a version

1. **Bump the version** in `pubspec.yaml`: `version: <name>+<code>`, for
   example `1.0.0+1` → `1.0.1+2`. The build number after `+` becomes
   `versionCode`. It must go up with every upload to Play, even when the
   name stays the same.
2. Run `dart format lib test`, `flutter analyze` and the full suite
   (`flutter test`).
3. **Build the app bundle** for Play:

   ```sh
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```

   Output: `build/app/outputs/bundle/release/app-release.aab`.

4. **Archive the symbols** for this version. `build/` is wiped by
   `flutter clean`, and you can't decode a crash without the files from the
   exact build that produced it:
   - `build/symbols/app.android-*.symbols`: Dart symbols (one per ABI). Use
     them to decode obfuscated Dart stack traces:
     `flutter symbolize -i <stack-trace.txt> -d build/symbols/app.android-arm64.symbols`.
   - `build/app/outputs/mapping/release/mapping.txt`: the R8 map for
     Java/Kotlin stack traces. Upload it to Play Console with the release
     (App bundle explorer → Downloads → ReTrace mapping file).

   Native debug symbols are already inside the `.aab`
   (`BUNDLE-METADATA/`), so Play receives them automatically.

5. Upload the `.aab` to Play Console.

## Testing a release build on a device

```sh
flutter build apk --release --obfuscate --split-debug-info=build/symbols-apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`-r` updates in place and keeps the app's data. That only works when the
installed copy has the same signer. Android refuses to replace a
debug-signed install with a release-signed one
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`). Switching between the two means
uninstalling first, which deletes the data. Use a separate
`--split-debug-info` directory for test APKs so they don't overwrite the
symbols of the bundle you upload.

## Shrinking (R8)

The release build sets `isMinifyEnabled` and `isShrinkResources`. Anything
reached only by name or by reflection has to be kept explicitly:

- `android/app/src/main/res/raw/keep.xml`: resources named from Dart, which
  are the adhan sound (`@raw/adhan`) and the notification icon
  (`@mipmap/ic_launcher`). Add any new notification sound or icon there.
- `android/app/proguard-rules.pro`: flutter_local_notifications'
  model classes. Scheduled notifications are stored as Gson JSON and read
  back after a reboot or an app update, so their field names must not
  change between releases.
- Dart entry points called by name from the platform, such as
  `backgroundTaskDispatcher` for workmanager, need
  `@pragma('vm:entry-point')`.

After changing dependencies, check a release build on a device: the app
opens, an adhan sounds at prayer time (the debug "Test adhan" tool isn't in
release builds), and adhans still sound after a reboot.

## Store screenshots

`test/store_screenshots_test.dart` renders the real app (widgets, fonts,
translations) with fixed sample data and writes Play Store screenshots to
`store/screenshots/{en,ar}/{phone,tablet}/` (gitignored):

```sh
TZ=Africa/Cairo flutter test test/store_screenshots_test.dart \
  --dart-define=STORE_SCREENSHOTS=true
```

Without the define the test is skipped, so the normal suite doesn't write
them. Run it in the Africa/Cairo time zone, since the sample is in Cairo.

- **Sample data**: Cairo, Thursday 15 October 2026, 20 minutes before Asr
  (computed with the app's own prayer times), 34 weeks of tracker history
  so the tablet heatmap is full (mostly complete, scattered gaps, a 23-day
  streak, Fajr and Dhuhr ticked today), and 3 qada prayers. Settings → About shows
  the version from `pubspec.yaml`.
- **Shots** (8 per device and language, Play's maximum): `01-home`,
  `02-qibla` (aligned), `03-tracker`, `04-timetable`, `05-settings`,
  `06-onboarding`, `07-home-dark`, `08-qibla-dark`.
- **Sizes**: phone 1080 × 1920 (9:16, rendered at 2.75×) and 10-inch tablet
  2560 × 1440 (16:9 landscape, at 2×). Play requires JPEG or 24-bit PNG
  without alpha, each side 320–3840 px and at most 2:1. For promotion it
  wants phone screenshots at 9:16 and at least 1080 × 1920, and large-screen
  screenshots at 16:9 between 1080 and 7680 px. The generator writes RGB
  PNGs.
- The Developer section is hidden (`showDeveloperTools = false`), and there
  is no debug banner.
