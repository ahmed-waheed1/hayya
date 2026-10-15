import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../../domain/entities/timetable_month.dart';
import '../timetable_display.dart';

/// The month as a table: a fixed header row, then one scrolling row per
/// day with the Gregorian day and weekday, the Hijri day and the six
/// times. Today's row is filled with the primary color and starts
/// scrolled to the middle of the view.
///
/// Times drop the AM/PM marker when the columns are too narrow for it
/// (phones); the columns themselves say which half of the day it is.
///
/// Give it a key per month so a new month starts from its own scroll
/// position.
class TimetableTable extends StatefulWidget {
  const TimetableTable({
    super.key,
    required this.timetable,
    required this.today,
    this.tablet = false,
  });

  final TimetableMonth timetable;
  final DateTime today;
  final bool tablet;

  @override
  State<TimetableTable> createState() => _TimetableTableState();
}

class _TimetableTableState extends State<TimetableTable> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Created on the first layout, once the viewport height is known, so
  /// today's row is in view from the first frame.
  ScrollController _controllerFor(double viewport, double rowHeight) =>
      _controller ??= ScrollController(
        initialScrollOffset: _todayOffset(viewport, rowHeight),
      );

  /// Centers today's row, clamped to the list's scroll range.
  double _todayOffset(double viewport, double rowHeight) {
    final index = widget.timetable.indexOf(widget.today);
    if (index == null) return 0;
    final max = math.max(
      0.0,
      widget.timetable.days.length * rowHeight - viewport,
    );
    return (index * rowHeight - (viewport - rowHeight) / 2).clamp(0.0, max);
  }

  @override
  Widget build(BuildContext context) {
    final m = _Metrics(context, tablet: widget.tablet);
    final format = context.format;
    final days = widget.timetable.days;

    return HayyaCard(
      padding: EdgeInsets.zero,
      radius: HayyaRadius.xl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final timeWidth =
              (constraints.maxWidth - m.dayWidth - m.hijriWidth) /
              Prayer.values.length;
          final showMeridiem =
              !format.use24Hour && timeWidth >= m.widthWithMeridiem(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(metrics: m),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, list) => ListView.builder(
                    controller: _controllerFor(list.maxHeight, m.rowHeight),
                    itemExtent: m.rowHeight,
                    itemCount: days.length,
                    itemBuilder: (context, i) => TimetableRow(
                      day: days[i],
                      today: widget.today,
                      tablet: widget.tablet,
                      showMeridiem: showMeridiem,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Sizes from the design (phone) and their tablet counterparts, with the
/// row heights following the text scale.
class _Metrics {
  _Metrics(BuildContext context, {required this.tablet}) {
    final scale = (MediaQuery.textScalerOf(context).scale(100) / 100).clamp(
      1.0,
      2.0,
    );
    headerHeight = (tablet ? 44 : 36).r * scale;
    rowHeight = (tablet ? 44 : 31).r * scale;
  }

  final bool tablet;
  late final double headerHeight;
  late final double rowHeight;

  double get dayWidth => (tablet ? 84 : 54).r;
  double get hijriWidth => (tablet ? 60 : 34).r;
  double get timeSize => tablet ? 16 : 13;
  double get smallSize => tablet ? 12 : 10.5;
  double get headerSize => tablet ? 13 : 11;
  double get todayInset => (tablet ? 6 : 4).r;
  double get todayRadius => (tablet ? 12 : 10).r;

  /// Width a time needs with its AM/PM marker ("12:59 PM"), plus a little
  /// air on each side.
  double widthWithMeridiem(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: context.format.digits('12:59'),
            style: context.type.style(timeSize, FontWeight.w800, tabular: true),
          ),
          TextSpan(
            text: ' ${LocaleKeys.dates_pm.tr()}',
            style: context.type.style(smallSize, FontWeight.w700),
          ),
        ],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + 12.r;
    painter.dispose();
    return width;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.metrics});

  final _Metrics metrics;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.type
        .style(metrics.headerSize, FontWeight.w800)
        .copyWith(color: c.muted);

    Widget label(String text) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, style: style, maxLines: 1),
    );

    // Each row reads out its own labels.
    return ExcludeSemantics(
      child: ColoredBox(
        color: c.surface2,
        child: SizedBox(
          height: metrics.headerHeight,
          child: Row(
            children: [
              SizedBox(
                width: metrics.dayWidth,
                child: label(LocaleKeys.timetable_day.tr()),
              ),
              SizedBox(
                width: metrics.hijriWidth,
                child: label(LocaleKeys.timetable_hijri.tr()),
              ),
              for (final prayer in Prayer.values)
                Expanded(child: label(prayer.localizedName)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One day. Past days are muted, Fridays have a gold weekday and the
/// first of a Hijri month is marked in the primary color.
class TimetableRow extends StatelessWidget {
  const TimetableRow({
    super.key,
    required this.day,
    required this.today,
    required this.tablet,
    required this.showMeridiem,
  });

  final TimetableDay day;
  final DateTime today;
  final bool tablet;
  final bool showMeridiem;

  bool get isToday => day.date == today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final format = context.format;
    final m = _Metrics(context, tablet: tablet);
    final past = day.date.isBefore(today);
    final newHijriMonth = day.hijri.day == 1;

    final ink = isToday ? c.onPrimary : (past ? c.muted : c.text);
    final weekdayInk = isToday
        ? c.onPrimary
        : day.date.weekday == DateTime.friday
        ? c.goldInk
        : c.muted;
    final hijriInk = isToday
        ? c.onPrimary
        : newHijriMonth
        ? c.primaryInk
        : c.faint;
    final timeStyle = type
        .style(
          m.timeSize,
          isToday ? FontWeight.w800 : FontWeight.w500,
          tabular: true,
        )
        .copyWith(color: ink);
    final meridiemStyle = type
        .style(m.smallSize, FontWeight.w700)
        .copyWith(color: isToday ? c.onPrimary : c.muted);

    Widget cell(Widget child) => FittedBox(fit: BoxFit.scaleDown, child: child);

    final dayCell = cell(
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: 4.r,
        children: [
          Text(
            format.number(day.date.day),
            style: type
                .style(m.timeSize, FontWeight.w800, tabular: true)
                .copyWith(color: ink),
          ),
          Text(
            day.weekdayShort,
            style: type
                .style(m.smallSize, FontWeight.w700)
                .copyWith(color: weekdayInk),
          ),
        ],
      ),
    );

    final hijriCell = cell(
      Text(
        format.number(day.hijri.day),
        style: type
            .style(
              m.smallSize + 1,
              newHijriMonth || isToday ? FontWeight.w800 : FontWeight.w600,
              tabular: true,
            )
            .copyWith(color: hijriInk),
      ),
    );

    Widget timeCell(DateTime time) {
      final clock = format.clock(time);
      return cell(
        Text.rich(
          TextSpan(
            text: clock.time,
            children: [
              if (showMeridiem && clock.meridiem.isNotEmpty)
                TextSpan(text: ' ${clock.meridiem}', style: meridiemStyle),
            ],
          ),
          style: timeStyle,
          maxLines: 1,
        ),
      );
    }

    final content = Row(
      children: [
        SizedBox(width: m.dayWidth, child: dayCell),
        SizedBox(width: m.hijriWidth, child: hijriCell),
        for (final entry in day.times.times)
          Expanded(child: timeCell(entry.time)),
      ],
    );

    return Semantics(
      label: _semanticLabel(format),
      selected: isToday,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: isToday
            ? Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: m.todayInset,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(m.todayRadius),
                  ),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }

  /// "Thursday, 15 October 2026, 4 Jumada al-Ula 1448 AH, Fajr 5:20 AM,
  /// …", with "Today" first on today's row.
  String _semanticLabel(LocalizedFormat format) {
    final date =
        (isToday
                ? LocaleKeys.timetable_row_label_today
                : LocaleKeys.timetable_row_label)
            .tr(
              args: [format.gregorianDate(day.date), day.hijri.format(format)],
            );
    final separator = LocaleKeys.timetable_list_separator.tr();
    String time(DateTime at) {
      final clock = format.clock(at);
      return '${clock.time} ${clock.meridiem}'.trim();
    }

    return [
      date,
      for (final entry in day.times.times)
        LocaleKeys.timetable_time_label.tr(
          args: [entry.prayer.localizedName, time(entry.time)],
        ),
    ].join(separator);
  }
}
