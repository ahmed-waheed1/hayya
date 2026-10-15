import 'package:equatable/equatable.dart';

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

/// The user's choices for how times are calculated.
class PrayerCalculationSettings extends Equatable {
  const PrayerCalculationSettings({
    this.method = CalculationMethod.egyptian,
    this.madhab = AsrMadhab.shafi,
  });

  final CalculationMethod method;
  final AsrMadhab madhab;

  PrayerCalculationSettings copyWith({
    CalculationMethod? method,
    AsrMadhab? madhab,
  }) => PrayerCalculationSettings(
    method: method ?? this.method,
    madhab: madhab ?? this.madhab,
  );

  @override
  List<Object?> get props => [method, madhab];
}
