import 'dart:ui';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:fa_bank/bloc/landing_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/mobile_dashboard_screen.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/ui/web_dashboard_screen.dart';
import 'package:fa_bank/utils/list_utils.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatefulWidget {
  static const String route = '/landing_screen';

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

final PreferencesManager _preferencesManager = locator<PreferencesManager>();

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  final LandingBloc _landingBloc = LandingBloc(LandingInitial());
  bool _spin = true;
  AnimationController _fadeController;
  Animation _fadeAnimation;
  List<String> _backgroundImages = [
    'assets/images/shutterstock_111899093.jpg',
    'assets/images/shutterstock_1627633462.jpg',
    'assets/images/shutterstock_403945477.jpg'
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: Duration(seconds: 4))..repeat(reverse: true);
    _fadeAnimation = Tween(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _fadeController, curve: ListUtils.getRandomCurve()));

    _doRefreshToken();
  }

  @override
  void dispose() {
    _fadeController.dispose();

    super.dispose();
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _doOnExpiry() async {
    if (_preferencesManager.isKeyExists(PreferencesManager.keyAuthMSecs))
      await _preferencesManager.clearKey(PreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    _landingBloc.add(LandingEvent());
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  _logout(BuildContext context) {
    locator<PreferencesManager>().clearSessionRelated();
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocProvider<LandingBloc>(
          create: (context) => _landingBloc,
          child: BlocBuilder<LandingBloc, LandingState>(
            builder: (context, state) {
              if (state is LandingLoading) {
                _spin = true;
              } else if (state is LandingSuccess) {
                _spin = false;
                return kIsWeb ? _webView(context) : _mobileView(context);
              } else if (state is LandingCache) {
                _spin = false;
                return Center(child: Text('LandingCache'));
              } else if (state is LandingFailure) {
                _spin = false;
                return Center(child: Text('LandingFailure'));
              }

              return Spinner();
            },
          ),
        ),
      ),
    );
  }

  Widget _mobileView(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Image.asset(Utils.randomImage(_backgroundImages),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
            child: Container(
              color: FaColor.red[900].withOpacity(0.8),
            ),
          ),
        ),
        Align(
          alignment: FractionalOffset.topCenter,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      FaColor.red[900],
                      FaColor.red[700],
                      FaColor.red[1]
                    ]
                )
            ),
            child: Padding(
                padding: EdgeInsets.only(left: 64, right: 64, top: 120, bottom: 120),
                child: Image.asset('assets/images/fa-logo.png')),
          ),
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Table(
              defaultColumnWidth: FixedColumnWidth(MediaQuery.of(context).size.width / 4),
              border: TableBorder.all(color: Colors.black26, width: 1, style: BorderStyle.none),
              children: [
                TableRow(children: [
                  TableCell(child: _getDummyCell('Performance', 1)),
                  TableCell(child: _getDummyCell('Positions', 2)),
                  TableCell(child: _getDummyCell('Allocations', 3)),
                  TableCell(child: _getDummyCell('Transactions', 4)),
                ]),
                TableRow(children: [
                  TableCell(child: _getTradingCell('Trading')),
                  TableCell(child: _getDummyCell('Deposit &  \nWithdraw', 6)),
                  TableCell(child: _getBlogCell('FA Blog')),
                  TableCell(child: _getSignOutCell('Sign Out')),
                ])
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _webView(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Center(
          child: Image.asset(Utils.randomImage(_backgroundImages),
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
            child: Container(
              color: FaColor.red[900].withOpacity(0.8),
            ),
          ),
        ),
        Align(
          alignment: FractionalOffset.topCenter,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  FaColor.red[900],
                  FaColor.red[700],
                  FaColor.red[1]
                ]
              )
            ),
            child: Container(
              width: width * 0.4,
              child: Padding(
                  padding: EdgeInsets.only(top: 120, bottom: 120),
                  child: Image.asset('assets/images/fa-logo.png')),
            ),
          ),
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Table(
              defaultColumnWidth: FixedColumnWidth(MediaQuery.of(context).size.width / 4),
              border: TableBorder.all(color: Colors.black26, width: 1, style: BorderStyle.none),
              children: [
                TableRow(children: [
                  TableCell(child: _getDummyCell('Performance', 1)),
                  TableCell(child: _getDummyCell('Positions', 2)),
                  TableCell(child: _getDummyCell('Allocations', 3)),
                  TableCell(child: _getDummyCell('Transactions', 4)),
                ]),
                TableRow(children: [
                  TableCell(child: _getTradingCell('Trading')),
                  TableCell(child: _getDummyCell('Deposit & \nWithdraw', 6)),
                  TableCell(child: _getBlogCell('FA Blog')),
                  TableCell(child: _getSignOutCell('Sign Out')),
                ])
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getIcon(int value) {
    IconData ic = CommunityMaterialIcons.speedometer;
    switch (value) {
      case 1:
        ic = CommunityMaterialIcons.speedometer;
        break;
      case 2:
        ic = CommunityMaterialIcons.briefcase;
        break;
      case 3:
        ic = CommunityMaterialIcons.chart_pie;
        break;
      case 4:
        ic = CommunityMaterialIcons.clipboard_list_outline;
        break;
      case 5:
        ic = CommunityMaterialIcons.chart_areaspline_variant;
        break;
      case 6:
        ic = CommunityMaterialIcons.cash_100;
        break;
      case 7:
        ic = CupertinoIcons.pencil_outline;
        break;
      case 8:
        ic = Icons.logout;
        break;
    }
    return Icon(ic, size: 38, color: Colors.white);
  }

  Widget _getTradingCell(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          kIsWeb ? Navigator.pushNamedAndRemoveUntil(context, WebDashboardScreen.route, (r) => false) : Navigator.pushNamedAndRemoveUntil(context, MobileDashboardScreen.route, (r) => false);
        },
        child: Column(
          children: [
            _getIcon(5),
            Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _getBlogCell(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          var url = 'https://fasolutions.com/blog/';
          if (await canLaunch(url)) {
          await launch(url);
          } else {
          _showToast(context, 'Cannot open information');
          }
        },
        child: Column(
          children: [
            _getIcon(7),
            Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _getDummyCell(String text, int iconId) {
    return Builder(
      builder: (stupidToastContext) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showToast(stupidToastContext, 'Not implemented'),
          child: Column(
            children: [
              _getIcon(iconId),
              Padding(
                padding: EdgeInsets.only(top: 4, bottom: 4),
                child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSignOutCell(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _logout(context);
        },
        child: Column(
          children: [
            _getIcon(8),
            Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text(text, style: TextStyle(fontSize: 14, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
