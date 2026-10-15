import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/localized_format.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/adhan_preferences.dart';
import '../cubit/adhan_notifications_cubit.dart';
import '../cubit/adhan_notifications_state.dart';

/// Settings → Notifications: a warning when the system blocks the adhan,
/// then the pre-adhan reminder switch and lead time.
///
/// The design's "Adhan sound" list isn't built yet; it needs the audio
/// files and in-app preview.
class NotificationSettingsGroup extends StatelessWidget {
  const NotificationSettingsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BlocBuilder<AdhanNotificationsCubit, AdhanNotificationsState>(
      builder: (context, state) {
        final cubit = context.read<AdhanNotificationsCubit>();
        // Not in the design: without these the adhan silently never plays
        // (or plays late), so the user needs a way to fix it.
        final warning = !state.notificationsAllowed
            ? _PermissionWarning(
                title: LocaleKeys.settings_notifications_off_title.tr(),
                body: LocaleKeys.settings_notifications_off_body.tr(),
                action: LocaleKeys.settings_turn_on.tr(),
                onAction: cubit.allowNotifications,
              )
            : !state.exactAlarmsAllowed
            ? _PermissionWarning(
                title: LocaleKeys.settings_exact_alarms_title.tr(),
                body: LocaleKeys.settings_exact_alarms_body.tr(),
                action: LocaleKeys.settings_allow.tr(),
                onAction: cubit.allowExactAlarms,
              )
            : null;
        return HayyaCard(
          padding: EdgeInsetsDirectional.fromSTEB(14.r, 6.r, 8.r, 6.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (warning != null) ...[warning, Divider(color: c.line)],
              _ReminderSetting(preferences: state.preferences),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: HayyaSpacing.s3),
      child: Row(
        spacing: 10.r,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.r,
              children: [
                Text(
                  title,
                  style: type
                      .style(15, FontWeight.w700)
                      .copyWith(color: c.text),
                ),
                Text(
                  body,
                  style: type
                      .style(12.5, FontWeight.w600)
                      .copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          HayyaButton(
            label: action,
            onPressed: onAction,
            variant: HayyaButtonVariant.soft,
          ),
        ],
      ),
    );
  }
}

class _ReminderSetting extends StatelessWidget {
  const _ReminderSetting({required this.preferences});

  final AdhanPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final cubit = context.read<AdhanNotificationsCubit>();
    final title = LocaleKeys.settings_pre_adhan_reminder.tr();
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 14.r, 6.r, 12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s3,
        children: [
          Row(
            spacing: 10.r,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2.r,
                  children: [
                    Text(
                      title,
                      style: type
                          .style(15, FontWeight.w700)
                          .copyWith(color: c.text),
                    ),
                    Text(
                      LocaleKeys.settings_pre_adhan_reminder_sub.tr(),
                      style: type
                          .style(12.5, FontWeight.w600)
                          .copyWith(color: c.muted),
                    ),
                  ],
                ),
              ),
              HayyaSwitch(
                value: preferences.reminderOn,
                onChanged: cubit.setReminderOn,
                semanticLabel: title,
              ),
            ],
          ),
          // The design only shows the "on" state; the lead time is hidden
          // while the reminder is off.
          if (preferences.reminderOn)
            Semantics(
              label: title,
              child: Row(
                spacing: HayyaSpacing.s2,
                children: [
                  for (final minutes in AdhanPreferences.reminderOptions)
                    Expanded(
                      child: _MinutesChip(
                        minutes: minutes,
                        selected: minutes == preferences.reminderMinutes,
                        onTap: () => cubit.setReminderMinutes(minutes),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MinutesChip extends StatelessWidget {
  const _MinutesChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(12.r);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? c.primarySoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: c.primaryInk, width: 2)
              : BorderSide(color: c.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 44.r,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  LocaleKeys.settings_reminder_minutes.tr(
                    args: [LocalizedFormat.number(minutes, context.locale)],
                  ),
                  style: context.type
                      .style(14, FontWeight.w800)
                      .copyWith(color: selected ? c.primaryInk : c.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
