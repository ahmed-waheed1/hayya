import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_spacing.dart';
import '../theme/theme_context.dart';
import 'hayya_card.dart';
import 'hayya_icon.dart';

/// Settings row: title, optional subtitle, and a trailing control.
///
/// [trailing] defaults to a chevron (mirrored in RTL). Pass a [HayyaSwitch],
/// a value label or a stepper instead when needed.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.elevation = HayyaElevation.card,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Use [HayyaElevation.flat] for tiles inside a settings group.
  final HayyaElevation elevation;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    return HayyaCard(
      elevation: elevation,
      onTap: onTap,
      padding: EdgeInsetsDirectional.fromSTEB(18.r, 6.r, 6.r, 6.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 52.r),
        child: Row(
          spacing: HayyaSpacing.s3,
          children: [
            ?leading,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2.r,
                children: [
                  Text(
                    title,
                    style: type
                        .style(15, FontWeight.w700)
                        .copyWith(color: c.text),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: type
                          .style(13, FontWeight.w500)
                          .copyWith(color: c.muted),
                    ),
                ],
              ),
            ),
            trailing ??
                SizedBox.square(
                  dimension: 44.r,
                  child: Center(
                    child: HayyaIcon(
                      HayyaIcons.chevron,
                      size: 20,
                      color: c.faint,
                      strokeWidth: 2,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
