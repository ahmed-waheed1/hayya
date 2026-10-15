import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    required this.child,
  });

  final AdhanScheduler scheduler;
  final Widget child;

  @override
  State<AdhanNotificationsSync> createState() => _AdhanNotificationsSyncState();
}

class _AdhanNotificationsSyncState extends State<AdhanNotificationsSync> {
  late final AppLifecycleListener _lifecycle;
  (Locale, bool)? _textsKey;

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
    final key = (
      Localizations.localeOf(context),
      MediaQuery.alwaysUse24HourFormatOf(context),
    );
    if (key == _textsKey) return;
    _textsKey = key;
    widget.scheduler.useTexts(
      LocalizedNotificationTexts(key.$1, use24Hour: key.$2),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
