import 'package:get_it/get_it.dart';

import '../theme/theme_mode_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<ThemeModeCubit>(ThemeModeCubit.new);
}
