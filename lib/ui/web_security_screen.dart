import 'dart:io';

import 'package:fa_bank/bloc/security_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/mutation/mutation_data.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/security/graph.dart';
import 'package:fa_bank/podo/security/security.dart';
import 'package:fa_bank/podo/security/security_body.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/web_investment_item.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/result_container.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

/// "Security" as in financial nomenclature, not data or information security.
///
/// "Security" is a fungible, negotiable financial instrument that holds some type of monetary value.

class WebSecurityScreen extends StatefulWidget {
  static const String route = '/web_security_screen';

  @override
  _WebSecurityScreenState createState() => _WebSecurityScreenState();
}

final PreferencesManager _preferencesManager = locator<PreferencesManager>();

enum ConfirmAction { CANCEL, PROCEED }

class _WebSecurityScreenState extends State<WebSecurityScreen> {

  final SecurityBloc _securityBloc = SecurityBloc(SecurityInitial());

  final TextEditingController _controllerAmount = TextEditingController();
  String _controllerOnChanged;
  final TextEditingController _controllerDate = TextEditingController();
  bool isConfirmed = false;

  //Graph globals
  String _graphDateCriteria = 'all';
  bool _pressWeekAttention = false;
  bool _pressMonthAttention = false;
  bool _press3MonthAttention = false;
  bool _press6MonthAttention = false;
  bool _pressYTDAttention = false;
  List<DateTime> _pressRangeAttention = [];
  static const String _week = '1w';
  static const String _month = '1m';
  static const String _threeMonth = '3m';
  static const String _sixMonth = '6m';
  static const String _ytd = 'YTD';

  String _transactionType = '';
  DateTime _dateRangeFirst = DateTime.now();
  DateTime _dateRangeLast = DateTime.now();
  List<Graph> _graphs = [];
  List<FlSpot> _graphSecurity = [];
  double _minY, _maxY = 0;
  double _chartTimeMSecs = 0;
  bool _spin = true;
  bool _mutationSuccess = false;
  GlobalKey<ScaffoldState> _key = GlobalKey();
  DateFormat _rssDateFormat = DateFormat('E, dd MMM yyyy HH:mm:ss zzz');
  DateFormat _wantedDateFormat = DateFormat('d MMM yyyy');
  double _paddingBetweenColumns = 12;

  @override
  void initState() {
    super.initState();

    _doRefreshToken();
  }

