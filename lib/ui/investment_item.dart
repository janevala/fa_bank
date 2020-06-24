import 'dart:io';

import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/ui/security_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class SecurityArgument {
  final String shortName;
  final Investment investment;
  final double cashBalance;

  SecurityArgument(this.investment, this.shortName, this.cashBalance);
}

//get rid of this and do more clever way
final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

class InvestmentItem extends StatelessWidget {
  final Investment investment;
  final String shortName;
  final double cashBalance;

  const InvestmentItem({Key key, this.investment, this.shortName, this.cashBalance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double rowHeight = 50;
    var iconForwardPlatform;
    if (Platform.isIOS)
      iconForwardPlatform = Icon(Icons.arrow_forward_ios);
    else
      iconForwardPlatform = Icon(Icons.arrow_forward);

//    var code = investment.security.currency == null ? 'EUR' : investment.security.currency.currencyCode;
    var code = 'EUR';
    var setting = Utils.getMoneySetting(code, 0);
    double positionValue = investment.positionValue;
    String strPositionValue = positionValue > 100000 ?
    FlutterMoneyFormatter(amount: positionValue, settings: setting).output.compactSymbolOnLeft :
    FlutterMoneyFormatter(amount: positionValue, settings: setting).output.symbolOnLeft;

    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            _sharedPreferencesManager.putString(SharedPreferencesManager.securityCode, investment.security.securityCode);

            Navigator.pushNamed(context, SecurityScreen.route,
              arguments: SecurityArgument(investment, shortName, cashBalance),
            );
          },
          child: Padding(
              padding: EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Expanded(
                    flex: 5,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          investment.security.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.subtitle2.merge(
                            TextStyle(fontSize: 17, color: Colors.black),
                          ),
                        ))
                ),
                Container(height: rowHeight, width: 10, child: VerticalDivider(thickness: 2, color: Colors.grey[300])),
                Expanded(
                    flex: 3,
                    child: Column(
                      children: <Widget>[
                        _widgetBodyText2(context, 'Pos. Value'),
                        _widgetHeadline6(
                            context, strPositionValue, Colors.black),
                      ],
                    )),
                Container(height: rowHeight, width: 10, child: VerticalDivider(thickness: 2,color: Colors.grey[300])),
                Expanded(
                    flex: 3,
                    child: Column(
                      children: <Widget>[
                        _widgetBodyText2(context, 'Amount'),
                        _widgetHeadline6(context, investment.amount.toStringAsFixed(0),
                            Colors.black),
                      ],
                    )),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: <Widget>[
                      _widgetBodyText2(context, 'Return'),
                      _widgetHeadline6(context, (investment.changePercent * 100).toStringAsFixed(1).replaceFirst('.', ',') + '%',
                          Utils.getColor(investment.changePercent)),
                    ],
                  ),
                ),
                Expanded(
                  child: iconForwardPlatform,
                )
              ])),
        ),
        Container(height: 8, color: Colors.grey[300]),
      ],
    );
  }

  Widget _widgetHeadline6(BuildContext context, String text, Color color) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.subtitle2.merge(
                TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
              ),
        ));
  }

  Widget _widgetBodyText2(BuildContext context, String text) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyText2.merge(
                TextStyle(color: Colors.grey[600]),
              ),
        ));
  }
}
