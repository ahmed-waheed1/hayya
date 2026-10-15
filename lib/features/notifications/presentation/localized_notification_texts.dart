import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/localized_format.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../domain/adhan_scheduler.dart';
import '../domain/entities/planned_notification.dart';

/// [NotificationTexts] from the loaded translations.
///
/// The locale must be the language those translations are in; it picks the
/// digits and the clock's AM/PM marker.
class LocalizedNotificationTexts implements NotificationTexts {
  LocalizedNotificationTexts(this._locale, {required this._use24Hour});

  final Locale _locale;
  final bool _use24Hour;

  @override
  ({String title, String body}) forNotification(PlannedNotification n) {
    final name = n.prayer.localizedName;
    switch (n.kind) {
      case NotificationKind.adhan:
        return (
          title: LocaleKeys.notifications_adhan_title.tr(args: [name]),
          body: LocaleKeys.notifications_adhan_body.tr(),
        );
      case NotificationKind.reminder:
        final minutes = n.prayerTime.difference(n.at).inMinutes;
        final clock = LocalizedFormat.clock(
          n.prayerTime,
          _locale,
          use24Hour: _use24Hour,
        );
        return (
          title: LocalizedFormat.digits(
            LocaleKeys.notifications_reminder_title.plural(
              minutes,
              name: 'minutes',
              namedArgs: {'prayer': name},
            ),
            _locale,
          ),
          body: LocaleKeys.notifications_reminder_body.tr(
            args: [
              [clock.time, clock.meridiem].where((s) => s.isNotEmpty).join(' '),
            ],
          ),
        );
    }
  }

  @override
  ChannelLabel channel(NotificationSound sound) => switch (sound) {
    NotificationSound.adhan => (
      name: LocaleKeys.notifications_adhan_channel.tr(),
      description: LocaleKeys.notifications_adhan_channel_description.tr(),
    ),
    NotificationSound.reminder => (
      name: LocaleKeys.notifications_reminder_channel.tr(),
      description: LocaleKeys.notifications_reminder_channel_description.tr(),
    ),
  };
}
