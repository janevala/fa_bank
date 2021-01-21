import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/backend_screen.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:fa_bank/ui/kyc_screen.dart';
import 'package:fa_bank/ui/landing_screen.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/ui/security_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();
  bool _alreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _alreadyLoggedIn = _sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyIsLogin)
        ? _sharedPreferencesManager.getBool(SharedPreferencesManager.keyIsLogin)
        : false;
  }

  @override
  Widget build(BuildContext context) {

    //https://stackoverflow.com/questions/50115311/flutter-how-to-force-an-application-restart-in-production-mode
    return RestartWidget(
      child: MaterialApp(
        showPerformanceOverlay: false,
        theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.grey,
            primaryColor: Colors.grey[500],
            accentColor: Colors.blueGrey[500],
//adjusting fonts in the app is work in progress, bellow section should be changed
            fontFamily: 'Lato',
            textTheme: TextTheme(
              headline6: GoogleFonts.lato(textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.normal)),
              subtitle2: GoogleFonts.lato(textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
              bodyText2: GoogleFonts.lato(textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
              bodyText1: GoogleFonts.lato(textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),

/*            textTheme: GoogleFonts.latoTextTheme(
              Theme.of(context).textTheme,*/
            )
        ),
        home: _alreadyLoggedIn ? LandingScreen() : LoginScreen(),
        routes: {
          LoginScreen.route: (context) => LoginScreen(),
          LandingScreen.route: (context) => LandingScreen(),
          DashboardScreen.route: (context) => DashboardScreen(),
          SecurityScreen.route: (context) => SecurityScreen(),
          BackendScreen.route: (context) => BackendScreen(),
          KycScreen.route: (context) => KycScreen(),
        },
      ),
    );
  }
}

class RestartWidget extends StatefulWidget {
  RestartWidget({this.child});

  final Widget child;

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<RestartWidgetState>().restartApp();
  }

  @override
  RestartWidgetState createState() => RestartWidgetState();
}

class RestartWidgetState extends State<RestartWidget> {
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