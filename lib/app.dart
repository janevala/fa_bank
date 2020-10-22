import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/backend_screen.dart';
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

    //https://stackoverflow.com/questions/50115311/flutter-how-to-force-an-application-restart-in-production-mode
    return RestartWidget(
      child: MaterialApp(
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
              bodyText1: GoogleFonts.lato(textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            )),
        home: _isAlreadyLoggedIn ? DashboardScreen() : LoginScreen(),
        routes: {
          LoginScreen.route: (context) => LoginScreen(),
          DashboardScreen.route: (context) => DashboardScreen(),
          SecurityScreen.route: (context) => SecurityScreen(),
          BackendScreen.route: (context) => BackendScreen(),
        },
      ),
    );
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>().restartApp();
  }

  @override
  _RestartWidgetState createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: widget.child,
    );
  }
}