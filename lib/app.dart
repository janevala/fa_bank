import 'package:fa_bank/ui/camera_screen.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/backend_screen.dart';
import 'package:fa_bank/ui/mobile_dashboard_screen.dart';
import 'package:fa_bank/ui/kyc_screen.dart';
import 'package:fa_bank/ui/landing_screen.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/ui/mobile_security_screen.dart';
import 'package:fa_bank/ui/web_dashboard_screen.dart';
import 'package:fa_bank/ui/web_security_screen.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();
  bool _alreadyLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _alreadyLoggedIn = _sharedPreferencesManager.isKeyExists(PreferencesManager.keyIsLogin)
        ? _sharedPreferencesManager.getBool(PreferencesManager.keyIsLogin)
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
            fontFamily: 'Lato',
            textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme)
        ),
        home: _alreadyLoggedIn ? LandingScreen() : LoginScreen(),
        routes: {
          LoginScreen.route: (context) => LoginScreen(),
          LandingScreen.route: (context) => LandingScreen(),
          MobileDashboardScreen.route: (context) => MobileDashboardScreen(),
          WebDashboardScreen.route: (context) => WebDashboardScreen(),
          MobileSecurityScreen.route: (context) => MobileSecurityScreen(),
          WebSecurityScreen.route: (context) => WebSecurityScreen(),
          BackendScreen.route: (context) => BackendScreen(),
          KycScreen.route: (context) => KycScreen(),
          CameraScreen.route: (context) => CameraScreen(),
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