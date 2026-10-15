# Magnetic declination (Qibla compass)

The Qibla bearing is measured from **true** north, but Android's compass
heading is measured from **magnetic** north. The difference is the magnetic
declination: about +4.8° in Cairo and −12.5° in New York. Without the
correction the "aligned" state is off by that much.

`QiblaCubit` adds the declination at the user's location, computed with
the World Magnetic Model in `lib/features/qibla/domain/magnetic_declination.dart`.

iOS is different: the flutter_compass plugin reports CoreLocation's
`trueHeading`, which is already true north. **It must not be corrected
again.** Each `CompassReading` carries a required `NorthReference`
(`magnetic` or `trueNorth`), which `FlutterCompassSensor` sets per
platform, and the cubit only corrects `magnetic` readings.

## The model expires

| File | What it is |
| --- | --- |
| `lib/features/qibla/domain/wmm2025_coefficients.dart` | WMM2025 Gauss coefficients, generated from NOAA's `WMM.COF` |
| `test/features/qibla/fixtures/wmm2025_test_values.dart` | NOAA's 100 official test points, generated from `WMM2025_TestValues.txt` |
| `tool/generate_wmm.py` | Generates both files |

**WMM2025 is valid from 2025.0 to 2030.0, so it expires at the end of
2029.** After that it keeps working, but its error grows every year. NOAA
releases the next model (WMM2030) in late 2029.

## Replacing it with the next model

1. Download the coefficient zip (`WMM2030COF.zip`) from
   <https://www.ncei.noaa.gov/products/world-magnetic-model/wmm-coefficients>
   and unzip it. It holds `WMM.COF` and `WMM2030_TestValues.txt`.
2. Rename the generated files to the new year, and update their imports:

   ```sh
   git mv lib/features/qibla/domain/wmm2025_coefficients.dart \
     lib/features/qibla/domain/wmm2030_coefficients.dart
   git mv test/features/qibla/fixtures/wmm2025_test_values.dart \
     test/features/qibla/fixtures/wmm2030_test_values.dart
   ```

3. Regenerate them from the repo root, then format:

   ```sh
   python3 tool/generate_wmm.py path/to/WMM.COF path/to/WMM2030_TestValues.txt \
     lib/features/qibla/domain/wmm2030_coefficients.dart \
     test/features/qibla/fixtures/wmm2030_test_values.dart
   dart format lib/features/qibla/domain/wmm2030_coefficients.dart \
     test/features/qibla/fixtures/wmm2030_test_values.dart
   ```

   The test fixture's constant is named after the model
   (`wmm2030TestValues`); update its uses in
   `test/features/qibla/domain/magnetic_declination_test.dart`.
4. Get new reference values from NOAA's calculator,
   <https://www.ngdc.noaa.gov/geomag/calculators/magcalc.shtml>: model
   WMM, elevation 0, for Cairo (30.0444, 31.2357), New York (40.7128,
   −74.0060), Jakarta (−6.2088, 106.8456) and London (51.5074, −0.1278),
   on two dates inside the new model's validity window. Replace the values
   and dates in the "NOAA calculator" group of
   `magnetic_declination_test.dart`. Also update the cubit tests that use
   the Cairo and New York declinations (`qibla_cubit_test.dart`, group
   "true north").
5. Update the validity test (`the model covers …`) to the new epoch, then
   run `flutter test test/features/qibla`. The 100 official test points
   must all pass within 0.0051° (they're published to 0.01°), and the
   calculator values within 0.0001°.
6. Update the dates in this file.
