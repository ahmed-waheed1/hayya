"""Generates the WMM Dart sources from NOAA's coefficient download.

Usage (from the repo root, after unzipping WMM20xxCOF.zip):
  python3 tool/generate_wmm.py WMM.COF WMM20xx_TestValues.txt \
      lib/features/qibla/domain/wmm2025_coefficients.dart \
      test/features/qibla/fixtures/wmm2025_test_values.dart
"""
import sys, hashlib
cof, tv, out_lib, out_test = sys.argv[1:5]
raw = open(cof, 'rb').read()
lines = raw.decode().splitlines()
epoch, name, released = lines[0].split()
rows = []
for l in lines[1:]:
    p = l.split()
    if p[0].startswith('9999'): break
    n, m = int(p[0]), int(p[1]); g, h, gd, hd = p[2:6]
    rows.append((n, m, g, h, gd, hd))
assert len(rows) == 90 and rows[-1][:2] == (12, 12), len(rows)
with open(out_lib, 'w') as f:
    f.write(f"""// GENERATED from NOAA's {name} coefficient file (WMM.COF, released
// {released}, sha256 {hashlib.sha256(raw).hexdigest()[:16]}…), from
// https://www.ncei.noaa.gov/products/world-magnetic-model/wmm-coefficients
// Do not edit by hand. The model is valid {epoch}–{float(epoch) + 5:.1f};
// replace it with the next WMM before then (see CLAUDE.md).

/// Epoch of the coefficients, in decimal years.
const wmmEpoch = {epoch};

/// Last decimal year the coefficients are valid for.
const wmmValidUntil = {float(epoch) + 5:.1f};

/// Schmidt semi-normalized Gauss coefficients in nT, and their yearly
/// change in nT/year: (n, m, g, h, ġ, ḣ), degree and order 1–12.
const wmmCoefficients = <(int, int, double, double, double, double)>[
""")
    for n, m, g, h, gd, hd in rows:
        f.write(f"  ({n}, {m}, {g}, {h}, {gd}, {hd}),\n")
    f.write("];\n")
pts = []
for l in open(tv):
    if l.startswith('#') or not l.strip(): continue
    p = l.split()
    pts.append((p[0], p[1], p[2], p[3], p[4]))
with open(out_test, 'w') as f:
    f.write("""// GENERATED from NOAA's WMM2025_TestValues.txt (shipped with the WMM2025
// coefficients). Declinations are given to 0.01°.

/// (decimal year, altitude km, geodetic latitude, longitude, declination).
const wmm2025TestValues = <(double, double, double, double, double)>[
""")
    for y, a, la, lo, d in pts:
        f.write(f"  ({float(y)}, {float(a)}, {float(la)}, {float(lo)}, {float(d)}),\n")
    f.write("];\n")
print(len(rows), 'coefficients;', len(pts), 'test points')
