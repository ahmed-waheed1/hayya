import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hayya/core/preferences/display_preferences.dart';
import 'package:hayya/core/utils/localized_format.dart';

void main() {
  const en = LocalizedFormat(Locale('en'));
  const ar = LocalizedFormat(Locale('ar'));
  const arWestern = LocalizedFormat(Locale('ar'), numerals: Numerals.western);

  test('Arabic uses Arabic-Indic digits', () {
    expect(ar.digits('15 Oct 2026, 5:28'), '١٥ Oct ٢٠٢٦, ٥:٢٨');
    expect(en.digits('5:28'), '5:28');
    expect(ar.number(136), '١٣٦');
  });

  test('Arabic-Indic digits use the Arabic decimal separator', () {
    expect(ar.digits('Fajr 19.5°, Isha 17.5°.'), 'Fajr ١٩٫٥°, Isha ١٧٫٥°.');
    // A full stop after a number is not a decimal point.
    expect(ar.digits('Isha 18.'), 'Isha ١٨.');
  });

  test('Western numerals in Arabic leave digits alone', () {
    expect(arWestern.digits('15 Oct 2026, 19.5'), '15 Oct 2026, 19.5');
    expect(arWestern.number(136), '136');
    expect(
      arWestern.countdown(const Duration(hours: 7, seconds: 59)),
      '07:00:59',
    );
  });

  test('the numerals choice never affects English', () {
    const enArabicIndic = LocalizedFormat(
      Locale('en'),
      numerals: Numerals.arabicIndic,
    );
    expect(enArabicIndic.number(136), '136');
  });

  test('signed adjustments use a real minus sign', () {
    expect(en.signed(5), '+5');
    expect(en.signed(-3), '−3');
    expect(en.signed(0), '0');
    expect(ar.signed(12), '+١٢');
  });

  test('countdown is HH:MM:SS, rounded up', () {
    expect(
      en.countdown(
        const Duration(hours: 1, minutes: 41, seconds: 17, milliseconds: 400),
      ),
      '01:41:18',
    );
    expect(en.countdown(Duration.zero), '00:00:00');
    expect(en.countdown(const Duration(milliseconds: -5)), '00:00:00');
    expect(ar.countdown(const Duration(hours: 7, seconds: 59)), '٠٧:٠٠:٥٩');
  });

  test('24-hour clock has no marker', () {
    final t = DateTime(2026, 10, 15, 17, 5);
    expect(const LocalizedFormat(Locale('en'), use24Hour: true).clock(t), (
      time: '17:05',
      meridiem: '',
    ));
    expect(
      const LocalizedFormat(Locale('ar'), use24Hour: true).clock(t).time,
      '١٧:٠٥',
    );
  });

  test('12-hour clock: noon is 12, midnight is 12', () {
    String time(int h) => en.clock(DateTime(2026, 10, 15, h, 7)).time;
    expect(time(0), '12:07');
    expect(time(5), '5:07');
    expect(time(12), '12:07');
    expect(time(19), '7:07');
  });

  test('time format: a choice overrides the device, none follows it', () {
    const unset = DisplayPreferences();
    expect(unset.use24Hour(deviceUses24Hour: true), isTrue);
    expect(unset.use24Hour(deviceUses24Hour: false), isFalse);

    const twelve = DisplayPreferences(timeFormat: TimeFormat.twelveHour);
    expect(twelve.use24Hour(deviceUses24Hour: true), isFalse);
    const twentyFour = DisplayPreferences(
      timeFormat: TimeFormat.twentyFourHour,
    );
    expect(twentyFour.use24Hour(deviceUses24Hour: false), isTrue);
  });
}
