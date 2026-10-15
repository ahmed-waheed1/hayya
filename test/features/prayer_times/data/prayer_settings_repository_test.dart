import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/features/prayer_times/data/prayer_settings_repository_impl.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer.dart';
import 'package:hayya/features/prayer_times/domain/entities/prayer_calculation_settings.dart';
import 'package:hayya/features/prayer_times/domain/usecases/suggest_calculation_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<PrayerSettingsRepositoryImpl> repositoryWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    return PrayerSettingsRepositoryImpl(await SharedPreferences.getInstance());
  }

  Future<PrayerSettingsRepositoryImpl> reload() async =>
      PrayerSettingsRepositoryImpl(await SharedPreferences.getInstance());

  group('PrayerSettingsRepository', () {
    test('defaults: Egyptian, Shafi\'i, middle of the night, no '
        'adjustments', () async {
      final repository = await repositoryWith({});
      expect(repository.settings, const PrayerCalculationSettings());
      expect(
        repository.settings.highLatitudeRule,
        HighLatitudeRule.middleOfTheNight,
      );
      for (final prayer in Prayer.values) {
        expect(repository.settings.adjustmentFor(prayer), 0);
      }
    });

    test('every setting survives a reload', () async {
      final repository = await repositoryWith({});
      final settings = const PrayerCalculationSettings(
        method: CalculationMethod.ummAlQura,
        madhab: AsrMadhab.hanafi,
        highLatitudeRule: HighLatitudeRule.seventhOfTheNight,
      ).withAdjustment(Prayer.fajr, -4).withAdjustment(Prayer.isha, 30);
      await repository.save(settings);

      final reloaded = await reload();
      expect(reloaded.settings, settings);
      expect(reloaded.settings.adjustmentFor(Prayer.fajr), -4);
      expect(reloaded.settings.adjustmentFor(Prayer.isha), 30);
      expect(reloaded.settings.adjustmentFor(Prayer.dhuhr), 0);
    });

    test('an adjustment set back to zero is removed from storage', () async {
      final repository = await repositoryWith({});
      await repository.save(
        const PrayerCalculationSettings().withAdjustment(Prayer.asr, 3),
      );
      await repository.save(const PrayerCalculationSettings());

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('adjustment_asr'), isFalse);
      expect((await reload()).settings, const PrayerCalculationSettings());
    });

    test('unknown or out-of-range stored values fall back safely', () async {
      final repository = await repositoryWith({
        'calculation_method': 'jafari',
        'asr_madhab': 'maliki',
        'high_latitude_rule': 'polar_night',
        'adjustment_fajr': 45,
        'adjustment_isha': -12,
      });
      final settings = repository.settings;
      expect(settings.method, CalculationMethod.egyptian);
      expect(settings.madhab, AsrMadhab.shafi);
      expect(settings.highLatitudeRule, HighLatitudeRule.middleOfTheNight);
      expect(settings.adjustmentFor(Prayer.fajr), 0);
      expect(settings.adjustmentFor(Prayer.isha), -12);
    });

    test('save announces the new settings', () async {
      final repository = await repositoryWith({});
      final next = const PrayerCalculationSettings().withAdjustment(
        Prayer.maghrib,
        2,
      );
      final announced = repository.changes.first;
      await repository.save(next);
      expect(await announced, next);
    });
  });

  group('suggested method', () {
    test('follows the country', () {
      expect(suggestCalculationMethod('EG'), CalculationMethod.egyptian);
      expect(suggestCalculationMethod('sa'), CalculationMethod.ummAlQura);
      expect(suggestCalculationMethod('AE'), CalculationMethod.dubai);
      expect(suggestCalculationMethod('PK'), CalculationMethod.karachi);
      expect(suggestCalculationMethod('MY'), CalculationMethod.singapore);
      expect(suggestCalculationMethod('TR'), CalculationMethod.turkey);
      expect(suggestCalculationMethod('IR'), CalculationMethod.tehran);
      expect(suggestCalculationMethod('US'), CalculationMethod.northAmerica);
      expect(
        suggestCalculationMethod('GB'),
        CalculationMethod.moonsightingCommittee,
      );
    });

    test('other countries get the Muslim World League', () {
      expect(
        suggestCalculationMethod('DE'),
        CalculationMethod.muslimWorldLeague,
      );
    });

    test('no country, no suggestion', () {
      expect(suggestCalculationMethod(null), isNull);
      expect(suggestCalculationMethod(' '), isNull);
    });
  });
}