  _doOnExpiry() async {
    if (_preferencesManager.isKeyExists(PreferencesManager.keyAuthMSecs))
      await _preferencesManager.clearKey(PreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    _securityBloc.add(SecurityEvent(null));
  }

  String _formatDateTime(DateTime dateTime) {
    return _wantedDateFormat.format(dateTime);
  }

  String _getNowAgain() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  bool _isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  String _getParsedValue(Security security, double value) {
    var code = security.currency == null ? 'EUR' : security.currency.currencyCode;
    return _getParsedValueWithCode(code, value, 1);
  }

  String _getParsedValueWithCode(String code, double value, int decimal) {
    var setting = Utils.getMoneySetting(code, decimal);
    return value > 10000000 ?
    FlutterMoneyFormatter(amount: value, settings: setting).output.compactSymbolOnLeft :
    FlutterMoneyFormatter(amount: value, settings: setting).output.symbolOnLeft;
  }

  double _countToday(List<Graph> graphs) {
    if (graphs.length > 2) {
      var last = graphs[graphs.length - 1].price;
      var secondLast = graphs[graphs.length - 2].price;
      return last / secondLast - 1;
    } else {
      return 0;
    }
  }

  String _getTodayAsString(double today) {
    if (today == 0) return 'n/a';
    return today.toStringAsFixed(2) + '%';
  }

  Future<void> _showPurchaseDialogBottomSheet(BuildContext context, SecurityBody securityBody, String shortName, double cashBalance) async {
    double latestValue = securityBody.securities[0].marketData.latestValue;

    return await showModalBottomSheet<void>(
      context: context,
      isScrollControlled:true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      builder: (BuildContext context) {
        return Container(
          child: Padding(
              padding: EdgeInsets.only(left: 32, right: 32),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(top: 16, bottom: 16),
                          child: _widgetSubtitle(context, _transactionType == 'B' ? 'New Buy Order' : 'New Sell Order')),
                      _widgetAmount(context),
                      _widgetDate(context),
                      _widgetTextRowSubtitle(context, 'Ask:', _getParsedValueWithCode('EUR', latestValue, 1)),
                      _widgetTextRowSubtitle(context, 'Estimated Price:', _getParsedValueWithCode('EUR', _calculateEstimated(latestValue), 1)),
                      _widgetTextRowSubtitle(context, 'Estimated Balance:', _getParsedValueWithCode('EUR', _calculateBalance(cashBalance, _calculateEstimated(latestValue)), 1)),
                      _widgetConfirmation(context),
                      Container(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: 20),
                                  child: TextButton(
                                      child: Text('CANCEL', style: TextStyle(color: Colors.black, fontSize: 20)),
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).pop();
                                      },
                                      style: TextButton.styleFrom(
                                          side: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                              style: BorderStyle.solid),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))
                                      ))
                                  ),
                                ),
                            Expanded(
                              child: Padding(
                                  padding: EdgeInsets.only(left: 20),
                                  child: _widgetSendButton(context, securityBody, shortName)),
                            ),
                          ]),
                      Container(height: 16),
                    ]),
              )),
        );
      },
    ).whenComplete(() {
      print('LOG: bottom sheet closed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final SecurityArgument arg = ModalRoute.of(context).settings.arguments;
    final Investment investment = arg.investment;
    final Security security = arg.investment.security;
    final String shortName = arg.shortName;
    final double cashBalance = arg.cashBalance;

    _controllerDate.text = _getNowAgain();

    return Scaffold(
      key: _key,
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          security.name,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: FaColor.red[900],
      ),
      body: BlocProvider<SecurityBloc>(
        create: (context) => _securityBloc,
        child: BlocBuilder<SecurityBloc, SecurityState>(
          builder: (context, state) {
            if (state is SecurityLoading) {
              _spin = true;
            } else if (state is SecurityQuerySuccess) {
              _spin = false;
              return _widgetMainView(context, state.securityBody, investment, shortName, cashBalance);
            } else if (state is SecurityMutationSuccess) {
              _mutationSuccess = true;
              _spin = false;
              return _widgetMainView(context, state.securityBody, investment, shortName, cashBalance);
            } else if (state is SecurityCache) {
              return _widgetMainView(context, state.securityBody, investment, shortName, cashBalance);
            } else if (state is SecurityFailure) {
              return Center(
                child: Text(state.error, style: TextStyle(fontSize: 18)),
              );
            }

            return Spinner();
          },
        ),
      ),
    );
  }

  Widget _widgetMainView(BuildContext context, SecurityBody securityBody, Investment investment, String shortName, double cashBalance) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double heightScreen = mediaQueryData.size.height;

    _graphs = securityBody.securities[0].graph;
    _updateGraphStates();

    bool esgRisk = securityBody.securities[0].figuresAsObject != null && securityBody.securities[0].figuresAsObject.latestValues != null &&
        securityBody.securities[0].figuresAsObject.latestValues.esgObject != null && securityBody.securities[0].figuresAsObject.latestValues.riskObject != null;

    return SafeArea(
      child: Stack(
        children: <Widget>[
          Container(
            color: Colors.grey[300],
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(_paddingBetweenColumns),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _widgetSummary(context, securityBody, investment),
                              Divider(thickness: 2, color: Colors.grey[300]),
                              _widgetDetail(context, securityBody, investment),
                              Divider(thickness: 2, color: Colors.grey[300]),
                              Padding(
                                padding: EdgeInsets.only(left: 42, right: 42),
                                child: Column(children: <Widget>[
                                  _widgetInformation(
                                      context, securityBody.securities[0].url),
                                  Divider(thickness: 2, color: Colors.grey[300]),
                                  _widgetTextRowSubtitle(context, 'Position Value', _getParsedValueWithCode('EUR', investment.positionValue, 2)),
                                  _widgetTextRowSubtitle(context, 'Purchase Value', _getParsedValueWithCode('EUR', investment.purchaseValue, 2)),
                                  Padding(
                                      padding: EdgeInsets.only(top: 12, bottom: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Flexible(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text('Return', style: TextStyle(fontSize: 18)),
                                            ),
                                          ),
                                          Flexible(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                _getParsedValueWithCode('EUR', investment.positionValue - investment.purchaseValue, 2),
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getColor(investment.positionValue - investment.purchaseValue)),
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                  _widgetTextRowSubtitle(context, 'ESG Rating', esgRisk ? securityBody.securities[0].figuresAsObject.latestValues.esgObject.value.toStringAsFixed(0) : 'n/a'),
                                  _widgetTextRowSubtitle(context, 'Risk Score', esgRisk ? securityBody.securities[0].figuresAsObject.latestValues.riskObject.value.toStringAsFixed(0) : 'n/a'),
                                  _widgetTextRowSubtitle(context, 'Ticker', investment.security.securityCode),
                                ]),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ), Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: _paddingBetweenColumns, bottom: _paddingBetweenColumns, right: _paddingBetweenColumns),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _widgetDateTitle(context),
                              _graphSecurity.length > 0 ? Padding(
                                padding: EdgeInsets.only(left: 2, right: 4),
                                child: Row(
                                  children: [
                                    Container(
                                        height: 200,
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 2),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Expanded(child: Align(alignment: Alignment.topCenter, child: Text(_maxY.toString(), style: TextStyle(fontSize: 12)))),
                                              Expanded(child: Align(alignment: Alignment.center, child: Text(((_maxY+_minY) / 2).toStringAsFixed(1), style: TextStyle(fontSize: 12)))),
                                              Expanded(child: Align(alignment: Alignment.bottomCenter, child: Text(_minY.toString(), style: TextStyle(fontSize: 12))))
                                            ],
                                          ),
                                        )),
                                    Expanded(
                                      child: Container(
                                        height: 200,
                                        child: LineChart(
                                          _getLineChartData(investment),
                                          swapAnimationDuration: const Duration(milliseconds: 500),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ) : Container(),
                              Padding(
                                  padding: EdgeInsets.only(left: 2, right: 2),
                                  child: _widgetDateChooser(context)),
                              Container(
                                height: 80,
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: SizedBox.expand(
                                            child: FlatButton(
                                                child: Text('SELL', style: TextStyle(color: Colors.white, fontSize: 20)),
                                                color: FaColor.red[900],
                                                onPressed: () {
                                                  setState(() {
                                                    _controllerAmount.text = '';
                                                    _controllerOnChanged = '';
                                                    _transactionType = 'S';
                                                  });

                                                  _showPurchaseDialogBottomSheet(context, securityBody, shortName, cashBalance);
                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(5.0))),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: SizedBox.expand(
                                            child: FlatButton(
                                                child: Text('BUY', style: TextStyle(color: Colors.white, fontSize: 20)),
                                                color: Colors.green,
                                                onPressed: () {
                                                  setState(() {
                                                    _controllerAmount.text = '';
                                                    _controllerOnChanged = '';
                                                    _transactionType = 'B';
                                                  });

                                                  _showPurchaseDialogBottomSheet(context, securityBody, shortName, cashBalance);
                                                },
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(5.0))),
                                          ),
                                        ),
                                      ),
                                    ]),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Visibility(
            visible: _spin,
            child: Spinner(),
          ),
          InkWell(
            onTap: () => Navigator.pop(context, true),
            child: Visibility(
              visible: _mutationSuccess,
              child: ResultContainer(true),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _getLineChartData(Investment investment) {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 20,
          tooltipBgColor: Colors.grey[300],
        ),
        touchCallback: (LineTouchResponse touchResponse) {
          if (touchResponse.props.last.runtimeType == FlPanEnd || touchResponse.props.last.runtimeType == FlLongPressEnd) {
            setState(() {
              _chartTimeMSecs = 0;
            });
          } else if (touchResponse.lineBarSpots.length > 0) {
            setState(() {
              _chartTimeMSecs = touchResponse.lineBarSpots[0].x;
            });
          }
        },
        handleBuiltInTouches: true,
      ),
        gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 0.4,
              );
            }
        ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: false,
          getTextStyles: (value) => TextStyle(fontSize: 12),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return 'JAN';
            }
            return '';
          },
        ),
        leftTitles: SideTitles(
          showTitles: false,
          getTextStyles: (value) => TextStyle(fontSize: 12),
          getTitles: (value) {
            switch (value.toInt()) {
              case 60:
                return '60';
              case 80:
                return '80';
              case 100:
                return '100';
              case 120:
                return '120';
              case 140:
                return '140';
              case 160:
                return '160';
              case 180:
                return '180';
            }
            return '';
          },
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(
            color: Colors.black,
            width: 0.5,
          ),
          left: BorderSide(
            color: Colors.black,
            width: 0.5,
          ),
          right: BorderSide(
            color: Colors.transparent,
          ),
          top: BorderSide(
            color: Colors.transparent,
          ),
        ),
      ),
