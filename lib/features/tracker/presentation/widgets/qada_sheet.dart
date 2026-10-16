import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/prayer_display.dart';
import '../../domain/entities/tracker_data.dart';
import '../cubit/tracker_cubit.dart';
import 'tracker_sheet.dart';

/// Sets how many of each prayer the user owes. Saved on Save; closing
/// the sheet any other way keeps the old counts.
Future<void> showQadaSheet(BuildContext context) {
  final cubit = context.read<TrackerCubit>();
  return showTrackerSheet(
    context,
    builder: (_) => BlocProvider.value(value: cubit, child: const _QadaSheet()),
  );
}

class _QadaSheet extends StatefulWidget {
  const _QadaSheet();

  @override
  State<_QadaSheet> createState() => _QadaSheetState();
}

class _QadaSheetState extends State<_QadaSheet> {
  static const _max = 99999;

  late final Map<Prayer, int> _counts;
  final _controllers = <Prayer, TextEditingController>{};
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<TrackerCubit>().state;
    _counts = {for (final p in trackedPrayers) p: data.owed(p)};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The digits depend on the locale, which initState can't read.
    if (_started) return;
    _started = true;
    final format = context.format;
    for (final p in trackedPrayers) {
      _controllers[p] = TextEditingController(text: format.number(_counts[p]!));
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _step(Prayer prayer, int by) {
    final count = (_counts[prayer]! + by).clamp(0, _max);
    setState(() => _counts[prayer] = count);
    _controllers[prayer]!.text = context.format.number(count);
  }

  Future<void> _save() async {
    final cubit = context.read<TrackerCubit>();
    final navigator = Navigator.of(context);
    for (final p in trackedPrayers) {
      if (_counts[p] != cubit.state.owed(p)) {
        await cubit.setQadaOwed(p, _counts[p]!);
      }
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return TrackerSheetFrame(
      title: LocaleKeys.tracker_qada_sheet_title.tr(),
      subtitle: LocaleKeys.tracker_qada_sheet_hint.tr(),
      footer: HayyaButton(
        label: LocaleKeys.tracker_save.tr(),
        expand: true,
        onPressed: _save,
      ),
      children: [
        for (final prayer in trackedPrayers)
          _CountRow(
            prayer: prayer,
            controller: _controllers[prayer]!,
            count: _counts[prayer]!,
            onStep: (by) => _step(prayer, by),
            onTyped: (count) => setState(() => _counts[prayer] = count),
          ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.prayer,
    required this.controller,
    required this.count,
    required this.onStep,
    required this.onTyped,
  });

  final Prayer prayer;
  final TextEditingController controller;
  final int count;
  final ValueChanged<int> onStep;
  final ValueChanged<int> onTyped;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final name = prayer.localizedName;

    return Container(
      constraints: BoxConstraints(minHeight: 64.r),
      padding: EdgeInsetsDirectional.fromSTEB(14.r, 6.r, 6.r, 6.r),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(HayyaRadius.md),
      ),
      // With large text the − count + controls move under the name.
      child: AdaptiveRow(
        gap: HayyaSpacing.s2,
        leading: HayyaIcon(prayer.icon, size: 20, color: c.muted),
        label: Text(
          name,
          style: type.style(16, FontWeight.w700).copyWith(color: c.text),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: HayyaSpacing.s2,
          children: [
            _StepButton(
              icon: HayyaIcons.minus,
              label: LocaleKeys.tracker_qada_fewer.tr(args: [name]),
              onTap: count == 0 ? null : () => onStep(-1),
            ),
            SizedBox(
              // Room for five digits at any text size.
              width: MediaQuery.textScalerOf(context).scale(72.r),
              child: Semantics(
                label: LocaleKeys.tracker_qada_count_for.tr(args: [name]),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: type
                      .style(18, FontWeight.w800, tabular: true)
                      .copyWith(color: c.text),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      vertical: 10.r,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HayyaRadius.sm),
                      borderSide: BorderSide(color: c.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HayyaRadius.sm),
                      borderSide: BorderSide(color: c.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HayyaRadius.sm),
                      borderSide: BorderSide(color: c.primaryInk, width: 2),
                    ),
                  ),
                  onChanged: (text) => onTyped(parseDigits(text)),
                ),
              ),
            ),
            _StepButton(
              icon: HayyaIcons.add,
              label: LocaleKeys.tracker_qada_more.tr(args: [name]),
              onTap: () => onStep(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reads Western or Arabic-Indic digits; empty is zero.
int parseDigits(String text) {
  final latin = text.replaceAllMapped(
    RegExp('[٠-٩]'),
    (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x0660 + 0x30),
  );
  return int.tryParse(latin) ?? 0;
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, this.onTap});

  final HayyaIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: TapTarget(
        onTap: onTap,
        child: HayyaIcon(
          icon,
          size: 22,
          strokeWidth: 2.2,
          color: onTap == null ? c.faint : c.primaryInk,
        ),
      ),
    );
  }
}
