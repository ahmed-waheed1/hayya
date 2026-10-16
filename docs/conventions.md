# Hayya conventions

Hayya (حيّ) is a bilingual (English / Arabic RTL) prayer times and Qibla app
built with Flutter: prayer times, Qibla compass, prayer tracker, monthly
timetable, settings, onboarding. These are the rules the code follows.

## Architecture

- **Feature-first clean architecture**: `lib/features/<feature>/{data,domain,presentation}`.
  Shared code lives in `lib/core/` (`theme/`, `widgets/`, `di/`, `router/`,
  `utils/`, …).
- **State**: Cubit (`flutter_bloc`). **DI**: `get_it`, registered in
  `lib/core/di/injection.dart`. **Routing**: `go_router`, in
  `lib/core/router/app_router.dart`.
- **Ask before adding any new package.**

## Text, numbers and direction

- **No hardcoded strings.** All user-facing text goes through `LocaleKeys`
  (`lib/generated/locale_keys.g.dart`), with `easy_localization`. Add each key
  to **both** `assets/translations/en.json` and `ar.json`, then regenerate:

  ```sh
  dart run easy_localization:generate -S assets/translations -f keys -O lib/generated -o locale_keys.g.dart
  ```

- **Numbers, times and dates go through `context.format`** (`LocalizedFormat`
  in `lib/core/utils/localized_format.dart`). It applies the user's numerals
  (Arabic-Indic or Western, Arabic only) and 12/24-hour choice, and makes the
  widget rebuild when they change. Never format digits by hand.
- **Directional widgets only**: `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `start`/`end`. Never use left/right.

## Layout and sizing

- `flutter_screenutil`: `.r` for sizes and spacing, `.sp` for fonts.
- Choose layouts by the space available, not the screen: phone < 600,
  tablet >= 600 (`Breakpoints` / `ResponsiveBuilder` in
  `lib/core/utils/responsive.dart`).
- Touch targets are at least 44 × 44; use `TapTarget`.

### Text scaling

The app must work at every system font size, up to 2.0×.

- **Never put text inside a fixed height** (or a fixed-size box). Use minimum
  heights (`BoxConstraints(minHeight: …)`) so the widget grows with the text.
  Fixed sizes are only for things without text: icons, dots, bars, chart
  cells.
- A label beside trailing controls goes in **`AdaptiveRow`**
  (`lib/core/widgets/adaptive_row.dart`), not a `Row` with an `Expanded`
  label. With large text the controls move under the label instead of
  squeezing it into broken words.
- Use `FittedBox` only to fit text into a fixed graphic, and never so that
  text ends up smaller than it is at 1.0×.
- At 1.0× the design must not change.
- **Every new screen, sheet and state is added to `test/text_scale_test.dart`**
  (see [Text-scale matrix](#text-scale-matrix)).

## Theme and components

- Tokens live in `lib/core/theme/`: `HayyaColors` and `HayyaTypography` are
  `ThemeExtension`s, alongside `HayyaSpacing`, `HayyaRadius` and `HayyaTheme`.
  Read them with `context.colors` and `context.type`. Don't hardcode colors or
  sizes.
- Reusable widgets live in `lib/core/widgets/` (import `widgets.dart`).
- Settings has a **Developer** section in debug builds only (`kDebugMode`),
  with "Test adhan in 1 minute" for checking notifications on a device. Put
  any other debug-only tools there, never in release builds.

## Fonts

- Manrope for Latin text (the design uses Manrope, not Inter), Cairo for
  Arabic, switched by locale.
- The fonts are bundled in `assets/fonts/` (Regular, Medium, SemiBold, Bold,
  ExtraBold), and `GoogleFonts.config.allowRuntimeFetching = false` is set in
  `main.dart`. The OFL licenses are registered with `LicenseRegistry`.
- To change a font weight, use `context.type.style(size, weight)`. Never use
  `copyWith(fontWeight: …)`: google_fonts binds each weight to its own file,
  so `copyWith` won't load the new weight. Any new weight also needs a
  matching `Family-WeightName.ttf` in `assets/fonts/`.

## Qibla compass

True-north correction uses WMM2025, which **expires at the end of 2029**, and
iOS must not be corrected twice. See [magnetic-declination.md](magnetic-declination.md).

## Testing

### Workflow

| When | Command | Runs |
| --- | --- | --- |
| While working | `flutter test --exclude-tags text-scale` | everything except the text-scale matrix (about 2.5 min) |
| Before every commit and every PR | `flutter test` | the full suite, matrix included (about 10 min) |

Before committing, also run `dart format lib test` and `flutter analyze`; both
must be clean.

### Text-scale matrix

`test/text_scale_test.dart` runs every screen and state at 1.0×, 1.3×, 1.6×
and 2.0× text, in English and Arabic, on five screen sizes (phone, 320 × 568,
phone landscape, tablet, tablet portrait). It fails on:

- overflow and other layout exceptions
- truncated text (ellipsis or past `maxLines`)
- clipped text (taller than its box)
- a word broken in the middle
- text drawn smaller than at 1.0×

It is tagged `text-scale` (declared in `dart_test.yaml`). To list every issue
instead of stopping at the first:

```sh
flutter test test/text_scale_test.dart --dart-define=PROBE=true
```

Add each new screen, sheet and state there: register it with
`textScaleMatrix` (from `test/helpers/text_scale.dart`) and call `check` at
each state.

### Layout tests

- `test/helpers/pump_app.dart` boots the full app (`pumpHayyaApp`) with
  fonts, translations and mocked preferences loaded. Pass `now:` for anything
  that depends on the date; tests must not read the real clock.
- Widget tests render with a placeholder font where every glyph is 1 em wide
  until the real fonts load, so overflow results are wrong until then. Load
  the bundled fonts first: pump text in every family and weight, then run a
  few `tester.runAsync(delay)` + `pump` rounds. `GoogleFonts.pendingFonts()`
  hangs inside the fake-async zone.
- `.tr()` returns the raw key when translations aren't loaded, which also
  skews measured widths.
- Design mocks can hide overflows, because HTML flex items shrink silently.
  Measure tight rows in both locales.

## Git workflow

- Every change goes on its own branch, created from an up-to-date `master`:
  `feature/<name>`, `fix/<name>` or `chore/<name>`. Never commit directly to
  `master`.
- Run the full suite before each commit (see [Workflow](#workflow)).
- Push the branch (`git push -u origin <branch>`) and open a pull request
  with `gh pr create --base master`.
- Merge with `gh pr merge --merge --delete-branch`, then
  `git switch master && git pull`.
- Avoid stacking PRs. If one PR is based on another's branch, retarget it
  first (`gh pr edit <n> --base master`). Merging the base with
  `--delete-branch` closes the stacked PR instead of retargeting it.
