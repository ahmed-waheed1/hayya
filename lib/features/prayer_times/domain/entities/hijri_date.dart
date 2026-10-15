import 'package:equatable/equatable.dart';

/// A date in the Hijri calendar. [month] is 1 (Muharram) to 12
/// (Dhu al-Hijjah).
class HijriDate extends Equatable {
  const HijriDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  @override
  List<Object?> get props => [year, month, day];
}
