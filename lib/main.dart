import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/app.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await setupLocator();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      runApp(App());
    }).catchError((onError) => print(onError.toString()));
  } catch (error, stacktrace) {
    print('$error & $stacktrace');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
}
