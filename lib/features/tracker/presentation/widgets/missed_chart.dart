import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../../domain/entities/tracker_data.dart';

/// Missed prayers per prayer as bars, the most-missed ones in gold.
/// Fajr is at the start edge, so the order flips in Arabic.
class MissedChart extends StatelessWidget {
  const MissedChart({super.key, required this.missed});

  final Map<Prayer, int> missed;

  /// Bar area height and the tallest bar in it, as in the design; the
  /// rest is room for the count above the bar.
  static const _chartHeight = 150.0;
  static const _tallestBar = 104.0;
  static const _shortestBar = 4.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final format = context.format;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final most = missed.values.fold(0, math.max);
    final prayers = rtl ? trackedPrayers.reversed.toList() : trackedPrayers;
    // The design's soft bar: heatmap level 2 in light, 3 in dark.
    final soft = c.heatmap[context.isDark ? 3 : 2];

    bool highlighted(Prayer p) => most > 0 && missed[p] == most;
    TextStyle labelStyle(bool strong) => type
        .style(12, strong ? FontWeight.w800 : FontWeight.w600, height: 1.2)
        .copyWith(color: strong ? c.goldInk : c.muted);

    // The names under the bars: the design's 26 px band, or taller for
    // large text.
    final space = 6.r;
    final labelsHeight = math.max(
      26.r,
      MediaQuery.textScalerOf(context).scale(12.sp * 1.2) + space + 2,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: _chartHeight.r + labelsHeight,
        child: BarChart(
          BarChartData(
            maxY: _chartHeight,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            barTouchData: BarTouchData(enabled: false),
            borderData: FlBorderData(
              show: true,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: labelsHeight,
                  getTitlesWidget: (value, meta) {
                    final prayer = prayers[value.toInt()];
                    final strong = highlighted(prayer);
                    return SideTitleWidget(
                      meta: meta,
                      space: space,
                      // Each name has its bar's share of the width.
                      child: SizedBox(
                        width: constraints.maxWidth / prayers.length - 4.r,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            prayer.localizedName,
                            maxLines: 1,
                            style: labelStyle(strong),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (final (i, prayer) in prayers.indexed)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: most == 0
                          ? _shortestBar
                          : math.max(
                              _shortestBar,
                              missed[prayer]! / most * _tallestBar,
                            ),
                      width: 30.r,
                      color: highlighted(prayer) ? c.gold : soft,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                        bottom: Radius.circular(3.r),
                      ),
                      label: BarChartRodLabel(
                        show: true,
                        text: format.number(missed[prayer]!),
                        offset: Offset(0, 6.r),
                        style: type
                            .style(
                              13,
                              FontWeight.w800,
                              tabular: true,
                              height: 1,
                            )
                            .copyWith(
                              color: highlighted(prayer) ? c.goldInk : c.muted,
                            ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Missed prayers, last 30 days: Fajr 6, Dhuhr 1, …" for screen readers.
  static String semanticsLabel(
    Map<Prayer, int> missed,
    String window,
    LocalizedFormat format,
  ) => LocaleKeys.tracker_missed_label.tr(
    args: [
      window,
      [
        for (final p in trackedPrayers)
          LocaleKeys.tracker_missed_item.tr(
            args: [p.localizedName, format.number(missed[p] ?? 0)],
          ),
      ].join(LocaleKeys.tracker_list_separator.tr()),
    ],
  );
}
