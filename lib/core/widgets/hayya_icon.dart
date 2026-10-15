import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An outline icon on the design system's 24 px grid.
@immutable
class HayyaIconData {
  const HayyaIconData(this.path, {this.mirrorInRtl = false});

  /// SVG path data in a 0 0 24 24 viewBox.
  final String path;

  /// Directional glyphs (back, chevron) flip in RTL. Never set this for the
  /// compass, bearings, clocks or the Kaaba.
  final bool mirrorInRtl;
}

/// Icon set from the design system: 24 px grid, 1.8 stroke, round caps.
abstract final class HayyaIcons {
  static const home = HayyaIconData(
    'M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z',
  );
  static const qibla = HayyaIconData(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM15.5 8.5l-2 5-5 2 2-5z',
  );
  static const tracker = HayyaIconData(
    'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM4 9h16M8 2.5v3M16 2.5v3M9 15l2 2 4-4',
  );
  static const settings = HayyaIconData(
    'M4 7h9M17 7h3M4 17h3M11 17h9M15 5v4M9 15v4',
  );
  static const fajr = HayyaIconData(
    'M3 17h18M7 17a5 5 0 0 1 10 0M6 21h12M17 3.5l.7 1.6 1.6.7-1.6.7L17 8.1l-.7-1.6-1.6-.7 1.6-.7z',
  );
  static const sunrise = HayyaIconData(
    'M3 18h18M7 18a5 5 0 0 1 10 0M12 3v6M9 6l3-3 3 3M4.6 12.6l1.4 1.4M19.4 12.6 18 14',
  );
  static const dhuhr = HayyaIconData(
    'M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2.5v2M12 19.5v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2.5 12h2M19.5 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
  );
  static const asr = HayyaIconData(
    'M12 14a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2v1.5M5.6 4.6l1 1M3 10h1.5M19.5 10H21M17.4 5.6l1-1M3 18h18M7 21h10',
  );
  static const maghrib = HayyaIconData(
    'M3 18h18M7 18a5 5 0 0 1 10 0M12 9V3M9 6l3 3 3-3M4.6 12.6l1.4 1.4M19.4 12.6 18 14',
  );
  static const isha = HayyaIconData(
    'M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5zM17 3v4M15 5h4',
  );
  static const bell = HayyaIconData(
    'M6 16v-5a6 6 0 1 1 12 0v5l1.5 2h-15zM10 20.5a2 2 0 0 0 4 0',
  );
  static const bellOff = HayyaIconData(
    'M8.5 5.6A6 6 0 0 1 18 11v4M6 11v5l-1.5 2H16M10 20.5a2 2 0 0 0 4 0M3.5 3.5l17 17',
  );
  static const check = HayyaIconData('M5 12.5l4.5 4.5L19 7.5');
  static const kaaba = HayyaIconData(
    'M4 8l8-4 8 4v9l-8 4-8-4zM4 8l8 4 8-4M12 12v9M4 11.2l8 4 8-4',
  );
  static const location = HayyaIconData(
    'M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
  );
  static const pinOff = HayyaIconData(
    'M9.2 4.2A7 7 0 0 1 19 9.5c0 2-1 4.1-2.3 5.9M14.6 17.8C13.3 19.6 12 21 12 21s-7-6.2-7-11.5c0-1.2.3-2.3.8-3.3M3 3l18 18',
  );
  static const gpsOff = HayyaIconData(
    'M12 2v3M12 19v3M2 12h3M19 12h3M8 8a6 6 0 0 0 8.5 8.5M10 6.3A6 6 0 0 1 17.7 14M3 3l18 18',
  );
  static const calendar = HayyaIconData(
    'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zM4 9.5h16M8 2.5v3M16 2.5v3M8 13.5h2M14 13.5h2M8 17h2M14 17h2',
  );
  static const search = HayyaIconData(
    'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4',
  );
  static const language = HayyaIconData(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3.5 9h17M3.5 15h17M12 3c2.4 2.5 3.6 5.5 3.6 9s-1.2 6.5-3.6 9c-2.4-2.5-3.6-5.5-3.6-9S9.6 5.5 12 3z',
  );
  static const theme = HayyaIconData(
    'M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z',
  );
  static const sound = HayyaIconData(
    'M4 9.5v5h3.5L12 18V6L7.5 9.5zM15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11',
  );
  static const streak = HayyaIconData(
    'M12 21c-3.9 0-7-2.7-7-6.4 0-3.1 2.1-4.9 3.4-6.9.5 1.9 1.4 2.9 2.4 3.4C11 8.2 12 5.2 14.4 3c.4 3 4.6 5.6 4.6 11.4C19 18.2 15.9 21 12 21z',
  );
  static const calibrate = HayyaIconData(
    'M12 12c-2-2.6-3.6-4-5.5-4a4 4 0 0 0 0 8c1.9 0 3.5-1.4 5.5-4zm0 0c2 2.6 3.6 4 5.5 4a4 4 0 0 0 0-8c-1.9 0-3.5 1.4-5.5 4z',
  );
  static const reminder = HayyaIconData(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2',
  );
  static const retry = HayyaIconData('M20 12a8 8 0 1 1-2.4-5.7M20 4v5h-5');

  /// Clockwise turn. Flip it for a left turn by the turn's direction,
  /// never by the locale.
  static const turn = HayyaIconData('M4 12a8 8 0 0 1 14-5.3M18 3v4h-4');

  /// Struck-out dial: the compass can't be read.
  static const compassOff = HayyaIconData(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 3l18 18',
  );

  /// Struck-out Qibla compass: no compass sensor.
  static const qiblaOff = HayyaIconData(
    'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM15.5 8.5l-2 5-5 2 2-5zM3 3l18 18',
  );
  static const add = HayyaIconData('M12 5v14M5 12h14');
  static const minus = HayyaIconData('M5 12h14');
  static const numerals = HayyaIconData(
    'M5 9h14M5 15h14M10 4l-2 16M16 4l-2 16',
  );
  static const back = HayyaIconData('M15 5l-7 7 7 7', mirrorInRtl: true);
  static const chevron = HayyaIconData('M9 5l7 7-7 7', mirrorInRtl: true);

  static const all = [
    home, qibla, tracker, settings, fajr, sunrise, dhuhr, asr, maghrib, isha, //
    bell, bellOff, check, kaaba, location, pinOff, gpsOff, calendar, search, //
    language, theme, sound, streak, calibrate, reminder, retry, add, minus,
    numerals, turn, compassOff, qiblaOff, back, chevron,
  ];
}

class HayyaIcon extends StatelessWidget {
  const HayyaIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.8,
  });

  final HayyaIconData icon;

  /// Design size in logical px; scaled with ScreenUtil.
  final double size;

  /// Defaults to the ambient [IconTheme] color.
  final Color? color;

  /// Stroke in viewBox units. 1.8 is the default; checks use 2.6–2.8.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color!;
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round"><path d="${icon.path}"/></svg>',
      width: size.r,
      height: size.r,
      matchTextDirection: icon.mirrorInRtl,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
