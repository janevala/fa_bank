import 'dart:io';

import 'package:fa_bank/bloc/mobile_dashboard_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/daily_value.dart';
import 'package:fa_bank/podo/portfolio/daily_values.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/portfolio/trade_order.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/mobile_investment_item.dart';
import 'package:fa_bank/ui/landing_screen.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class MobileDashboardScreen extends StatefulWidget {
  static const String route = '/mobile_dashboard_screen';

  @override
  _MobileDashboardScreenState createState() => _MobileDashboardScreenState();
}

final PreferencesManager _preferencesManager = locator<PreferencesManager>();

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  final MobileDashboardBloc _dashboardUserBloc = MobileDashboardBloc(MobileDashboardInitial());

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

  DateTime _dateRangeFirst = DateTime.now();
  DateTime _dateRangeLast = DateTime.now();
  Graph _graphRaw = Graph(DailyValues([DailyValue(DateTime.now(), 0, 0)]));
  List<FlSpot> _graphBenchmarkMinus100 = [];
  List<FlSpot> _graphPortfolioMinus100 = [];
  double _minY, _maxY = 0;
  double _chartTimeMSecs = 0;
  bool _spin = true;

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
    _dashboardUserBloc.add(MobileDashboardEvent());
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  List<DataRow> _getDataRows(List<TradeOrder> tradeOrders) {
    List<DataRow> dataRows = [];
    for (var i = 0; i < tradeOrders.length; i++) {
      dataRows.add(DataRow(
        cells: <DataCell>[
          DataCell(Text(DateFormat('dd.MM.yyyy').format(tradeOrders[i].transactionDate))),
          DataCell(Text(tradeOrders[i].securityName)),
          DataCell(Text(tradeOrders[i].typeName)),
          DataCell(Text(tradeOrders[i].amount.toString())),
        ],
      ));
    }

    return dataRows;
  }

  _openTradeOrders(BuildContext context, List<TradeOrder> tradeOrders) {
    showDialog(
      context: context,
      builder: (context) {
        int numOfOrders = tradeOrders.length;
        String title = 'Trade Orders ($numOfOrders)';

        if (!kIsWeb && Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title, style: TextStyle(fontSize: 18)),
            content: _widgetTradeOrderList(context, tradeOrders),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ok', style: TextStyle(fontSize: 18)),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(title, style: TextStyle(fontSize: 18)),
            content: _widgetTradeOrderList(context, tradeOrders),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ok', style: TextStyle(fontSize: 18)),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _widgetTradeOrderList(BuildContext context, List<TradeOrder> tradeOrders) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height * 0.70;
    return Container(
      width: width,
      height: height,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tradeOrders.length,
        itemBuilder: (BuildContext context, int index) {
          return _widgetTradeOrder(context, tradeOrders[index]);
        },
      ),
    );
  }

  Widget _widgetTradeOrder(BuildContext context, TradeOrder tradeOrder) {
    Color typeColor = Utils.getColor(tradeOrder.typeName == 'Buy' ? 1 : -1);
    String dateText = DateFormat('dd.MM.yyyy').format(tradeOrder.transactionDate);
    String titleText = !kIsWeb && Platform.isIOS ? tradeOrder.securityName : tradeOrder.securityName + ' (' + tradeOrder.securityCode + ')'; //Cupertino quirks

    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(titleText,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis),
          Container(height: 4),
          Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.date_range, size: 18)),
              Padding(padding: EdgeInsets.only(right: 8), child: Text(dateText, style: TextStyle(fontSize: 14))),
              Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.business_center, size: 18)),
              Padding(padding: EdgeInsets.only(right: 4), child: Text(tradeOrder.typeName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: typeColor))),
              Text(tradeOrder.amount.toInt().toString(), style: TextStyle(fontSize:14, fontWeight: FontWeight.bold, color: typeColor), overflow: TextOverflow.ellipsis),
            ],
          ),
          Divider(color: Colors.grey[500], thickness: 1)
        ],
      ),
    );
  }

  _logout(BuildContext context) {
    locator<PreferencesManager>().clearSessionRelated();
    Navigator.pushNamedAndRemoveUntil(context, LoginScreen.route, (r) => false);
  }

  _return(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, LandingScreen.route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    List<TradeOrder> tradeOrders = [];
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Image.asset('assets/images/fa-logo.png',
            height: AppBar().preferredSize.height * 0.75),
        backgroundColor: FaColor.red[900],
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _spin = true;
              _doRefreshToken();
            },
          ),
          IconButton(
            icon: Icon(Icons.format_list_numbered),
            onPressed: () {
              if (tradeOrders.length > 0) _openTradeOrders(context, tradeOrders);
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _return(context);
            },
          ),
        ],
      ),
      body: BlocProvider<MobileDashboardBloc>(
        create: (context) => _dashboardUserBloc,
        child: BlocBuilder<MobileDashboardBloc, MobileDashboardState>(
          builder: (context, state) {
            if (state is MobileDashboardLoading) {
              _spin = true;
            } else if (state is MobileDashboardSuccess) {
              _spin = false;
              if (state.portfolioBody.portfolio == null) return Center(
                child: Text('Error', style: TextStyle(fontSize: 18))
              );
              tradeOrders = state.portfolioBody.portfolio.tradeOrders;
              return _widgetMainView(context, state.portfolioBody);
            } else if (state is MobileDashboardCache) {
              if (state.portfolioBody.portfolio == null) return Center(
                child: Text('Error', style: TextStyle(fontSize: 18)),
              );
              return _widgetMainView(context, state.portfolioBody);
            } else if (state is MobileDashboardFailure) {
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

  Widget _widgetMainView(BuildContext context, PortfolioBody portfolioBody) {
    if (portfolioBody.portfolio == null) return Center(
      child: Text('Error', style: TextStyle(fontSize: 18)),
    );

    _graphRaw = portfolioBody.portfolio.graph;
    _updateGraphStates();

    return SafeArea(
      child: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: () async {
              _spin = true;
              _doRefreshToken();
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _widgetTitle(context, portfolioBody),
                  Container(height: 12, color: Colors.grey[300]),
                  _widgetSummary(context, portfolioBody),
                  Divider(thickness: 2, color: Colors.grey[300]),
                  Padding(
                      padding: EdgeInsets.only(left: 2, right: 2),
                      child: _widgetDateChooser(context)),
                  _widgetDateTitle(context),
                  _graphBenchmarkMinus100.length > 0 ? Padding(
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
                        _graphBenchmarkMinus100.length > 0 ? Expanded(
                          child: Container(
                            height: 200,
                            child: LineChart(
                              _getLineChartData(),
                              swapAnimationDuration: const Duration(milliseconds: 500),
                            ),
                          ),
                        ) : Container()
                      ],
                    ),
                  ) : Container(),
                  _widgetDescriptor(context),
                  Container(height: 12, color: Colors.grey[300]),
                  _widgetInvestments(
                      context, portfolioBody.portfolio.portfolioReport.investments, portfolioBody.portfolio.shortName, portfolioBody.portfolio.portfolioReport.cashBalance)
                ],
              ),
            ),
          ),
          Visibility(
            visible: _spin,
            child: Spinner(),
          )
        ],
      ),
    );
  }

  LineChartData _getLineChartData() {
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
      lineBarsData: _getLineBarDataList(),
    );
  }

  List<LineChartBarData> _getLineBarDataList() {
    final LineChartBarData linePortfolioMinus100 = LineChartBarData(
      spots: _graphPortfolioMinus100,
      isCurved: false,
      colors: [
        Colors.black,
      ],
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
          show: false,
          colors: [
            Colors.grey
          ]
      ),
    );
    final LineChartBarData lineBenchmarkMinus100 = LineChartBarData(
      spots: _graphBenchmarkMinus100,
      isCurved: false,
      colors: [
        FaColor.red[900],
      ],
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: false,
      ),
      belowBarData: BarAreaData(
          show: false,
          colors: [
            FaColor.red[500]
          ]
      ),
    );
    return [
      linePortfolioMinus100,
      lineBenchmarkMinus100
    ];
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
            style: TextStyle(fontSize: 14),
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
            _widgetHeadline(context, portfolio.portfolio.portfolioName),
            Center(
                child: Text(
              portfolio.portfolio.client.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ))
          ],
        ));
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _pressWeekAttention ? Colors.white : Colors.black)),
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _pressMonthAttention ? Colors.white : Colors.black)),
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _press3MonthAttention ? Colors.white : Colors.black)),
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _press6MonthAttention ? Colors.white : Colors.black)),
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
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _pressYTDAttention ? Colors.white : Colors.black)),
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

  Widget _widgetParsedNumberText(BuildContext context, String str) {
    final formatter = NumberFormat("#,###");// using comma here will not work, even by escaping with back slash
    String newString = formatter.format(int.parse(str));
    return Text('€' + newString.replaceAll(',', '.'), style: TextStyle(fontSize: 19));
  }

  Widget _widgetSummary(BuildContext context, PortfolioBody portfolio) {

    var setting = Utils.getMoneySetting('EUR', 1);
    double netAssetValue = portfolio.portfolio.portfolioReport.netAssetValue;
    String strNetAssetValue = netAssetValue > 1000000 ?
    (FlutterMoneyFormatter(amount: netAssetValue, settings: setting).output.compactSymbolOnLeft).replaceFirst('.', ',') :
    FlutterMoneyFormatter(amount: netAssetValue, settings: setting).output.symbolOnLeft;

    double marketValue = portfolio.portfolio.portfolioReport.marketValue;
    String strMarketValue = marketValue > 1000000 ?
    (FlutterMoneyFormatter(amount: marketValue, settings: setting).output.compactSymbolOnLeft).replaceFirst('.', ',') :
    FlutterMoneyFormatter(amount: marketValue, settings: setting).output.symbolOnLeft;

    double cashBalance = portfolio.portfolio.portfolioReport.cashBalance;
    String strCashBalance = cashBalance > 1000000 ?
    (FlutterMoneyFormatter(amount: cashBalance, settings: setting).output.compactSymbolOnLeft).replaceFirst('.', ',') :
    FlutterMoneyFormatter(amount: cashBalance, settings: setting).output.symbolOnLeft;

    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Total Value'),
              Center(
                  child: Text(strNetAssetValue, style: TextStyle(fontSize: 19)),
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Market Value'),
              Center(
                child: Text(strMarketValue, style: TextStyle(fontSize: 19)),
              )
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText(context, 'Cash Balance'),
              Center(
                child: Text(strCashBalance, style: TextStyle(fontSize: 19)),
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget _widgetDescriptor(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(left: 18, right: 18),
            child: Divider(thickness: 3, color: Colors.black),
          ),
        ),
        Flexible(
          child: Text(
            'Investments',
            style: TextStyle(fontSize: 14)
          ),
        ),
        Flexible(
          child: Padding(
            padding: EdgeInsets.only(left: 18, right: 18),
            child: Divider(thickness: 3, color: FaColor.red[900]),
          ),
        ),
        Flexible(
          child: Text(
            'Benchmark',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ]),
    );
  }

  Widget _widgetInvestments(BuildContext context, List<Investment> investments, String shortName, double cashBalance) {
//    deviceList.sort((a, b) => b.deviceLocation.deviceTime.compareTo(a.deviceLocation.deviceTime));

    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12),
        child: ListView.builder(
            itemCount: investments.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int i) {
              return MobileInvestmentItem(investment: investments[i], shortName: shortName, cashBalance: cashBalance);
            }));
  }

  Widget _widgetHeadline(BuildContext context, String text) {
    return Center(
        child: Text(text, style: TextStyle(fontSize: 22),
    ));
  }

  Widget _widgetBodyText(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
    ));
  }

  _updateGraphStates() {
    _graphPortfolioMinus100 = [];
    _graphBenchmarkMinus100 = [];

    if (_graphRaw.dailyValues.dailyValue.length > 0) {
      var lastDate = _graphRaw.dailyValues.dailyValue[_graphRaw.dailyValues.dailyValue.length - 1].date;
      var firstDate = _graphRaw.dailyValues.dailyValue[0].date;
      var comparisonDate;
      if (_graphDateCriteria == 'all') comparisonDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
      if (_graphDateCriteria == _week) comparisonDate = DateTime(lastDate.year, lastDate.month, lastDate.day - 7);
      if (_graphDateCriteria == _month) comparisonDate = DateTime(lastDate.year, lastDate.month - 1, lastDate.day);
      if (_graphDateCriteria == _threeMonth) comparisonDate = DateTime(lastDate.year, lastDate.month - 3, lastDate.day);
      if (_graphDateCriteria == _sixMonth) comparisonDate = DateTime(lastDate.year, lastDate.month - 6, lastDate.day);
      if (_graphDateCriteria == _ytd) comparisonDate = DateTime(lastDate.year, 1, 1);

      if (_pressRangeAttention.length == 2) {
        var first = DateTime(_pressRangeAttention[0].year, _pressRangeAttention[0].month, _pressRangeAttention[0].day);
        var second = DateTime(_pressRangeAttention[1].year, _pressRangeAttention[1].month, _pressRangeAttention[1].day);
        for (var i = 0; i < _graphRaw.dailyValues.dailyValue.length; i++) {
          var v = _graphRaw.dailyValues.dailyValue[i];
          if (v.date.isAfter(first) && v.date.isBefore(second)) {
            _graphPortfolioMinus100.add(FlSpot(v.date.millisecondsSinceEpoch.toDouble(), num.parse(v.portfolioMinus100.toStringAsFixed(1))));
            _graphBenchmarkMinus100.add(FlSpot(v.date.millisecondsSinceEpoch.toDouble(), num.parse(v.benchmarkMinus100.toStringAsFixed(1))));
          }
        }
      } else {
        for (var i = 0; i < _graphRaw.dailyValues.dailyValue.length; i++) {
          var v = _graphRaw.dailyValues.dailyValue[i];
          if (v.date.isAfter(comparisonDate)) {
            _graphPortfolioMinus100.add(FlSpot(v.date.millisecondsSinceEpoch.toDouble(), num.parse(v.portfolioMinus100.toStringAsFixed(1))));
            _graphBenchmarkMinus100.add(FlSpot(v.date.millisecondsSinceEpoch.toDouble(), num.parse(v.benchmarkMinus100.toStringAsFixed(1))));
          }
        }
      }

      if (_graphPortfolioMinus100.length > 0 && _graphBenchmarkMinus100.length > 0) {
        var portfolioValues = List.generate(_graphPortfolioMinus100.length, (i) => _graphPortfolioMinus100[i].y);
        var benchmarkValues = List.generate(_graphBenchmarkMinus100.length, (i) => _graphBenchmarkMinus100[i].y);
        _minY = min(portfolioValues.reduce(min),benchmarkValues.reduce(min));
        _maxY = max(portfolioValues.reduce(max),benchmarkValues.reduce(max));

        _dateRangeFirst = DateTime.fromMillisecondsSinceEpoch(_graphPortfolioMinus100[0].x.toInt());
        _dateRangeLast = DateTime.fromMillisecondsSinceEpoch(_graphPortfolioMinus100[_graphPortfolioMinus100.length -1].x.toInt());
      }
    }
  }
}
