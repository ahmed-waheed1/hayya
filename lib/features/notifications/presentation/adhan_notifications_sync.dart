import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/localized_format.dart';

import '../domain/adhan_scheduler.dart';
import 'cubit/adhan_notifications_cubit.dart';
import 'localized_notification_texts.dart';

/// Reschedules the adhan notifications when the app opens, comes back to
/// the foreground, or changes language. Location and settings changes are
/// picked up by [AdhanScheduler] itself.
///
/// Must sit under the app's [Localizations] (e.g. in `MaterialApp.builder`)
/// and an [AdhanNotificationsCubit] provider. [Localizations] builds its
/// child only once the translations are loaded, and reports a new locale
/// only once that language has loaded, so the notification text is never
/// written from missing translations.
class AdhanNotificationsSync extends StatefulWidget {
  const AdhanNotificationsSync({
    super.key,
    required this.scheduler,
    required this.preferences,
    required this.child,
  });

  final AdhanScheduler scheduler;

  /// Where the device's 12/24-hour setting is kept for the background
  /// reschedule, which has no view to read it from.
  final AppPreferences preferences;
  final Widget child;

  @override
  State<AdhanNotificationsSync> createState() => _AdhanNotificationsSyncState();
}

class _AdhanNotificationsSyncState extends State<AdhanNotificationsSync> {
  late final AppLifecycleListener _lifecycle;
  LocalizedFormat? _textsFormat;

  @override
  void initState() {
    super.initState();
    widget.scheduler.start();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        // Days may have passed, and permissions may have changed in the
        // system settings.
        context.read<AdhanNotificationsCubit>().refreshPermissions();
        widget.scheduler.reschedule();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdhanNotificationsCubit>().start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The loaded language (not easy_localization's, which can run ahead
    // of the translations), with the user's digits and clock.
    final format = context.format;
    widget.preferences.setDeviceUses24Hour(
      MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final texts = LocalizedFormat(
      Localizations.localeOf(context),
      numerals: format.numerals,
      use24Hour: format.use24Hour,
    );
    if (texts == _textsFormat) return;
    _textsFormat = texts;
    widget.scheduler.useTexts(LocalizedNotificationTexts(texts));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
