import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/hayya_radius.dart';
import '../../../../core/theme/hayya_spacing.dart';
import '../../../../core/theme/theme_context.dart';

/// A bottom sheet in the app's style (like the calculation method sheet),
/// as wide as a phone column on tablets.
Future<void> showTrackerSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(HayyaRadius.xxl),
      ),
    ),
    builder: builder,
  );
}

/// Handle, [title] and [subtitle] (with an optional [trailing] beside
/// them), scrolling [children], and a [footer] kept above the keyboard.
class TrackerSheetFrame extends StatelessWidget {
  const TrackerSheetFrame({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.children,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: EdgeInsetsDirectional.only(top: 10.r),
                width: 40.r,
                height: 4.r,
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(HayyaRadius.full),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.r, 14.r, 12.r, 10.r),
              child: Row(
                spacing: HayyaSpacing.s2,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2.r,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: type
                                .style(20, FontWeight.w800)
                                .copyWith(color: c.text),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: type
                              .style(13, FontWeight.w600)
                              .copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 16.r),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6.r,
                    children: children,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16.r,
                HayyaSpacing.s3,
                16.r,
                HayyaSpacing.s4,
              ),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}
