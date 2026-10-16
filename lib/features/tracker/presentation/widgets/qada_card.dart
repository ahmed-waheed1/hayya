import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../../domain/entities/tracker_data.dart';
import '../cubit/tracker_cubit.dart';
import 'qada_sheet.dart';

/// Qada counter: what is owed per prayer, and a button that logs one
/// made-up prayer of the selected kind. The user sets the counts
/// themselves ([showQadaSheet]); nothing is added automatically.
class QadaCard extends StatefulWidget {
  const QadaCard({super.key});

  @override
  State<QadaCard> createState() => _QadaCardState();
}

class _QadaCardState extends State<QadaCard> {
  Prayer? _selected;

  /// The prayer just logged, for the confirmation and Undo.
  Prayer? _logged;

  Prayer _selectedIn(TrackerData data) =>
      _selected ??
      trackedPrayers.firstWhere(
        (p) => data.owed(p) > 0,
        orElse: () => trackedPrayers.first,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final format = context.format;
    final cubit = context.read<TrackerCubit>();
    final data = context.watch<TrackerCubit>().state;
    final total = data.totalOwed;
    final selected = _selectedIn(data);

    final mutedStyle = type
        .style(12.5, FontWeight.w600)
        .copyWith(color: c.muted);

    final header = Row(
      spacing: 12.r,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2.r,
            children: [
              Semantics(
                header: true,
                child: Text(
                  LocaleKeys.tracker_qada_title.tr(),
                  style: type
                      .style(16, FontWeight.w800)
                      .copyWith(color: c.text),
                ),
              ),
              if (total > 0)
                Text(LocaleKeys.tracker_qada_subtitle.tr(), style: mutedStyle),
            ],
          ),
        ),
        if (total > 0)
          Semantics(
            liveRegion: true,
            label: LocaleKeys.tracker_qada_total.tr(
              args: [format.grouped(total)],
            ),
            child: ExcludeSemantics(
              child: Text(
                format.grouped(total),
                style: type
                    .style(40, FontWeight.w800, tabular: true, height: 1)
                    .copyWith(color: c.text),
              ),
            ),
          ),
      ],
    );

    final editButton = HayyaButton(
      label: LocaleKeys.tracker_qada_edit.tr(),
      variant: HayyaButtonVariant.text,
      onPressed: () => showQadaSheet(context),
    );

    final List<Widget> body;
    if (total == 0) {
      body = [
        Text(
          (data.qadaMadeUp > 0
                  ? LocaleKeys.tracker_qada_all_done
                  : LocaleKeys.tracker_qada_empty)
              .tr(),
          style: type.style(14, FontWeight.w600).copyWith(color: c.muted),
        ),
        if (data.qadaMadeUp > 0)
          Center(child: editButton)
        else
          HayyaButton(
            label: LocaleKeys.tracker_qada_add.tr(),
            icon: HayyaIcons.add,
            variant: HayyaButtonVariant.soft,
            expand: true,
            onPressed: () => showQadaSheet(context),
          ),
        _PrivacyNote(style: mutedStyle),
      ];
    } else {
      body = [
        Semantics(
          label: LocaleKeys.tracker_qada_pick.tr(),
          container: true,
          child: Row(
            spacing: 6.r,
            children: [
              for (final prayer in trackedPrayers)
                Expanded(
                  child: _QadaOption(
                    prayer: prayer,
                    count: data.owed(prayer),
                    selected: prayer == selected,
                    onTap: () => setState(() {
                      _selected = prayer;
                      _logged = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        HayyaButton(
          label: LocaleKeys.tracker_qada_log.tr(args: [selected.localizedName]),
          icon: HayyaIcons.add,
          variant: HayyaButtonVariant.gold,
          expand: true,
          onPressed: data.owed(selected) == 0
              ? null
              : () {
                  cubit.logQada(selected);
                  // Stay on this prayer even when it reaches zero.
                  setState(() => _logged = _selected = selected);
                },
        ),
        if (_logged case final logged?)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    LocaleKeys.tracker_qada_logged.tr(
                      args: [logged.localizedName],
                    ),
                    textAlign: TextAlign.center,
                    style: mutedStyle.copyWith(color: c.primaryInk),
                  ),
                ),
              ),
              HayyaButton(
                label: LocaleKeys.tracker_qada_undo.tr(),
                variant: HayyaButtonVariant.text,
                onPressed: () {
                  cubit.undoQada(logged);
                  setState(() => _logged = null);
                },
              ),
            ],
          )
        else
          _PrivacyNote(style: mutedStyle),
        Center(child: editButton),
      ];
    }

    return HayyaCard(
      padding: EdgeInsetsDirectional.fromSTEB(16.r, 18.r, 16.r, 8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14.r,
        children: [header, ...body],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.style});

  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text(
    LocaleKeys.tracker_qada_private.tr(),
    textAlign: TextAlign.center,
    style: style,
  );
}

/// One prayer in the picker: what's owed over its name.
class _QadaOption extends StatelessWidget {
  const _QadaOption({
    required this.prayer,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Prayer prayer;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final format = context.format;
    final ink = selected ? c.primaryInk : c.text;
    final radius = BorderRadius.circular(HayyaRadius.md);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: LocaleKeys.tracker_qada_owed_for.tr(
        args: [prayer.localizedName, format.grouped(count)],
      ),
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primarySoft : c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? c.primaryInk : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 58.r),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: 4.r,
                vertical: 6.r,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 1.r,
                  children: [
                    Text(
                      format.grouped(count),
                      style: type
                          .style(
                            17,
                            FontWeight.w800,
                            tabular: true,
                            height: 1.2,
                          )
                          .copyWith(color: ink),
                    ),
                    Text(
                      prayer.localizedName,
                      style: type
                          .style(11, FontWeight.w700, height: 1.2)
                          .copyWith(color: ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
