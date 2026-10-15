import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../generated/locale_keys.g.dart';
import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';

/// Body for a tab whose screen isn't built yet: title plus "Coming soon".
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: HayyaSpacing.s2,
          children: [
            Text(title, style: context.type.titleLarge.copyWith(color: c.text)),
            Text(
              LocaleKeys.common_coming_soon.tr(),
              style: context.type.body.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}
