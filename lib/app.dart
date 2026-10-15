import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/hayya_theme.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'core/utils/responsive.dart';
import 'generated/locale_keys.g.dart';

/// [HayyaApp] inside EasyLocalization, starting in [languageCode] (the
/// device locale when null).
Widget localizedApp(String? languageCode) => EasyLocalization(
  supportedLocales: const [Locale('en'), Locale('ar')],
  path: 'assets/translations',
  fallbackLocale: const Locale('en'),
  // AppPreferences persists the language (see language_switcher.dart).
  saveLocale: false,
  startLocale: languageCode == null ? null : Locale(languageCode),
  child: const HayyaApp(),
);

class HayyaApp extends StatefulWidget {
  const HayyaApp({super.key});

  @override
  State<HayyaApp> createState() => _HayyaAppState();
}

class _HayyaAppState extends State<HayyaApp> {
  final _router = createAppRouter();

  /// Frame sizes from the design export (phone 390 × 844, tablet 834 × 1194).
  static const _phoneDesign = Size(390, 844);
  static const _tabletDesign = Size(834, 1194);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ThemeModeCubit>(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final base = constraints.isTablet ? _tabletDesign : _phoneDesign;
          final landscape = constraints.maxWidth > constraints.maxHeight;
          return ScreenUtilInit(
            designSize: landscape ? base.flipped : base,
            minTextAdapt: true,
            builder: (context, _) => BlocBuilder<ThemeModeCubit, ThemeMode>(
              builder: (context, themeMode) => MaterialApp.router(
                onGenerateTitle: (_) => LocaleKeys.app_name.tr(),
                debugShowCheckedModeBanner: false,
                theme: HayyaTheme.light(context.locale),
                darkTheme: HayyaTheme.dark(context.locale),
                themeMode: themeMode,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: _router,
              ),
            ),
          );
        },
      ),
    );
  }
}
