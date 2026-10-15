import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/utils/localized_format.dart';

void main() {
  const en = Locale('en');
  const ar = Locale('ar');

  test('Arabic uses Arabic-Indic digits', () {
    expect(
      LocalizedFormat.digits('15 Oct 2026, 5:28', ar),
      '١٥ Oct ٢٠٢٦, ٥:٢٨',
    );
    expect(LocalizedFormat.digits('5:28', en), '5:28');
    expect(LocalizedFormat.number(136, ar), '١٣٦');
  });

  test('countdown is HH:MM:SS, rounded up', () {
    expect(
      LocalizedFormat.countdown(
        const Duration(hours: 1, minutes: 41, seconds: 17, milliseconds: 400),
        en,
      ),
      '01:41:18',
    );
    expect(LocalizedFormat.countdown(Duration.zero, en), '00:00:00');
    expect(
      LocalizedFormat.countdown(const Duration(milliseconds: -5), en),
      '00:00:00',
    );
    expect(
      LocalizedFormat.countdown(const Duration(hours: 7, seconds: 59), ar),
      '٠٧:٠٠:٥٩',
    );
  });

  test('24-hour clock has no marker', () {
    final t = DateTime(2026, 10, 15, 17, 5);
    expect(LocalizedFormat.clock(t, en, use24Hour: true), (
      time: '17:05',
      meridiem: '',
    ));
    expect(LocalizedFormat.clock(t, ar, use24Hour: true).time, '١٧:٠٥');
  });

  test('12-hour clock: noon is 12, midnight is 12', () {
    String time(int h) => LocalizedFormat.clock(
      DateTime(2026, 10, 15, h, 7),
      en,
      use24Hour: false,
    ).time;
    expect(time(0), '12:07');
    expect(time(5), '5:07');
    expect(time(12), '12:07');
    expect(time(19), '7:07');
  });
}
