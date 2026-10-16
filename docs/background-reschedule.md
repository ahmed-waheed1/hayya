# Background adhan reschedule

The adhan notifications are planned a few days ahead and replanned whenever
the app opens. For someone who rarely opens the app, the schedule would run
out, so a daily background task tops it up.

## What runs

`rescheduleAdhanInBackground()` in `lib/core/di/background_reschedule.dart`.
It builds the minimum it needs from what is saved on disk and hands it to
the app's own `AdhanScheduler`, `PlanAdhanNotifications` and
`LocalizedNotificationTexts`. There is no second copy of the scheduling
logic.

- **Location**: the city chosen by hand, otherwise the cached device fix
  (`LocationService.lastKnown`). It never locates: no GPS, no geocoding, no
  network, no permission prompt. With no saved location it schedules
  nothing, as the app does.
- **Settings**: the saved calculation settings and adhan preferences
  (prayers on, reminder, volume).
- **No UI**: it shows nothing and asks for nothing. Notification and exact
  alarm permissions are whatever the user already granted. Without exact
  alarms, notifications are scheduled inexactly, as in the app.
- **Not `configureDependencies`**: that opens the tracker's Hive box, which
  the app may hold open at the same time.

### Language and digits

A background isolate has no `BuildContext`, so it can't use the app's
`EasyLocalization` or `MediaQuery`. It picks what the app would:

| | Source |
| --- | --- |
| Language | The chosen one (`language_code`); otherwise the device's, if it is English or Arabic; otherwise English (`resolveAppLocale`, as `EasyLocalization` does) |
| Digits | The chosen numerals (`numerals`) |
| 12/24-hour | The chosen format (`time_format`); otherwise the device setting the app last saw (`device_uses_24_hour`, saved by `AdhanNotificationsSync`), since there is no view to read it from |

The translations are loaded with `loadTranslationsWithoutContext`
(`lib/core/utils/app_locales.dart`), with Arabic plural rules on as in the
app. Each notification's text comes from `LocalizedNotificationTexts`, as
in the foreground.

## When it runs

`WorkmanagerBackgroundTasks` (`lib/core/services/`) registers it with
[workmanager](https://pub.dev/packages/workmanager):

- **Registered** on every launch (`main.dart`) and again after onboarding
  (`OnboardingStatus.complete`). It uses one unique name,
  `com.ahmedwaheed.hayya.adhanReschedule`, with
  `ExistingPeriodicWorkPolicy.update`, so registering again updates the
  task in place. It is never duplicated and its schedule isn't pushed back.
- **Android**: WorkManager runs it about once a day (`frequency: 1 day`;
  the minimum is 15 minutes), with no constraints. WorkManager keeps the
  task in its own database and restores it after a reboot or an app
  update. Each run starts a headless Flutter engine at
  `backgroundTaskDispatcher`. That must stay a top-level
  `@pragma('vm:entry-point')` function with the same name, because it is
  found again by name.
- **iOS**: see [below](#ios).

The dispatcher calls `DartPluginRegistrant.ensureInitialized()` first.
Plugins implemented in Dart (`shared_preferences`, for example) aren't
registered in a background isolate otherwise.

If the app is open while the task runs, both reschedule. On Android each
plugin call runs on the main thread, so they interleave call by call. The
run that cancels last also schedules everything after that, so nothing is
lost. On iOS a one-off task can run on the app's own engine. The
dispatcher then reschedules through the app's `AdhanScheduler`, without
reloading translations, which would replace the app's.

## How far ahead

`NotificationService.planDays` sets the horizon:

| | Days planned | Cap |
| --- | --- | --- |
| Android | 7 (topped up daily) | 500 pending |
| iOS | Up to 64, as far as the cap allows (about 12 days with every adhan on, 6 with reminders too) | 64 pending, the system limit |

## Testing it

- `test/core/background_reschedule_test.dart`: the entry point schedules
  the same plan as the app (cached fix, chosen city, prayers on), in the
  chosen or device language with the right digits and clock, fills 64
  slots on iOS, and never calls the location plugins' channels.
- `test/core/workmanager_background_tasks_test.dart`: one daily task under
  one name, updated in place, and failures never reach the app.
- On a device, in a debug build: **Settings → Developer → Run background
  reschedule now** queues a one-off run of the same task, which on Android
  runs in a headless engine like the daily one. Its log line is
  `Background adhan reschedule ran (en)` (`adb logcat -s flutter`).
  WorkManager also runs the daily task once right after it is first
  registered (a fresh install, or after clearing data), and logs
  `Worker result SUCCESS` for it. Forcing the periodic job with
  `adb shell cmd jobscheduler run -f` doesn't help: WorkManager won't run
  it before its period is up and just queues it again.

## iOS

iOS decides when background work runs, and may never run it, for example
if the user swipes the app away or rarely opens it. So it isn't relied on:
iOS plans as far ahead as the 64-notification cap allows (see above), and
the background task only helps on top of that.

The setup:

- `Info.plist`: `BGTaskSchedulerPermittedIdentifiers` lists
  `com.ahmedwaheed.hayya.adhanReschedule`, and `UIBackgroundModes` has
  `fetch` (needed for a `BGAppRefreshTask`).
- `AppDelegate.swift`: `WorkmanagerPlugin.registerPeriodicTask` registers
  the launch handler before `didFinishLaunching` returns. With UIScene,
  plugins register too late for `BGTaskScheduler`.
  `setPluginRegistrantCallback` gives the headless engine the app's
  plugins.
- The earliest next run is 12 hours (`iosEarliestBegin`, and the same
  value in AppDelegate). iOS usually runs it later.

### To check on a Mac

This hasn't been built for iOS yet; there is no Mac here.

1. `flutter build ios --debug --no-codesign` builds; Xcode resolves the
   `workmanager_apple` Swift package, and `import workmanager_apple` in
   AppDelegate.swift compiles.
2. In Xcode, Runner target → Signing & Capabilities: **Background Modes**
   shows "Background fetch" ticked (from Info.plist). If Xcode wants the
   capability added, add it with only that box.
3. Run on a device, open the app once, then simulate the task. Pause in
   the debugger and run:

   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.ahmedwaheed.hayya.adhanReschedule"]
   ```

   then continue. The console shows
   `Background adhan reschedule ran (…)`, and no prompt appears.
4. Settings → Developer → **Run background reschedule now** also logs it.
5. With every adhan and reminders on, the pending count is 64, not 70: in
   the debugger,
   `UNUserNotificationCenter.current().getPendingNotificationRequests`
   returns 64 requests.
6. Settings → General → Background App Refresh lists Hayya.
