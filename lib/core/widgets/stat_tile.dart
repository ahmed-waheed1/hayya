import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';
import 'hayya_card.dart';
import 'hayya_icon.dart';

enum StatTone { primary, gold }

/// Tracker stat: tinted icon, label, big value with a unit.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.tone = StatTone.primary,
    this.progress,
  });

  final HayyaIconData icon;
  final String label;
  final String value;
  final String? unit;
  final StatTone tone;

  /// 0–1: adds a progress bar under the value.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final (Color bg, Color fg) = switch (tone) {
      StatTone.primary => (c.primarySoft, c.primaryInk),
      StatTone.gold => (c.goldSoft, c.goldInk),
    };

    return HayyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 10.r,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: HayyaIcon(icon, size: 22, color: fg),
          ),
          Text(
            label,
            style: type.style(13, FontWeight.w600).copyWith(color: c.muted),
          ),
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: type
                        .style(15, FontWeight.w600)
                        .copyWith(color: c.muted),
                  ),
              ],
            ),
            style: type
                .style(30, FontWeight.w800, tabular: true, height: 1.1)
                .copyWith(color: c.text),
          ),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(HayyaRadius.full),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 6.r,
                color: tone == StatTone.gold ? c.gold : c.primary,
                backgroundColor: c.surface2,
              ),
            ),
        ],
      ),
    );
  }
}
