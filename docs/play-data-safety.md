# Google Play Data safety answers

Answers for Play Console → App content → Data safety, based on the privacy
audit of 16 October 2026 (see [privacy-policy.md](privacy-policy.md)).
Recheck them whenever a dependency, a permission or anything that touches
the network changes.

The policy the app links to is published from the separate public repo
[`ahmed-waheed1/hayya-privacy`](https://github.com/ahmed-waheed1/hayya-privacy)
(`index.html` in English, `ar.html` in Arabic) on GitHub Pages. The
Markdown files in `docs/` are the source. After editing them, update both
pages there and change the effective date.

## What the audit found

| Path off the device | What leaves | Where | Notes |
| --- | --- | --- | --- |
| Reverse geocoding | Approximate coordinates of the fix, twice (`en`, `ar`) | Android `Geocoder`, Google Play services | `DeviceLocationService._describe`, `lib/core/services/device_location_service.dart:183` |
| City search | The typed search text, then the coordinates of up to 5 hits | Android `Geocoder`, Google Play services | `DeviceLocationService.searchPlaces`, `device_location_service.dart:123` |
| Location fix | Nothing from Hayya. Fused location may use Wi-Fi/cell data under the device's Google location settings | Google Play services | geolocator's `FusedLocationClient`, `LocationAccuracy.low` |
| Android Auto Backup | Shared preferences and the Hive `tracker` box (`app_flutter/`) | The user's Google account | On by default: the manifest doesn't set `allowBackup`. There are no backup rules. |
| Privacy policy link | Nothing from Hayya. The browser opens the GitHub Pages URL | GitHub, in the user's browser | `about_group.dart` |

Things that don't send data:

- **No `INTERNET` permission in release builds.** The merged release
  manifest has none (only `src/debug` and `src/profile` add it for
  development), so the app process can't open a socket. The geocoder runs in
  Google Play services' process.
- **Notifications** are local (`flutter_local_notifications`, scheduled with
  `AlarmManager`). There's no push service and no Firebase.
- **Fonts**: `google_fonts` is set to `allowRuntimeFetching = false`
  (`lib/main.dart:17`). The fonts are bundled.
- **No crash reporting, analytics, ads or attribution SDKs.** `pubspec.lock`
  has no Firebase, Crashlytics, Sentry, AdMob or Facebook packages. `http`
  is a transitive dependency (of `google_fonts`, `lottie`, `flutter_svg`,
  `vector_graphics`, `timezone` and `package_info_plus`), and
  `web_socket_channel` comes only from dev tooling. Hayya never loads
  anything from a URL, and release builds couldn't reach the network
  anyway.
- **Compass**, `flutter_timezone`, `package_info_plus` and `workmanager`
  only read device state.

## Permissions

The merged release manifest, and what uses each permission:

| Permission | Used by | Needed |
| --- | --- | --- |
| `ACCESS_COARSE_LOCATION` | `DeviceLocationService` (geolocator, `LocationAccuracy.low`) | Yes |
| `POST_NOTIFICATIONS` | Adhan and reminder notifications (Android 13+) | Yes |
| `SCHEDULE_EXACT_ALARM` | On-time adhan. Falls back to inexact alarms without it | Yes |
| `RECEIVE_BOOT_COMPLETED` | flutter_local_notifications' boot receiver and WorkManager's reschedule receiver | Yes |
| `VIBRATE` | flutter_local_notifications. Notifications vibrate by default, and the plugin calls `setVibrate` | Kept: before Android 8 (minSdk is 24), notification vibration may need it. It's an install-time permission with no prompt |
| `WAKE_LOCK` | WorkManager, which holds wake locks while it runs work | Yes |
| `ACCESS_NETWORK_STATE` | WorkManager's network constraint tracking. Our task has no network constraint | Kept: it's an install-time permission with no prompt and no Play declaration. Removing it risks a `SecurityException` inside WorkManager for no user-visible gain |
| `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | androidx.core, an app-private signature permission for non-exported receivers | Yes |
| ~~`FOREGROUND_SERVICE`~~, ~~`FOREGROUND_SERVICE_SHORT_SERVICE`~~ | workmanager_android, only for workers given a `foregroundServiceConfig` or registered as expedited | **Removed** with `tools:node="remove"` in `AndroidManifest.xml`. `workmanager_background_tasks_test.dart` checks that neither task uses those options |

## The form

### Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes**: approximate location (see the note below) |
| Is all of the user data collected by your app encrypted in transit? | **Yes**: Google's geocoder uses HTTPS ⚠️ (see *Unsure*) |
| Do you provide a way for users to request that their data is deleted? | **No.** Nothing is stored off the device. The "Data deletion" answer can explain that data lives only on the device and is removed by uninstalling or clearing app data. |

### Data types

**Location → Approximate location**

| Question | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** |
| Processed ephemerally? | **Yes**: the coordinates are sent only to get place names, and Hayya keeps nothing off the device |
| Required or optional? | **Required**: prayer times need a location, and both the device fix and the city search go through the geocoder |
| Why is it collected? | **App functionality** |

**Location → Precise location**: not collected. The app requests only
`ACCESS_COARSE_LOCATION` and asks for `LocationAccuracy.low`.

Every other data type is **not collected**: personal info, financial info,
health and fitness, messages, photos and videos, audio, files and docs,
calendar, contacts, app activity, web browsing, app info and performance
(no crash logs or diagnostics), and device or other IDs.

The prayer tracker, settings and saved location stay on the device. Play
doesn't count on-device data as collected. ⚠️ See *Unsure* for backups.

### Other App content items

- **Privacy policy**: `https://ahmed-waheed1.github.io/hayya-privacy/`
- **Ads**: the app contains no ads.
- **Target audience**: pick the age groups you want. The privacy policy says
  Hayya isn't aimed at children in particular. Choosing under-13 age groups
  brings in the Families policy requirements.

## ⚠️ Unsure, check before submitting

1. **Is OS geocoding "collection"?** Play defines collection as data your
   app transmits off the device, and that includes data sent through
   libraries and SDKs. Hayya calls an Android platform API, and Google Play
   services sends the request. That arguably isn't Hayya transmitting it.
   Declaring approximate location as collected and ephemeral is the
   conservative answer, and that's what the form above uses. Declaring
   nothing is defensible, but riskier if a reviewer disagrees.
2. **Encrypted in transit.** Hayya can't see how Google Play services sends
   geocoder requests. HTTPS is a reasonable assumption for a Google service,
   but it isn't something this audit verified.
3. **Android Auto Backup.** As far as I know, data backed up through
   Android's own backup service (to the user's Google account) doesn't
   need to be declared. Check Play's current Data safety help before
   relying on that. To avoid the question, turn backup off with
   `android:allowBackup="false"`, or restrict it with
   `dataExtractionRules`/`fullBackupContent`. The policy would then need its
   backup section updated.
4. **Exact alarms.** The release manifest includes `SCHEDULE_EXACT_ALARM`.
   Play Console may ask you to justify it (on-time adhan) when you upload.
   That's a separate form from Data safety. There's no foreground service
   declaration: `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_SHORT_SERVICE`
   from `workmanager_android` are removed (see *Permissions* below).
5. **iOS.** This audit covers Android. On iOS the geocoder is Apple's
   (`CLGeocoder`), backups go to iCloud, and the permission list differs.
   Update the policy before shipping on the App Store.
