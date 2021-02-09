import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

Future setupLocator() async {
  PreferencesManager sharedPreferencesManager = await PreferencesManager.getInstance();
  locator.registerSingleton<PreferencesManager>(sharedPreferencesManager);
}