import 'dart:ui';

import 'package:community_material_icon/community_material_icon.dart';
import 'package:fa_bank/bloc/dashboard_bloc.dart';
import 'package:fa_bank/bloc/landing_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/portfolio/trade_order.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class LandingScreen extends StatefulWidget {
  static const String route = '/landing_screen';

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

final SharedPreferencesManager _sharedPreferencesManager =
    locator<SharedPreferencesManager>();

class _LandingScreenState extends State<LandingScreen> {
  final LandingBloc _landingBloc = LandingBloc(LandingInitial());
  bool _spin = true;

  @override
  void initState() {
    super.initState();

    _doRefreshToken();
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _doOnExpiry() async {
    if (_sharedPreferencesManager
        .isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager
          .clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    _landingBloc.add(LandingEvent());
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  _logout(BuildContext context) {
    locator<SharedPreferencesManager>().clearSessionRelated();
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    List<TradeOrder> tradeOrders = [];
    return Scaffold(
      body: BlocProvider<LandingBloc>(
        create: (context) => _landingBloc,
        child: BlocBuilder<LandingBloc, LandingState>(
          builder: (context, state) {
            if (state is LandingLoading) {
              _spin = true;
            } else if (state is LandingSuccess) {
              _spin = false;
              return Center(
                child: _widgetMainView(context),
              );
            } else if (state is LandingCache) {
              _spin = false;
              return Center(
                child: Text('LandingCache',
                    style: Theme.of(context).textTheme.subtitle2),
              );
            } else if (state is LandingFailure) {
              _spin = false;
              return Center(
                child: Text('LandingFailure',
                    style: Theme.of(context).textTheme.subtitle2),
              );
            }

            return Spinner();
          },
        ),
      ),
    );
  }

  Widget _widgetMainView(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Image.asset('assets/images/login_bg.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: FaColor.red[900].withOpacity(0.8),
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
                  FaColor.red[900],
                  FaColor.red[50]
                ]
              )
            ),
            child: Padding(
                padding: EdgeInsets.only(left: 64, right: 64, top: 96, bottom: 96),
                child: Image.asset('assets/images/fa-bank-login.png')),
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
                  TableCell(child: _getDummyCell('FA Blog', 7)),
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
    IconData ic = CommunityMaterialIcons.chart_areaspline_variant;
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
    return Icon(ic, size: 50, color: Colors.white);
  }

  Widget _getTradingCell(String text) {
    return InkWell(
      onTap: () {
        Navigator.pushNamedAndRemoveUntil(context, DashboardScreen.route, (r) => false);
      },
      child: Column(
        children: [
          _getIcon(5),
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyText2.merge(
              TextStyle(
                  color: Colors.white),
            )),
          )
        ],
      ),
    );
  }

  Widget _getDummyCell(String text, int iconId) {
    return Builder(
      builder: (stupidToastContext) => InkWell(
        onTap: () => _showToast(stupidToastContext, 'Not implemented'),
        child: Column(
          children: [
            _getIcon(iconId),
            Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text(text, style: Theme.of(context).textTheme.bodyText2.merge(
                TextStyle(
                    color: Colors.white),
              )),
            )
          ],
        ),
      ),
    );
  }

  Widget _getSignOutCell(String text) {
    return InkWell(
      onTap: () {
        _logout(context);
      },
      child: Column(
        children: [
          _getIcon(8),
          Padding(
            padding: EdgeInsets.only(top: 4, bottom: 4),
            child: Text(text, style: Theme.of(context).textTheme.bodyText2.merge(
              TextStyle(
                  color: Colors.white),
            )),
          )
        ],
      ),
    );
  }
}