/*      minX: _minX,
      maxX: _maxX,*/
      maxY: _maxY,
      minY: _minY,
      lineBarsData: _getLineBarDataList(investment),
    );
  }

  List<LineChartBarData> _getLineBarDataList(Investment investment) {
    final LineChartBarData linePortfolioMinus100 = LineChartBarData(
      spots: _graphSecurity,
      isCurved: false,
      colors: [
        Utils.getColor(investment.changePercent * 100),
      ],
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
          show: true,
          gradientFrom: Offset(1, 0),
          gradientTo: Offset(0, 2),
          colors: [
            Utils.getColor(investment.changePercent * 100),
            Utils.getColorLight(investment.changePercent * 100)
          ]
      ),
    );
    return [
      linePortfolioMinus100,
    ];
  }

  double _calculateEstimated(double price) {
    if (_controllerOnChanged == null || _controllerOnChanged.isEmpty) return 0;
    if (!_isNumeric(_controllerOnChanged)) return 0;
    return price * double.parse(_controllerOnChanged);
  }

  double _calculateBalance(double balance, double estimated) {
    if (_controllerOnChanged == null || _controllerOnChanged.isEmpty) return balance;
    if (!_isNumeric(_controllerOnChanged)) return balance;
    return balance - estimated;
  }

  Widget _widgetSendButton(BuildContext context, SecurityBody securityBody, String shortName) {
    return TextButton(
        child: Text('SEND', style: TextStyle(color: Colors.white, fontSize: 20)),
        onPressed: () async {
          FocusScope.of(context).unfocus();

          String _amount = _controllerAmount.text.trim();
          String _date = _controllerDate.text.trim();
          if (_amount.isEmpty || _date.isEmpty || !isConfirmed) {
            print('ERRRR');
          } else {
            Navigator.of(context).pop();
            String _amount = _controllerAmount.text.trim();
            String _date = _controllerDate.text.trim();
            MutationData mutationData = MutationData(
                shortName,
                securityBody.securities[0].securityCode,
                _amount,
                securityBody.securities[0].marketData.latestValue.toString(),
                securityBody.securities[0].currency.currencyCode,
                _transactionType,
                _date);

            _securityBloc.add(SecurityEvent(mutationData));
          }
        },
        style: TextButton.styleFrom(
            backgroundColor: _transactionType == 'B' ? Colors.green : FaColor.red[900],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))
        )
    );
  }

  Widget _widgetDateChooser(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Expanded(
          flex: 3,
          child: InkWell(
              onTap: () async {
                DateTime now = DateTime.now();
                final DateTimeRange picked = await showDateRangePicker(
                  context: context,
                  lastDate: DateTime(now.year, now.month, now.day),
                  firstDate: DateTime(now.year, now.month - 1, now.day),
                );
                if (picked != null) {
                  setState(() {
                    _pressRangeAttention = [picked.start, picked.end];
                    _pressWeekAttention = false;
                    _pressMonthAttention = false;
                    _press3MonthAttention = false;
                    _press6MonthAttention = false;
                    _pressYTDAttention = false;
                  });
                }
              },
            child: Container(
                height: 26,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                      children: [
                        WidgetSpan(
                          child: Icon(Icons.date_range, size: 20),
                        ),
                        TextSpan(text: 'Date range'),
                      ],
                    ),
                  ),
                )),
          )),
      Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextButton(
                child: Text(_week,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _pressWeekAttention ? Colors.white : Colors.black)),
                onPressed: () => setState(() {
                      if (_pressWeekAttention)
                        _graphDateCriteria = 'all';
                      else
                        _graphDateCriteria = _week;
                      _pressWeekAttention = !_pressWeekAttention;
                      _pressMonthAttention = false;
                      _press3MonthAttention = false;
                      _press6MonthAttention = false;
                      _pressYTDAttention = false;
                      _pressRangeAttention = [];
                 }),
                style: _pressWeekAttention ? TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    backgroundColor: FaColor.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                ) : TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    side: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                )
            ),
          )),
      Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextButton(
                child: Text(_month,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _pressMonthAttention ? Colors.white : Colors.black)),
                onPressed: () => setState(() {
                      if (_pressMonthAttention)
                        _graphDateCriteria = 'all';
                      else
                        _graphDateCriteria = _month;
                      _pressMonthAttention = !_pressMonthAttention;
                      _pressWeekAttention = false;
                      _press3MonthAttention = false;
                      _press6MonthAttention = false;
                      _pressYTDAttention = false;
                      _pressRangeAttention = [];
                 }),
                style: _pressMonthAttention ? TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    backgroundColor: FaColor.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                ) : TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    side: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                )
            ),
          )),
      Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextButton(
                child: Text(_threeMonth,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _press3MonthAttention ? Colors.white : Colors.black)),
                onPressed: () => setState(() {
                      if (_press3MonthAttention)
                        _graphDateCriteria = 'all';
                      else
                        _graphDateCriteria = _threeMonth;
                      _press3MonthAttention = !_press3MonthAttention;
                      _pressWeekAttention = false;
                      _pressMonthAttention = false;
                      _press6MonthAttention = false;
                      _pressYTDAttention = false;
                      _pressRangeAttention = [];
                 }),
                style: _press3MonthAttention ? TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    backgroundColor: FaColor.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                ) : TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    side: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                )
            ),
          )),
      Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextButton(
                child: Text(_sixMonth,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _press6MonthAttention ? Colors.white : Colors.black)),
                onPressed: () => setState(() {
                      if (_press6MonthAttention)
                        _graphDateCriteria = 'all';
                      else
                        _graphDateCriteria = _sixMonth;
                      _press6MonthAttention = !_press6MonthAttention;
                      _pressWeekAttention = false;
                      _pressMonthAttention = false;
                      _press3MonthAttention = false;
                      _pressYTDAttention = false;
                      _pressRangeAttention = [];
                 }),
                style: _press6MonthAttention ? TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    backgroundColor: FaColor.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                ) : TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    side: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                )
            ),
          )),
      Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: TextButton(
                child: Text(_ytd,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pressYTDAttention ? Colors.white : Colors.black)),
                onPressed: () => setState(() {
                      if (_pressYTDAttention)
                        _graphDateCriteria = 'all';
                      else
                        _graphDateCriteria = _ytd;
                      _pressYTDAttention = !_pressYTDAttention;
                      _pressWeekAttention = false;
                      _pressMonthAttention = false;
                      _press3MonthAttention = false;
                      _press6MonthAttention = false;
                      _pressRangeAttention = [];
                 }),
                style: _pressYTDAttention ? TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    backgroundColor: FaColor.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                ) : TextButton.styleFrom(
                    minimumSize: Size(0, 0),
                    side: BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))
                )
            ),
          ))
    ]);
  }

