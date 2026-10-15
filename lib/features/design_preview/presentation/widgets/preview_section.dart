import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';

/// Titled block used by every preview section.
class PreviewSection extends StatelessWidget {
  const PreviewSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: HayyaSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: HayyaSpacing.s4,
        children: [
          Text(title, style: context.type.titleLarge),
          child,
        ],
      ),
    );
  }
}

/// Sample-data time formatting for the preview ("5:28" + "AM" / "ص").
({String time, String meridiem}) formatSampleTime(
  BuildContext context,
  int hour,
  int minute,
) {
  final locale = Localizations.localeOf(context).toString();
  final t = DateTime(2026, 10, 15, hour, minute);
  return (
    time: DateFormat('h:mm', locale).format(t),
    meridiem: DateFormat('a', locale).format(t),
  );
}
