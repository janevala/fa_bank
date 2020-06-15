import 'dart:io';

import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/security/security.dart';
import 'package:fa_bank/ui/security_screen.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class SecurityArgument {
  final String shortName;
  final Investment investment;

  SecurityArgument(this.investment, this.shortName);
}

class InvestmentItem extends StatelessWidget {
  final Investment investment;
  final String shortName;

  const InvestmentItem({Key key, this.investment, this.shortName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double rowHeight = 50;
    var iconForwardPlatform;
    if (Platform.isIOS)
      iconForwardPlatform = Icon(Icons.arrow_forward_ios);
    else
      iconForwardPlatform = Icon(Icons.arrow_forward);

    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, SecurityScreen.route,
              arguments: SecurityArgument(investment, shortName),
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
                          style: Theme.of(context).textTheme.headline6.merge(
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
                        _widgetHeadline6Currency(
                            context, investment.positionValue.toStringAsFixed(0), Colors.black),
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
                      _widgetHeadline6(context, investment.changePercent.toStringAsFixed(2) + '%',
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
          style: Theme.of(context).textTheme.headline6.merge(
                TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
              ),
        ));
  }

  Widget _widgetHeadline6Currency(BuildContext context, String text, Color color) {
    final formatter = NumberFormat("#,###");// using comma here will not work, even by escaping with back slash
    String newString = formatter.format(int.parse(text));

    return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '€' + newString.replaceAll(',', '.'),
          style: Theme.of(context).textTheme.headline6.merge(
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
                TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
        ));
  }
}
