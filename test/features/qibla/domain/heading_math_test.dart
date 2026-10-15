import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/qibla/domain/heading_math.dart';
import 'package:hayya/features/qibla/domain/qibla_alignment.dart';

void main() {
  group('normalizeDegrees', () {
    test('folds into 0–360', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(725), 5);
      expect(normalizeDegrees(-10), 350);
      expect(normalizeDegrees(-725), 355);
    });
  });

  group('shortestTurn', () {
    test('turns the short way across north', () {
      expect(shortestTurn(350, 10), closeTo(20, 1e-9));
      expect(shortestTurn(10, 350), closeTo(-20, 1e-9));
      expect(shortestTurn(359, 1), closeTo(2, 1e-9));
    });

    test('is within (−180, 180]', () {
      expect(shortestTurn(0, 180), 180);
      expect(shortestTurn(180, 0), 180);
      expect(shortestTurn(0, 181), closeTo(-179, 1e-9));
      expect(shortestTurn(90, 90), 0);
    });

    test('accepts unwrapped headings', () {
      expect(shortestTurn(720 + 113, 136), closeTo(23, 1e-9));
      expect(shortestTurn(-247, 136), closeTo(23, 1e-9));
    });
  });

  group('HeadingSmoother', () {
    test('starts at the first reading', () {
      final smoother = HeadingSmoother();
      expect(smoother.value, isNull);
      expect(smoother.add(-90), 270);
    });

    test('takes the short way from 359° to 1°, past 360', () {
      final smoother = HeadingSmoother(smoothing: 0.5)..add(359);
      final values = [for (var i = 0; i < 20; i++) smoother.add(1)];

      // Rising steadily toward 361 (= 1°), never back down through 180.
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]));
      }
      expect(values.every((v) => v >= 359 && v <= 361), isTrue);
      expect(values.last, closeTo(361, 0.01));
      expect(normalizeDegrees(values.last), closeTo(1, 0.01));
    });

    test('takes the short way from 1° to 359°, below 0', () {
      final smoother = HeadingSmoother(smoothing: 0.5)..add(1);
      for (var i = 0; i < 20; i++) {
        smoother.add(359);
      }
      expect(smoother.value, closeTo(-1, 0.01));
    });

    test('damps jitter', () {
      final smoother = HeadingSmoother()..add(100);
      final out = <double>[];
      for (var i = 0; i < 40; i++) {
        out.add(smoother.add(i.isEven ? 104 : 96)); // ±4° noise
      }
      final settled = out.skip(10);
      final spread =
          settled.reduce((a, b) => a > b ? a : b) -
          settled.reduce((a, b) => a < b ? a : b);
      expect(spread, lessThan(3)); // vs 8° raw
      expect(settled.last, closeTo(100, 2));
    });

    test('keeps unwrapping over many turns', () {
      final smoother = HeadingSmoother(smoothing: 1);
      for (var turn = 0; turn < 3; turn++) {
        for (var h = 0.0; h < 360; h += 30) {
          smoother.add(h);
        }
      }
      expect(smoother.value, closeTo(2 * 360 + 330, 1e-9));
    });

    test('reset starts over', () {
      final smoother = HeadingSmoother()..add(50);
      smoother.reset();
      expect(smoother.value, isNull);
      expect(smoother.add(10), 10);
    });
  });

  group('AlignmentTracker', () {
    const bearing = 136.0;

    test('aligns within 3°, either side', () {
      expect(AlignmentTracker().update(heading: 133, bearing: bearing), isTrue);
      expect(AlignmentTracker().update(heading: 139, bearing: bearing), isTrue);
      expect(
        AlignmentTracker().update(heading: 132.9, bearing: bearing),
        isFalse,
      );
      expect(
        AlignmentTracker().update(heading: 113, bearing: bearing),
        isFalse,
      );
    });

    test('stays aligned until past 5° (no flicker at the edge)', () {
      final tracker = AlignmentTracker();
      expect(tracker.update(heading: 136, bearing: bearing), isTrue);
      expect(tracker.update(heading: 140, bearing: bearing), isTrue);
      expect(tracker.update(heading: 131, bearing: bearing), isTrue);
      expect(tracker.update(heading: 141.5, bearing: bearing), isFalse);
      // Back inside 5° but not 3°: still not aligned.
      expect(tracker.update(heading: 140, bearing: bearing), isFalse);
      expect(tracker.update(heading: 138, bearing: bearing), isTrue);
    });

    test('jitter around the entry edge changes state only once', () {
      final tracker = AlignmentTracker();
      final changes = <bool>[];
      var last = false;
      for (final h in [
        130.0,
        132.8,
        133.2,
        132.9,
        133.1,
        132.5,
        134.0,
        132.0,
      ]) {
        final now = tracker.update(heading: h, bearing: bearing);
        if (now != last) changes.add(now);
        last = now;
      }
      expect(changes, [true]);
    });

    test('works across north and with unwrapped headings', () {
      expect(AlignmentTracker().update(heading: 359, bearing: 1), isTrue);
      expect(AlignmentTracker().update(heading: 2, bearing: 358), false);
      expect(
        AlignmentTracker().update(heading: 720 + 135, bearing: bearing),
        isTrue,
      );
    });

    test('reset forgets the alignment', () {
      final tracker = AlignmentTracker()
        ..update(heading: 136, bearing: bearing);
      tracker.reset();
      expect(tracker.aligned, isFalse);
      expect(tracker.update(heading: 140, bearing: bearing), isFalse);
    });
  });
}
