import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../generated/locale_keys.g.dart';
import '../utils/responsive.dart';
import '../widgets/widgets.dart';

/// Frame around the four top-level tabs: bottom bar on phones, rail on
/// tablets. Branch order matches the items below.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  List<HayyaNavItem> get _items => [
    HayyaNavItem(icon: HayyaIcons.home, label: LocaleKeys.nav_home.tr()),
    HayyaNavItem(icon: HayyaIcons.qibla, label: LocaleKeys.nav_qibla.tr()),
    HayyaNavItem(icon: HayyaIcons.tracker, label: LocaleKeys.nav_tracker.tr()),
    HayyaNavItem(
      icon: HayyaIcons.settings,
      label: LocaleKeys.nav_settings.tr(),
    ),
  ];

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    // Tapping the current tab again returns it to its first page.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    // Rebuild labels when the language changes.
    context.locale;
    return ResponsiveBuilder(
      phone: (context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: HayyaNavBar(
          items: _items,
          selectedIndex: navigationShell.currentIndex,
          onSelect: _onSelect,
        ),
      ),
      tablet: (context) => Scaffold(
        body: Row(
          children: [
            HayyaNavRail(
              items: _items,
              selectedIndex: navigationShell.currentIndex,
              onSelect: _onSelect,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
