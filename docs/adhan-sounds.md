# Adhan notification sounds

The source recording is `assets/sounds/adhan.mp3` (3:07, MP3 22 kHz
stereo). Notification sounds can't be read from Flutter assets, so each
platform has its own copy, made from that file:

```sh
# Android: the full adhan, cover art stripped.
ffmpeg -i assets/sounds/adhan.mp3 -map 0:a -c copy -map_metadata -1 \
  android/app/src/main/res/raw/adhan.mp3
# iOS: first 30 s (the system limit), 2.5 s fade-out, 16-bit PCM mono.
ffmpeg -i assets/sounds/adhan.mp3 -map 0:a -t 30 -af "afade=t=out:st=27.5:d=2.5" \
  -ac 1 -ar 22050 -c:a pcm_s16le -f caf ios/Runner/adhan.caf
```

`ios/Runner/adhan.caf` is already in the Runner target's Copy Bundle
Resources.

| Where | File | Format | Notes |
| --- | --- | --- | --- |
| Android | `android/app/src/main/res/raw/adhan.mp3` | MP3 (or OGG as `adhan.ogg`, never both) | Lower-case letters, digits and `_` only. Plays in full. |
| iOS | `ios/Runner/adhan.caf`, in the Runner target's resources | CAF, Linear PCM or IMA4, **30 s or less** | Longer or missing files play the default sound instead. |
| Source / in-app preview (later) | `assets/sounds/adhan.mp3` | MP3 | The source recording. **Not bundled**: `assets/sounds/` is left out of `pubspec.yaml` until the preview exists, so the app doesn't ship an unused 1.5 MB copy. Add it back then. |

## Changing a sound later

An Android channel stores its sound as a name
(`android.resource://<package>/raw/adhan`), so replacing `adhan.mp3` with
new audio under the **same name** takes effect on existing installs.

What a channel can't change after creation is its settings: which file
name it plays, its importance, its audio usage. To change any of those,
bump the channel id in `lib/core/services/notification_service.dart`
(`NotificationSound.adhan`, currently `adhan_v2`) and add the old id to
`NotificationSound.retiredChannelIds`, which are deleted at startup.

`adhan_v2` plays on the **alarm stream** (`USAGE_ALARM`): alarm volume,
and it sounds in silent/vibrate mode. `adhan_v1` used the notification
stream and is retired. The reminder stays on the notification stream.

Settings → Notifications → Adhan volume lets the user pick the stream.
"Notification volume" uses a second channel, `adhan_notification_v1`
(`NotificationSound.adhanNotificationVolume`): the same `adhan` file on
`USAGE_NOTIFICATION`, so silent mode silences it. Both channels always
exist; `AdhanScheduler` puts each adhan on the chosen one and reschedules
when the choice changes. iOS has no such choice (notification sounds
always follow the silent switch), so the setting is shown on Android only.

## Stopping the adhan

Removing the notification stops its sound: tapping it (opens the app,
auto-cancel), swiping it away, or "Clear all". Opening the notification
shade while it plays also stops the sound and leaves the notification.

Deliberately not used:

- `FLAG_INSISTENT` loops the sound until the notification is removed.
  With a 3-minute adhan that means it never ends on its own. That suits
  an alarm clock, not a call to prayer that should play once.
- A full-screen intent wakes the screen into an activity, like an alarm
  clock. It needs `USE_FULL_SCREEN_INTENT`, which Android 14+ grants by
  default only to calling and alarm-clock apps (others must ask the user,
  and Play reviews the declaration), plus a dedicated "adhan playing"
  screen. It's only worth adding if an in-app stop screen is wanted.

## More voices

The Settings design lists several voices (Makkah, Madinah, Cairo classic,
Takbir only, Silent). Each will be one more `NotificationSound` value with
its own channel id and file, e.g. `adhan_madinah.mp3` / `adhan_madinah.caf`,
plus an entry in `android/app/src/main/res/raw/keep.xml` so release builds
don't strip it.
