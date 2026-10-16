# Hayya privacy policy

**Effective date: 16 October 2026**

Hayya (حيّ) shows prayer times, the Qibla direction and a prayer tracker.
It has no accounts, no ads, no analytics and no crash reporting. Everything
it saves stays on your device. The only exception is looking up place
names, described below.

## What Hayya stores on your device

- **Your location**: the approximate coordinates of your last location fix,
  or the city you chose by hand, with the city and country names (in
  English and Arabic). Hayya uses them to calculate prayer times and the
  Qibla direction, and to show where you are.
- **Your settings**: language, numerals, 12/24-hour clock, theme, prayer
  calculation method, Asr method, high-latitude rule, Hijri date adjustment,
  and which adhan notifications and reminders are on.
- **Your prayer tracker**: which prayers you marked as prayed on each day,
  the date you started tracking, and your missed (qada) prayer counts.
- **Scheduled notifications**: the upcoming adhan and reminder times, so the
  system can show them on time and restore them after a restart.

Hayya does not send any of this to us or to anyone else. We don't run a
server, and the Android app doesn't even have permission to use the
internet.

## The exception: place names

To turn coordinates into a city name ("Cairo, Egypt"), and to find a city
when you search for one, Hayya uses your phone's built-in geocoding
service. On Android this is provided by Google (through Google Play
services), and it sends the request over the internet:

- after a location fix: the approximate coordinates, once for the English
  name and once for the Arabic one;
- when you search for a city: the text you typed.

Hayya doesn't add anything else to these requests, and we never see
them. Google handles them under its own privacy policy
(<https://policies.google.com/privacy>). If geocoding fails, for example
when you're offline, Hayya still works and keeps the last names it had.

Your phone's location service may also use Wi-Fi and mobile networks to
find your position. That is part of Android and follows your device's
location settings, not Hayya.

## Backups

If Android backup is turned on, Android may back up Hayya's data (the
location, settings and tracker described above) to **your own Google
account** and restore it when you reinstall Hayya or set up a new phone.
It may also copy it directly when you move to a new phone. This is
Android's backup service: Google stores the backup, we can't access it,
and you control it in your phone's settings (usually Settings → Google →
Backup). Google says these backups are encrypted, and on Android 9 and
later end-to-end encrypted with your screen lock when you have one.

## Permissions

Hayya asks for these permissions on Android:

| Permission | Why |
| --- | --- |
| Approximate location | To calculate prayer times and the Qibla direction for where you are. Hayya never asks for precise location. You can refuse and choose a city instead. |
| Notifications | To play the adhan and show reminders at prayer times. |
| Alarms & reminders | To show the adhan exactly on time. Without it, notifications may arrive a few minutes late. |
| Run at startup | To set the adhan notifications again after your phone restarts. |
| Vibration | For notifications. |
| Background work (keep awake, foreground service, network state) | These come with Android's WorkManager library, which Hayya uses once a day to plan upcoming adhans. That task uses only the location you saved; it never locates you or uses the network. |

The Qibla compass uses your phone's motion sensors. Their readings are
used live and never saved.

## Children

Hayya is for everyone and isn't aimed at children in particular. It
doesn't collect personal information from anyone, including children.

## Deleting your data

Everything Hayya saves is on your device, so you can delete it yourself:

- **Uninstall Hayya**, or
- **Clear its data**: Settings → Apps → Hayya → Storage → Clear data.

To remove an Android backup as well, delete it from your Google account
(Google Drive → Backups, or your phone's backup settings).

## Changes

If this policy changes, we'll update it here and change the effective date.

## Contact

Questions about this policy: <ahm761171@gmail.com>
