import 'package:easy_localization/easy_localization.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/localized_format.dart';
import '../../../generated/locale_keys.g.dart';
import '../../prayer_times/presentation/prayer_display.dart';
import '../domain/adhan_scheduler.dart';
import '../domain/entities/planned_notification.dart';

/// [NotificationTexts] from the loaded translations.
///
/// [_format]'s locale must be the language those translations are in; it
/// picks the digits and the clock's AM/PM marker.
class LocalizedNotificationTexts implements NotificationTexts {
  LocalizedNotificationTexts(this._format);

  final LocalizedFormat _format;

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
        final clock = _format.clock(n.prayerTime);
        return (
          title: _format.digits(
            LocaleKeys.notifications_reminder_title.plural(
              minutes,
              name: 'minutes',
              namedArgs: {'prayer': name},
            ),
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
    NotificationSound.adhanNotificationVolume => (
      name: LocaleKeys.notifications_adhan_notification_volume_channel.tr(),
      description: LocaleKeys
          .notifications_adhan_notification_volume_channel_description
          .tr(),
    ),
    NotificationSound.reminder => (
      name: LocaleKeys.notifications_reminder_channel.tr(),
      description: LocaleKeys.notifications_reminder_channel_description.tr(),
    ),
  };
}
