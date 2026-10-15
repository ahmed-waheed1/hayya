import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/entities/tracker_data.dart';

/// Prayers prayed per day as a [weeks]-column grid, Sunday to Saturday
/// top to bottom, ending with the week of [today]. Columns run from the
/// start edge, so in Arabic the newest week is on the left.
///
/// - Known days are colored by count with the heatmap tokens (0–5).
/// - Today has a gold outline.
/// - Future days and days before tracking began have a dashed outline.
class PrayerHeatmap extends StatelessWidget {
  const PrayerHeatmap({
    super.key,
    required this.data,
    required this.today,
    required this.weeks,
    required this.onDayTap,
  });

  final TrackerData data;
  final DateTime today;
  final int weeks;

  /// A day up to [today] was tapped.
  final ValueChanged<DateTime> onDayTap;

  /// The cell grid, without the labels.
  static const gridKey = Key('prayer_heatmap_grid');

  static double get _cell => 15.r;
  static double get _gap => 3.r;
  static double get _pitch => _cell + _gap;
  static double get _labelsWidth => 26.r;
  static double get _labelsGap => 6.r;

  /// How many week columns fit in [width].
  static int weeksFor(double width) =>
      ((width - _labelsWidth - _labelsGap + _gap) / _pitch).floor().clamp(
        1,
        53,
      );

  /// The Sunday that starts the first column.
  static DateTime firstDay(DateTime today, int weeks) =>
      today.dateOnly.addDays(-(today.weekday % 7) - 7 * (weeks - 1));

  /// Prayers prayed on [day] (0–5), or null when it has no data: in the
  /// future, or before tracking began with nothing recorded.
  int? levelOf(DateTime day) {
    final d = day.dateOnly;
    if (d.isAfter(today.dateOnly) || !data.isKnown(d)) return null;
    return data.prayedOn(d).length;
  }

  /// Where [day]'s cell sits inside the grid ([gridKey]).
  Rect cellRect(DateTime day, TextDirection direction) {
    final index = firstDay(today, weeks).daysUntil(day.dateOnly);
    final week = index ~/ 7;
    final column = direction == TextDirection.rtl ? weeks - 1 - week : week;
    return Rect.fromLTWH(
      column * _pitch + _gap / 2,
      (index % 7) * _pitch + _gap / 2,
      _cell,
      _cell,
    );
  }

  /// The day under [position] in the grid (a tap on a gap counts for the
  /// cell before it), or null outside the grid.
  DateTime? _dayAt(Offset position, TextDirection direction) {
    final column = (position.dx / _pitch).floor();
    final row = (position.dy / _pitch).floor();
    if (column < 0 || column >= weeks || row < 0 || row >= 7) return null;
    final week = direction == TextDirection.rtl ? weeks - 1 - column : column;
    return firstDay(today, weeks).addDays(week * 7 + row);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final direction = Directionality.of(context);
    final start = firstDay(today, weeks);
    final labelStyle = context.type
        .style(10.5, FontWeight.w700, height: 1)
        .copyWith(color: c.muted);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: _labelsGap,
      children: [
        SizedBox(
          width: _labelsWidth,
          height: 7 * _pitch,
          child: _WeekdayLabels(pitch: _pitch, style: labelStyle),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4.r,
          children: [
            SizedBox(
              width: weeks * _pitch,
              height: 12.r,
              child: _MonthLabels(
                start: start,
                weeks: weeks,
                pitch: _pitch,
                style: labelStyle,
              ),
            ),
            GestureDetector(
              key: gridKey,
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final day = _dayAt(details.localPosition, direction);
                if (day != null && !day.isAfter(today.dateOnly)) {
                  onDayTap(day);
                }
              },
              child: CustomPaint(
                size: Size(weeks * _pitch, 7 * _pitch),
                painter: _GridPainter(
                  heatmap: this,
                  direction: direction,
                  levels: c.heatmap,
                  todayColor: c.gold,
                  dashColor: c.line,
                  radius: 4.r,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({required this.pitch, required this.style});

  final double pitch;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // Rows run Sunday (0) to Saturday (6); every other row is labelled.
    final labels = {
      1: LocaleKeys.tracker_weekday_mon.tr(),
      3: LocaleKeys.tracker_weekday_wed.tr(),
      5: LocaleKeys.tracker_weekday_fri.tr(),
    };
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final MapEntry(key: row, value: label) in labels.entries)
          PositionedDirectional(
            top: row * pitch,
            start: 0,
            end: 0,
            height: pitch,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: style,
              ),
            ),
          ),
      ],
    );
  }
}

/// A month name over the first week that starts in that month. A name
/// would run off the end of the last column, so none goes there.
class _MonthLabels extends StatelessWidget {
  const _MonthLabels({
    required this.start,
    required this.weeks,
    required this.pitch,
    required this.style,
  });

  final DateTime start;
  final int weeks;
  final double pitch;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.MMM(context.locale.toLanguageTag());
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var week = 0; week < weeks - 1; week++)
          if (start.addDays(7 * week) case final sunday when sunday.day <= 7)
            PositionedDirectional(
              start: week * pitch,
              top: 0,
              child: Text(
                format.format(sunday),
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.heatmap,
    required this.direction,
    required this.levels,
    required this.todayColor,
    required this.dashColor,
    required this.radius,
  });

  final PrayerHeatmap heatmap;
  final TextDirection direction;
  final List<Color> levels;
  final Color todayColor;
  final Color dashColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final corner = Radius.circular(radius);
    final fill = Paint();
    final dash = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final todayPaint = Paint()
      ..color = todayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final start = PrayerHeatmap.firstDay(heatmap.today, heatmap.weeks);
    final today = heatmap.today.dateOnly;

    for (var i = 0; i < heatmap.weeks * 7; i++) {
      final day = start.addDays(i);
      final rect = heatmap.cellRect(day, direction);
      final level = heatmap.levelOf(day);
      if (level != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, corner),
          fill..color = levels[level.clamp(0, levels.length - 1)],
        );
      }
      if (day == today) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), corner),
          todayPaint,
        );
      } else if (level == null) {
        _drawDashed(
          canvas,
          RRect.fromRectAndRadius(rect.deflate(0.5), corner),
          dash,
        );
      }
    }
  }

  void _drawDashed(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    const on = 2.0;
    const off = 2.0;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += on + off) {
        canvas.drawPath(metric.extractPath(d, d + on), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.heatmap.data != heatmap.data ||
      old.heatmap.today != heatmap.today ||
      old.heatmap.weeks != heatmap.weeks ||
      old.direction != direction ||
      old.levels != levels ||
      old.todayColor != todayColor ||
      old.dashColor != dashColor ||
      old.radius != radius;
}
