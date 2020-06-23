import 'dart:io';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:date_range_picker/date_range_picker.dart' as DateRangePicker;
import 'package:fa_bank/bloc/dashboard_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/portfolio/trade_order.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/investment_item.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  static const String route = '/dashboard_screen';

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardBloc _dashboardUserBloc = DashboardBloc();

  //Graph globals
  bool _animate = true;
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

  DateTime _dateTime = DateTime.now();
  DateTime _dateRangeFirst = DateTime.now();
  DateTime _dateRangeLast = DateTime.now();

  bool _spin = true;

  @override
  void initState() {
    super.initState();

    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyUid)) _logout();

    _doRefreshToken();
  }

  _doOnExpiry() async {
    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager.clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    _dashboardUserBloc.add(DashboardEvent());
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMM yyyy').format(dateTime);
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  Widget _dataTable(BuildContext context, List<TradeOrder> tradeOrders) {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            'Date',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Stock',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Buy/Sell',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        DataColumn(
          label: Text(
            'Amount',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],

      rows: _getDataRows(tradeOrders),
    );
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
        int numOfOrders = tradeOrders.length + 1;
        String title = 'Trade Orders ($numOfOrders)';

        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title, style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 20))),
            content: _widgetTradeOrderList(context, tradeOrders),
            actions: [
              FlatButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ok', style: Theme.of(context).textTheme.subtitle2),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(title, style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 20))),
            content: _widgetTradeOrderList(context, tradeOrders),
            actions: [
              FlatButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ok', style: Theme.of(context).textTheme.subtitle2),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _widgetTradeOrderList(BuildContext context, List<TradeOrder> tradeOrders) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
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

    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(tradeOrder.securityName + ' (' + tradeOrder.securityCode + ')',
              style: Theme.of(context).textTheme.subtitle2,
              overflow: TextOverflow.ellipsis),
          Container(height: 4),
          Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.date_range, size: 20)),
              Padding(padding: EdgeInsets.only(right: 4), child: Text(dateText, style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(fontSize: 16)))),
              Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.business_center, size: 20)),
              Padding(padding: EdgeInsets.only(right: 4), child: Text(tradeOrder.typeName, style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: typeColor)))),
              Text(tradeOrder.amount.toInt().toString(), style: Theme.of(context).textTheme.subtitle2.merge(TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: typeColor))),
            ],
          ),
          Divider(color: Colors.grey[300], thickness: 2)
        ],
      ),
    );
  }

  _onChanged(charts.SelectionModel<DateTime> model) {
    setState(() {
      _dateTime = model.selectedDatum.first.datum.time;
      _animate = false;
    });
  }

  _logout() {
    locator<SharedPreferencesManager>().clearAll();
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
              _logout();
            },
          ),
        ],
      ),
      body: BlocProvider<DashboardBloc>(
        create: (context) => _dashboardUserBloc,
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              _spin = true;
            } else if (state is DashboardSuccess) {
              _spin = false;
              _animate = true;
              tradeOrders = state.portfolioBody.portfolio.tradeOrders;
              return _widgetMainView(context, state.portfolioBody);
            } else if (state is DashboardCache) {
              _animate = false;
              return _widgetMainView(context, state.portfolioBody);
            } else if (state is DashboardFailure) {
              return Center(
                child: Text(state.error, style: Theme.of(context).textTheme.subtitle2),
              );
            }

            return Spinner();
          },
        ),
      ),
    );
  }

  Widget _widgetMainView(BuildContext context, PortfolioBody portfolioBody) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
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
                Container(
                  height: 250,
                  child: Padding(
                    padding: EdgeInsets.only(left: 4, right: 4),
                    child: charts.TimeSeriesChart(
                      _chartData(portfolioBody.portfolio.graph),
                      animate: _animate,
                      defaultRenderer: charts.LineRendererConfig(),
                      customSeriesRenderers: [
                        charts.PointRendererConfig(
                            customRendererId: 'stocksPoint')
                      ],
                      dateTimeFactory: charts.LocalDateTimeFactory(),
                      selectionModels: [
                        charts.SelectionModelConfig(
                            type: charts.SelectionModelType.info)
                        //changedListener: _onChanged)
                      ],
                    ),
                  ),
                ),
                _widgetDateTitle(context),
                _widgetDescriptor(context),
                Container(height: 12, color: Colors.grey[300]),
                _widgetInvestments(
                    context, portfolioBody.portfolio.portfolioReport.investments, portfolioBody.portfolio.shortName, portfolioBody.portfolio.portfolioReport.cashBalance)
              ],
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

  Widget _widgetDateTitle(BuildContext context) {
    DateTime dateFirst = DateTime(_dateRangeFirst.year, _dateRangeFirst.month, _dateRangeFirst.day);
    DateTime dateLast = DateTime(_dateRangeLast.year, _dateRangeLast.month, _dateRangeLast.day);
    bool visible = !(dateFirst.isAtSameMomentAs(dateLast));
    String str = _formatDateTime(_dateRangeFirst) + ' - ' + _formatDateTime(_dateRangeLast);
    return Container(
      height: 24,
      child: Visibility(
        visible: visible,
        child: Center(
          child: Text(
            str,
            style: Theme.of(context).textTheme.bodyText2,
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
              style: Theme.of(context).textTheme.bodyText2.merge(
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
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
              final List<DateTime> picked = await DateRangePicker.showDatePicker(
                  context: context,
                  initialFirstDate: DateTime(now.year, now.month - 1, now.day),
                  initialLastDate: DateTime(now.year, now.month, now.day),
                  firstDate: DateTime(2016),
                  lastDate: DateTime(now.year, now.month, now.day)
              );
              if (picked != null && picked.length == 2) {
                setState(() {
                  _pressRangeAttention = picked;
                  _pressWeekAttention = false;
                  _pressMonthAttention = false;
                  _press3MonthAttention = false;
                  _press6MonthAttention = false;
                  _pressYTDAttention = false;
                  _animate = true;
                });
              }
            },
            child: Container(
                height: 28,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyText2.merge(
                            TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
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
          child: Center(
            child: ButtonTheme(
                height: 28,
                minWidth: 30,
                child: FlatButton(
                    color: _pressWeekAttention ? FaColor.red[900] : Colors.white,
                    child: Text(_week,
                        style: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _pressWeekAttention ? Colors.white : Colors.black),
                            )),
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressWeekAttention ? FaColor.red[900] : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          )),
      Expanded(
          flex: 2,
          child: Center(
            child: ButtonTheme(
              height: 28,
              minWidth: 30,
              child: FlatButton(
                  color: _pressMonthAttention ? FaColor.red[900] : Colors.white,
                  child: Text(_month,
                      style: Theme.of(context).textTheme.bodyText2.merge(
                            TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _pressMonthAttention ? Colors.white : Colors.black),
                          )),
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

                        _animate = false;
                      }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _pressMonthAttention ? FaColor.red[900] : Colors.black,
                          width: 1,
                          style: BorderStyle.solid),
                      borderRadius: new BorderRadius.circular(20.0))),
            ),
          )),
      Expanded(
          flex: 2,
          child: Center(
            child: ButtonTheme(
              height: 28,
              minWidth: 30,
              child: FlatButton(
                  color: _press3MonthAttention ? FaColor.red[900] : Colors.white,
                  child: Text(_threeMonth,
                      style: Theme.of(context).textTheme.bodyText2.merge(
                            TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _press3MonthAttention ? Colors.white : Colors.black),
                          )),
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

                        _animate = false;
                      }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _press3MonthAttention ? FaColor.red[900] : Colors.black,
                          width: 1,
                          style: BorderStyle.solid),
                      borderRadius: new BorderRadius.circular(20.0))),
            ),
          )),
      Expanded(
          flex: 2,
          child: Center(
            child: ButtonTheme(
                height: 28,
                minWidth: 30,
                child: FlatButton(
                    color: _press6MonthAttention ? FaColor.red[900] : Colors.white,
                    child: Text(_sixMonth,
                        style: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _press6MonthAttention ? Colors.white : Colors.black),
                            )),
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _press6MonthAttention ? FaColor.red[900] : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          )),
      Expanded(
          flex: 2,
          child: Center(
            child: ButtonTheme(
                height: 28,
                minWidth: 30,
                child: FlatButton(
                    color: _pressYTDAttention ? FaColor.red[900] : Colors.white,
                    child: Text(_ytd,
                        style: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(
                                fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _pressYTDAttention ? Colors.white : Colors.black),
                            )),
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressYTDAttention ? FaColor.red[900] : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          ))
    ]);
  }

  Widget _widgetParsedNumberText(BuildContext context, String str) {
    final formatter = NumberFormat("#,###");// using comma here will not work, even by escaping with back slash
    String newString = formatter.format(int.parse(str));
    return Text('€' + newString.replaceAll(',', '.'), style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 19)));
  }

  Widget _widgetSummary(BuildContext context, PortfolioBody portfolio) {

    var setting = Utils.getMoneySetting('EUR', 1);
    double netAssetValue = portfolio.portfolio.portfolioReport.netAssetValue;
    String strNetAssetValue = netAssetValue > 1000000 ?
    FlutterMoneyFormatter(amount: netAssetValue, settings: setting).output.compactSymbolOnLeft :
    FlutterMoneyFormatter(amount: netAssetValue, settings: setting).output.symbolOnLeft;

    double marketValue = portfolio.portfolio.portfolioReport.marketValue;
    String strMarketValue = marketValue > 1000000 ?
    FlutterMoneyFormatter(amount: marketValue, settings: setting).output.compactSymbolOnLeft :
    FlutterMoneyFormatter(amount: marketValue, settings: setting).output.symbolOnLeft;

    double cashBalance = portfolio.portfolio.portfolioReport.cashBalance;
    String strCashBalance = cashBalance > 1000000 ?
    FlutterMoneyFormatter(amount: cashBalance, settings: setting).output.compactSymbolOnLeft :
    FlutterMoneyFormatter(amount: cashBalance, settings: setting).output.symbolOnLeft;

    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Total Value'),
              Center(
                  child: Text(strNetAssetValue, style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 19))),
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Market Value'),
              Center(
                child: Text(strMarketValue, style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 19))),
              )
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Cash Balance'),
              Center(
                child: Text(strCashBalance, style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 19))),
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
            style: Theme.of(context).textTheme.bodyText2,
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
            style: Theme.of(context).textTheme.bodyText2,
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
              return InvestmentItem(investment: investments[i], shortName: shortName, cashBalance: cashBalance);
            }));
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

  List<charts.Series<TimeSeries, DateTime>> _chartData(Graph graphs) {
    List<TimeSeries> portfolioMinus100Series = [];
    List<TimeSeries> portfolioMinus100Pointers = [];
    List<TimeSeries> benchmarkMinus100Series = [];

    if (graphs.dailyValues.dailyValue.length > 0) {
      var lastDate = graphs.dailyValues.dailyValue[graphs.dailyValues.dailyValue.length - 1].date;
      var firstDate = graphs.dailyValues.dailyValue[0].date;
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
        for (var i = 0; i < graphs.dailyValues.dailyValue.length; i++) {
          var v = graphs.dailyValues.dailyValue[i];
          if (v.date.isAfter(first) && v.date.isBefore(second)) {
            portfolioMinus100Series.add(TimeSeries(v.date, v.portfolioMinus100));
            benchmarkMinus100Series.add(TimeSeries(v.date, v.benchmarkMinus100));
          }
        }
      } else {
        for (var i = 0; i < graphs.dailyValues.dailyValue.length; i++) {
          var v = graphs.dailyValues.dailyValue[i];
          if (v.date.isAfter(comparisonDate)) {
            portfolioMinus100Series.add(TimeSeries(v.date, v.portfolioMinus100));
            benchmarkMinus100Series.add(TimeSeries(v.date, v.benchmarkMinus100));
          }
        }
      }

      if (portfolioMinus100Series.length > 0) {
        _dateRangeFirst = portfolioMinus100Series[0].time;
        _dateRangeLast = portfolioMinus100Series[portfolioMinus100Series.length -1].time;
      }
    }

    return [
      charts.Series<TimeSeries, DateTime>(
        id: 'portfolioMinus100Series',
        colorFn: (_, __) => charts.MaterialPalette.black,
        domainFn: (TimeSeries s, _) => s.time,
        measureFn: (TimeSeries s, _) => s.unit,
        data: portfolioMinus100Series,
      ),
      charts.Series<TimeSeries, DateTime>(
        id: 'benchmarkMinus100Series',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (TimeSeries s, _) => s.time,
        measureFn: (TimeSeries s, _) => s.unit,
        data: benchmarkMinus100Series,
      ),
      charts.Series<TimeSeries, DateTime>(
          id: 'portfolioMinus100Pointers',
          colorFn: (_, __) => charts.MaterialPalette.black,
          domainFn: (TimeSeries s, _) => s.time,
          measureFn: (TimeSeries s, _) => s.unit,
          data: portfolioMinus100Pointers)
        ..setAttribute(charts.rendererIdKey, 'stocksPoint'),
    ];
  }
}

class TimeSeries {
  final DateTime time;
  final double unit;

  TimeSeries(this.time, this.unit);
}
