# Hayya (حيّ)

A prayer times and Qibla app for Android and iOS, built with Flutter, in
English and Arabic (right-to-left). Prayer times and the Qibla direction are
calculated on the device, so they work offline.

## Features

- **Onboarding** on first launch: pick English or Arabic, then the location
  and notification permissions, each explained before the system asks. Every
  step can be skipped or refused; choose a city by hand instead of sharing
  your location, and turn either on later in Settings.
- **Prayer times** for your location, with the current and next prayer and a
  live countdown. Choose the calculation method, the Asr madhab, a
  high-latitude rule and per-prayer minute adjustments.
- **Adhan notifications** for each prayer, with an optional reminder before it.
- **Qibla compass** with true-north correction, plus guidance when the
  compass needs calibrating or the device has none.
- **Prayer tracker**: mark prayers as prayed, see your streak, a heatmap and
  missed prayers per prayer, and keep count of prayers to make up (qada).
- **Monthly timetable** with Gregorian and Hijri dates.
- **Settings** for language, theme, numerals (Arabic-Indic or Western),
  12/24-hour time, location (GPS or a chosen city) and the Hijri date.

Phone and tablet layouts, light and dark themes, and system font sizes up to
2.0× are all supported.

## Running it

```sh
flutter pub get
flutter run
```

## Tests

```sh
# While working: everything except the text-scale matrix (about 2.5 min).
flutter test --exclude-tags text-scale

# Before every commit and PR: the full suite (about 10 min).
flutter test
```

## Documentation

- [docs/conventions.md](docs/conventions.md): the project rules covering
  architecture, localization, layout and text scaling, testing and the git
  workflow. Read this before contributing.
- [docs/](docs/): details on specific topics, such as the
  [magnetic declination model](docs/magnetic-declination.md) behind the Qibla
  compass, the [adhan notification sounds](docs/adhan-sounds.md) and the
  [release process](docs/release.md).
- [Privacy policy](docs/privacy-policy.md) ([Arabic](docs/privacy-policy.ar.md)),
  published at <https://ahmed-waheed1.github.io/hayya-privacy/>, and the
  [Play Data safety answers](docs/play-data-safety.md).
