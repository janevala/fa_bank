import 'dart:ui';

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

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(
        SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _logout(BuildContext context) {
    locator<SharedPreferencesManager>().clearSessionRelated();
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    List<TradeOrder> tradeOrders = [];
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Image.asset('assets/images/fa-bank.png',
            height: AppBar().preferredSize.height * 0.8),
        backgroundColor: FaColor.red[900],
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
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
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            color: Colors.blueGrey[300].withOpacity(0.5),
          ),
        ),
        Align(
          alignment: FractionalOffset.bottomCenter,
          child: Table(
            defaultColumnWidth: FixedColumnWidth(MediaQuery.of(context).size.width / 4),
            border: TableBorder.all(color: Colors.black26, width: 1, style: BorderStyle.none),
            children: [
              TableRow(children: [
                TableCell(child: _getTableCell()),
                TableCell(child: _getTableCell()),
                TableCell(child: _getTableCell()),
                TableCell(child: _getTableCell()),
              ])
            ],
          ),
        )
      ],
    );
  }

  Widget _getTableCell() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            Navigator.pushNamedAndRemoveUntil(
                context, DashboardScreen.route, (r) => false);
          });
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.blueGrey.withOpacity(0.9), offset: Offset(1, 1), blurRadius: 10, spreadRadius: 1),
              ],
              border: Border.all(
                color: Colors.grey[900],
              ),
              borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Container(
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart),
                        Text('Boing Boing'),
                      ]),
                )),
          ),
        ),
      ),
    );
  }

  Widget _widgetTitle(BuildContext context, PortfolioBody portfolio) {
    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          children: <Widget>[
            _widgetHeadline6(context, portfolio.portfolio.portfolioName),
            Center(
                child: Text(
              portfolio.portfolio.client.name,
              style: Theme.of(context).textTheme.subtitle2.merge(
                    TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
            ))
          ],
        ));
  }

  Widget _widgetHeadline6(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6,
    ));
  }

  Widget _widgetBodyText2(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.bodyText2.merge(
            TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
    ));
  }
}
