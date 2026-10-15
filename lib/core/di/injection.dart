import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../preferences/app_preferences.dart';
import '../theme/theme_mode_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<AppPreferences>(AppPreferences(prefs))
    ..registerLazySingleton<ThemeModeCubit>(
      () => ThemeModeCubit(getIt<AppPreferences>()),
    );
}
