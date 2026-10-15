import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../generated/locale_keys.g.dart';
import '../theme/hayya_radius.dart';
import '../theme/theme_context.dart';
import 'hayya_icon.dart';

@immutable
class HayyaNavItem {
  const HayyaNavItem({required this.icon, required this.label});

  final HayyaIconData icon;
  final String label;
}

/// Phone bottom navigation (`HayyaNavBar` in the design system).
/// Item order follows the ambient Directionality.
class HayyaNavBar extends StatelessWidget {
  const HayyaNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<HayyaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: LocaleKeys.nav_label.tr(),
      child: Container(
        decoration: BoxDecoration(
          color: c.nav,
          border: BorderDirectional(top: BorderSide(color: c.line)),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(
          8.r,
          8.r,
          8.r,
          bottomInset > 18.r ? bottomInset : 18.r,
        ),
        child: SizedBox(
          height: 60.r,
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
                  child: _NavDestination(
                    item: item,
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                    pillSize: Size(60.r, 32.r),
                    iconSize: 22,
                    gap: 4.r,
                    labelSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet navigation rail (`HayyaNavRail` in the design system): brand mark
/// on top, destinations below. Sits on the start edge, so it mirrors in RTL.
class HayyaNavRail extends StatelessWidget {
  const HayyaNavRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<HayyaNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: LocaleKeys.nav_label.tr(),
      child: Container(
        width: 104.r,
        decoration: BoxDecoration(
          color: c.nav,
          border: BorderDirectional(end: BorderSide(color: c.line)),
        ),
        child: SafeArea(
          right: false,
          left: false,
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(top: 36.r, bottom: 28.r),
            child: Column(
              spacing: 10.r,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 26.r),
                  child: const _BrandMark(),
                ),
                for (final (i, item) in items.indexed)
                  SizedBox(
                    width: 88.r,
                    height: 68.r,
                    child: _NavDestination(
                      item: item,
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                      pillSize: Size(60.r, 34.r),
                      iconSize: 23,
                      gap: 5.r,
                      labelSize: 12.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 52.r,
        height: 52.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(HayyaRadius.lg),
        ),
        child: Text(
          LocaleKeys.brand_mark.tr(),
          textDirection: TextDirection.rtl,
          style: context.type
              .arabic(20, FontWeight.w800)
              .copyWith(color: c.onPrimary),
        ),
      ),
    );
  }
}

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.pillSize,
    required this.iconSize,
    required this.gap,
    required this.labelSize,
  });

  final HayyaNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Size pillSize;
  final double iconSize;
  final double gap;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = selected ? c.primaryInk : c.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: gap,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: pillSize.width,
              height: pillSize.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(HayyaRadius.full),
              ),
              child: HayyaIcon(
                item.icon,
                size: iconSize,
                color: ink,
                strokeWidth: 1.9,
              ),
            ),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type
                  .style(
                    labelSize,
                    selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.2,
                  )
                  .copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
