import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superdriver_admin/core/shared_pref.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  if (locator.isRegistered<SharedPreferencesRepository>()) return;

  final prefs = await SharedPreferences.getInstance();
  locator.registerLazySingleton<SharedPreferencesRepository>(
    () => SharedPreferencesRepository(prefs),
  );
}
