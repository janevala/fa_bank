import 'package:fa_bank/app.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await setupLocator();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(App());
    }).catchError((onError) => print(onError.toString()));

    var systemTheme = SystemUiOverlayStyle.light.copyWith(
//        systemNavigationBarColor: Constants.faRed[900],
        statusBarColor: Constants.faRed[900]);

    SystemChrome.setSystemUIOverlayStyle(systemTheme);

  } catch (error, stacktrace) {
    print('$error & $stacktrace');
  }
}
