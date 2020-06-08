import 'dart:io';

import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/security/security.dart';
import 'package:fa_bank/ui/security_screen.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:flutter/material.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class SecurityArgument {
  final Security security;

  SecurityArgument(this.security);
}

class InvestmentItem extends StatelessWidget {
  final Investment investment;

  const InvestmentItem({Key key, this.investment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double rowHeight = 50;
    var iconForwardPlatform;
    if (Platform.isIOS)
      iconForwardPlatform = Icon(Icons.arrow_forward_ios);
    else
      iconForwardPlatform = Icon(Icons.arrow_forward);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          SecurityScreen.route,
          arguments: SecurityArgument(investment.security),
        );
      },
      child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Expanded(
                flex: 5,
                child: Column(
                  children: <Widget>[
                    _widgetHeadline6(context, investment.security.name, Colors.black),
                    _widgetBodyText2(context, investment.security.securityCode),
                  ],
                )),
            Container(height: rowHeight, width: 10, child: VerticalDivider(color: Colors.grey)),
            Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    _widgetBodyText2(context, 'Pos. value'),
                    _widgetHeadline6(
                        context, investment.positionValue.toString() + ' €', Colors.black),
                  ],
                )),
            Container(height: rowHeight, width: 10, child: VerticalDivider(color: Colors.grey)),
            Expanded(
              flex: 3,
              child: Column(
                children: <Widget>[
                  _widgetBodyText2(context, 'Return'),
                  _widgetHeadline6(context, investment.changePercent.toStringAsFixed(2) + '%',
                      Utils.getColor(investment.changePercent)),
                ],
              ),
            ),
            Expanded(
                flex: 3,
                child: Column(
                  children: <Widget>[
                    _widgetBodyText2(context, 'Today'),
                    _widgetHeadline6(context, investment.changePercent.toStringAsFixed(2) + '%',
                        Utils.getColor(investment.changePercent)),
                  ],
                )),
            Expanded(
              child: iconForwardPlatform,
            )
          ])),
    );
  }

  Widget _widgetHeadline6(BuildContext context, String text, Color color) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.headline6.merge(
                TextStyle(fontSize: 17, color: color),
              ),
        ));
  }

  Widget _widgetBodyText2(BuildContext context, String text) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyText2.merge(
                TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
        ));
  }
}