/*  String _parsedNumberText(BuildContext context, String str) {
    final formatter = NumberFormat("#,###");// using comma here will not work, even by escaping with back slash
    String newString = formatter.format(int.parse(str));
    return newString.replaceAll(',', '.');
  }*/

  Widget _widgetSummary(BuildContext context, SecurityBody securityBody, Investment investment) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Total Amount'),
              _widgetBoldSubtitle(context, investment.amount.toStringAsFixed(0), Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Total Current Value'),
              Text(_getParsedValue(securityBody.securities[0], (investment.amount * securityBody.securities[0].marketData.latestValue)), style: TextStyle(fontSize: 19))
            ],
          ),
        ),
      ]),
    );
  }

  Widget _widgetDateTitle(BuildContext context) {
    DateTime dateFirst = DateTime(_dateRangeFirst.year, _dateRangeFirst.month, _dateRangeFirst.day);
    DateTime dateLast = DateTime(_dateRangeLast.year, _dateRangeLast.month, _dateRangeLast.day);
    bool visible = !(dateFirst.isAtSameMomentAs(dateLast));

    return Container(
      height: 24,
      child: Visibility(
        visible: visible,
        child: Center(
          child: Text(
              _chartTimeMSecs > 0 ? _formatDateTime(DateTime.fromMillisecondsSinceEpoch(_chartTimeMSecs.toInt())) : _formatDateTime(_dateRangeFirst) + ' - ' + _formatDateTime(_dateRangeLast),
            style: Theme.of(context).textTheme.bodyText2,
          ),
        ),
      ),
    );
  }

  Widget _widgetAmount(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Amount:',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 18),
                  controller: _controllerAmount,
                  keyboardType: !kIsWeb && Platform.isIOS ? TextInputType.numberWithOptions(signed: true) : TextInputType.number,
                  onChanged: (text) {
                    setState(() {
                      _controllerOnChanged = text;
                    });
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                    FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                  ],
                ),
              ),
            )
          ],
        ));
  }

  Widget _widgetDate(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Valid:',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 18),
                  enabled: false,
                  controller: _controllerDate,
                  keyboardType: TextInputType.datetime,
                ),
              ),
            )
          ],
        ));
  }

  Widget _widgetConfirmation(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Checkbox(
                  value: isConfirmed,
                  onChanged: (bool value) {
                    setState(() {
                      isConfirmed = value;
                    });
                  },
                );
              },
            ),
            Text(
              'Confirm new order',
              style: TextStyle(fontSize: 20),
            )
          ],
        ));
  }

  Widget _widgetDetail(BuildContext context, SecurityBody securityBody, Investment investment) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Latest Value'),
              _widgetBoldSubtitle(context, _getParsedValue(securityBody.securities[0], securityBody.securities[0].marketData.latestValue), Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Return'),
              _widgetBoldSubtitle(context, (investment.changePercent * 100).toStringAsFixed(2).replaceFirst('.', ',') + '%', Utils.getColor(investment.changePercent * 100))
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Today'),
              _widgetBoldSubtitle(context, _getTodayAsString(_countToday(securityBody.securities[0].graph)).replaceFirst('.', ','), Utils.getColor(_countToday(securityBody.securities[0].graph)))
            ],
          ),
        ),
      ]),
    );
  }

  Widget _widgetInformation(BuildContext context, String url) {
    return Padding(
        padding: EdgeInsets.only(top: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                    child: Text('Investment Details', style: TextStyle(fontSize: 22)),
                ),
                Visibility(
                  visible: (url == null || url == '') ? false : true,
                  child: InkWell(
                    onTap: () async {
                      if (url.startsWith('www')) url = 'https://' + url;
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        _showToast(context, 'Cannot open link');
                      }
                    },
                    child: Text(
                      'More Details Here',
                      style: Theme.of(context).textTheme.subtitle1.merge(TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                )
              ],
            ),

          ],
        ));
  }

  Widget _widgetTextRowSubtitle(BuildContext context, String label, String text) {
    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(text, style: TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ));
  }

  Widget _widgetBoldSubtitle(BuildContext context, String text, Color color) {
    return Center(
        child: Text(text, style: TextStyle(fontSize: 19, color: color),
    ));
  }

  Widget _widgetSubtitle(BuildContext context, String text) {
    return Center(
        child: Text(text, style: TextStyle(fontSize: 19),
    ));
  }

  Widget _widgetBodyText(BuildContext context, String text) {
    return Center(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
    ));
  }

  _updateGraphStates() {
    _graphSecurity = [];

    if (_graphs.length > 0) {
      var lastDate = _graphs[_graphs.length - 1].date;
      var firstDate = _graphs[0].date;
      var comparisonDate;
      if (_graphDateCriteria == 'all') comparisonDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
      else if (_graphDateCriteria == _week) comparisonDate = DateTime(lastDate.year, lastDate.month, lastDate.day - 7);
      else if (_graphDateCriteria == _month) comparisonDate = DateTime(lastDate.year, lastDate.month - 1, lastDate.day);
      else if (_graphDateCriteria == _threeMonth) comparisonDate = DateTime(lastDate.year, lastDate.month - 3, lastDate.day);
      else if (_graphDateCriteria == _sixMonth) comparisonDate = DateTime(lastDate.year, lastDate.month - 6, lastDate.day);
      else if (_graphDateCriteria == _ytd) comparisonDate = DateTime(lastDate.year, 1, 1);

      if (_pressRangeAttention.length == 2) {
        var first = DateTime(_pressRangeAttention[0].year, _pressRangeAttention[0].month, _pressRangeAttention[0].day);
        var second = DateTime(_pressRangeAttention[1].year, _pressRangeAttention[1].month, _pressRangeAttention[1].day);
        for (var i = 0; i < _graphs.length; i++) {
          var v = _graphs[i].date;
          if (v.isAfter(first) && v.isBefore(second)) {
            _graphSecurity.add(FlSpot(_graphs[i].date.millisecondsSinceEpoch.toDouble(), num.parse(_graphs[i].price.toStringAsFixed(1))));
          }
        }
      } else {
        for (var i = 0; i < _graphs.length; i++) {
          var v = _graphs[i].date;
          if (v.isAfter(comparisonDate)) {
            _graphSecurity.add(FlSpot(_graphs[i].date.millisecondsSinceEpoch.toDouble(), num.parse(_graphs[i].price.toStringAsFixed(1))));
          }
        }
      }

      if (_graphSecurity.length > 0) {
        var portfolioValues = List.generate(_graphSecurity.length, (i) => _graphSecurity[i].y);
        _minY = portfolioValues.reduce(min);
        _maxY = portfolioValues.reduce(max);

        _dateRangeFirst = DateTime.fromMillisecondsSinceEpoch(_graphSecurity[0].x.toInt());
        _dateRangeLast = DateTime.fromMillisecondsSinceEpoch(_graphSecurity[_graphSecurity.length -1].x.toInt());
      }
    }
  }
}
