import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/ui/security_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class App extends StatelessWidget {
  final SharedPreferencesManager _sharedPreferencesManager =
      locator<SharedPreferencesManager>();

  @override
  Widget build(BuildContext context) {
    bool _isAlreadyLoggedIn = _sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyIsLogin)
        ? _sharedPreferencesManager.getBool(SharedPreferencesManager.keyIsLogin)
        : false;

    return MaterialApp(
      showPerformanceOverlay: false,
      theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.grey,
          primaryColor: Colors.grey[500],
          accentColor: Colors.blueGrey[500],
          fontFamily: 'Lato',
          textTheme: TextTheme(
            headline6: GoogleFonts.lato(textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.normal)),
            subtitle2: GoogleFonts.lato(textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
            bodyText2: GoogleFonts.lato(textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          )),
      home: _isAlreadyLoggedIn ? DashboardScreen() : LoginScreen(),
      routes: {
        LoginScreen.route: (context) => LoginScreen(),
        DashboardScreen.route: (context) => DashboardScreen(),
        SecurityScreen.route: (context) => SecurityScreen(),
      },
    );
  }
}
