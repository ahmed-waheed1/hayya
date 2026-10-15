import 'package:equatable/equatable.dart';

import 'prayer.dart';

/// Angle conventions for Fajr and Isha.
enum CalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  moonsightingCommittee,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  turkey,
  tehran,
}

/// Asr starts when a shadow is one (Shafi'i) or two (Hanafi) times an
/// object's length.
enum AsrMadhab { shafi, hanafi }

/// How Fajr and Isha are bounded where twilight lasts most of the night
/// (or all of it) in summer.
enum HighLatitudeRule {
  /// Fajr no earlier and Isha no later than the middle of the night.
  middleOfTheNight,

  /// Fajr no earlier than the last seventh of the night, Isha no later
  /// than the first seventh.
  seventhOfTheNight,

  /// Like [seventhOfTheNight], with the fraction taken from the method's
  /// angles (angle / 60).
  twilightAngle;

  /// Above this latitude (north or south) twilight can last all night in
  /// summer, so the rule changes Fajr and Isha noticeably.
  static const relevantFromLatitude = 48.0;
}

/// The user's choices for how times are calculated.
class PrayerCalculationSettings extends Equatable {
  const PrayerCalculationSettings({
    this.method = CalculationMethod.egyptian,
    this.madhab = AsrMadhab.shafi,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
    this.adjustments = const {},
  });

  /// The range offered for [adjustments], in minutes.
  static const maxAdjustment = 30;

  final CalculationMethod method;
  final AsrMadhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Minutes added to each calculated time, on top of the method's own
  /// adjustments. Zero entries are left out, so settings compare equal
  /// however they were reached.
  final Map<Prayer, int> adjustments;

  int adjustmentFor(Prayer prayer) => adjustments[prayer] ?? 0;

  /// [minutes] clamped to ±[maxAdjustment].
  PrayerCalculationSettings withAdjustment(Prayer prayer, int minutes) {
    final clamped = minutes.clamp(-maxAdjustment, maxAdjustment);
    return copyWith(
      adjustments: {...adjustments, prayer: clamped}
        ..removeWhere((_, m) => m == 0),
    );
  }

  PrayerCalculationSettings copyWith({
    CalculationMethod? method,
    AsrMadhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? adjustments,
  }) => PrayerCalculationSettings(
    method: method ?? this.method,
    madhab: madhab ?? this.madhab,
    highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    adjustments: adjustments ?? this.adjustments,
  );

  @override
  List<Object?> get props => [method, madhab, highLatitudeRule, adjustments];
}
