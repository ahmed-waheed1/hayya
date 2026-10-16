import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/preferences/display_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/hayya_theme.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'core/utils/responsive.dart';
import 'features/notifications/domain/adhan_scheduler.dart';
import 'features/notifications/presentation/adhan_notifications_sync.dart';
import 'features/notifications/presentation/cubit/adhan_notifications_cubit.dart';
import 'features/onboarding/domain/onboarding_status.dart';
import 'features/tracker/presentation/cubit/tracker_cubit.dart';
import 'generated/locale_keys.g.dart';

/// [HayyaApp] inside EasyLocalization, starting in [languageCode] (the
/// device locale when null). Tests can pass their own [assetLoader].
Widget localizedApp(
  String? languageCode, {
  AssetLoader assetLoader = const RootBundleAssetLoader(),
}) => EasyLocalization(
  supportedLocales: const [Locale('en'), Locale('ar')],
  path: 'assets/translations',
  assetLoader: assetLoader,
  fallbackLocale: const Locale('en'),
  // AppPreferences persists the language (see language_switcher.dart).
  saveLocale: false,
  // Arabic needs its few/many forms (٣ دقائق, ١١ دقيقة); the default
  // only knows zero/one/two/other.
  ignorePluralRules: false,
  startLocale: languageCode == null ? null : Locale(languageCode),
  child: const HayyaApp(),
);

class HayyaApp extends StatefulWidget {
  const HayyaApp({super.key});

  @override
  State<HayyaApp> createState() => _HayyaAppState();
}

class _HayyaAppState extends State<HayyaApp> {
  final _router = createAppRouter(
    onboarding: getIt<OnboardingStatus>().shouldShow,
  );

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
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeModeCubit>()),
        BlocProvider.value(value: getIt<DisplayPreferencesCubit>()),
        BlocProvider.value(value: getIt<AdhanNotificationsCubit>()),
        BlocProvider.value(value: getIt<TrackerCubit>()),
      ],
      child: BlocBuilder<DisplayPreferencesCubit, DisplayPreferences>(
        builder: (context, display) => DisplayPreferencesScope(
          preferences: display,
          child: LayoutBuilder(builder: _build),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, BoxConstraints constraints) {
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
          // Inside the app's Localizations, which only build their
          // child once the translations are loaded.
          builder: (context, child) => AdhanNotificationsSync(
            scheduler: getIt<AdhanScheduler>(),
            child: child!,
          ),
        ),
      ),
    );
  }
}
