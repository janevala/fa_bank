import 'package:charts_flutter/flutter.dart' as charts;
import 'package:fa_bank/bloc/dashboard_bloc.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/podo/portfolio/graph.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/ui/investment_item.dart';
import 'package:fa_bank/ui/login_screen.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  static const String route = '/dashboard_screen';

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

String portfolioQuery = """
query PortfolioOverview(\$id: Long!) {
  portfolio(id: \$id) {
    client: primaryContact {
      name
    }
    portfolioName: name
    portfolioReport: portfolioReport(use15minDelayedPrice: true,
      calculateExpectedAmountBasedOpenTradeOrders: true) {
      marketValue: positionMarketValue
      cashBalance: accountBalance
      netAssetValue: marketValue
      investments: portfolioReportItems {
        security {
          name
          securityCode
        }
        positionValue: marketTradeAmount
        changePercent: valueChangeRelative
      }
    }
    graph:analytics(withoutPositionData:false,
      parameters: {
        paramsSet: {
          timePeriodCodes:"GIVEN"
          includeData:true
          drilldownEnabled:false
          limit: 0
        },
        includeDrilldownPositions:false
      }) {
      dailyValues:grouppedAnalytics(key:"1") {
        dailyValue:indexedReturnData {
          date
          portfolioMinus100:indexedValue
          benchmarkMinus100:benchmarkIndexedValue
        }
      }
    }
  }
}
""";

//note withoutPositionData false = slower query

final SharedPreferencesManager _sharedPreferencesManager =
    locator<SharedPreferencesManager>();

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
  static const String _week = '1w';
  static const String _month = '1m';
  static const String _threeMonth = '3m';
  static const String _sixMonth = '6m';
  static const String _ytd = 'YTD';

  DateTime _dateTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    _doRefreshToken();
  }

  static final HttpLink _httpLink = HttpLink(uri: Constants.faAuthApi);

  static final AuthLink _authLink = AuthLink(
      getToken: () async =>
          'Bearer ' +
          _sharedPreferencesManager
              .getString(SharedPreferencesManager.keyAccessToken));

  static final Link link = _authLink.concat(_httpLink);

  ValueNotifier<GraphQLClient> _faClient = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    ),
  );

  _doOnExpiry() async {
    if (_sharedPreferencesManager
        .isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager
          .clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    String refreshToken = _sharedPreferencesManager
        .getString(SharedPreferencesManager.keyRefreshToken);
    RefreshTokenBody refreshTokenBody =
        RefreshTokenBody('refresh_token', refreshToken);
    _dashboardUserBloc.add(DashboardEvent(refreshTokenBody));
  }

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(
        SnackBar(duration: Duration(milliseconds: 400), content: Text(text)));
  }

  _onChanged(charts.SelectionModel<DateTime> model) {
    setState(() {
      _dateTime = model.selectedDatum.first.datum.time;
      _animate = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
        client: _faClient,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Image.asset('assets/images/fa-bank.png',
                height: AppBar().preferredSize.height * 0.8),
            backgroundColor: Constants.faRed[900],
            actions: <Widget>[
/*              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  doRefreshToken();
                },
              ),*/
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: () {
                  locator<SharedPreferencesManager>().clearAll();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.route, (r) => false);
                },
              ),
            ],
          ),
          body: BlocProvider<DashboardBloc>(
            create: (context) => _dashboardUserBloc,
            child: BlocListener<DashboardBloc, DashboardState>(
              listener: (context, state) {
                if (state is DashboardFailure) {
                  _showToast(context, state.error);
                }
              },
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return Spinner();
                  } else if (state is DashboardSuccess) {
                    return Query(
                        options: QueryOptions(
                            documentNode: gql(portfolioQuery),
                            variables: {"id": 10527075},
//                            variables: {"id": 10527024},
                            pollInterval: 30000),
                        builder: (QueryResult result,
                            {VoidCallback refetch, FetchMore fetchMore}) {
                          if (result.hasException) {
                            if (result.exception.clientException != null) {
                              String msg =
                                  result.exception.clientException.message;
                              if (msg.contains('Network Error: 401')) {
                                _doOnExpiry();
                                _doRefreshToken();
                              } else {
                                return Center(child: Text(msg));
                              }
                            } else if (result.exception.graphqlErrors[0] !=
                                null) {
                              return Center(
                                  child: Text(result
                                      .exception.graphqlErrors[0].message));
                            } else {
                              return Center(child: Text('Network Error'));
                            }
                          }
                          if (result.loading) return Spinner();

                          var portfolioBody =
                              PortfolioBody.fromJson(result.data);

                          return SafeArea(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  _widgetTitle(context, portfolioBody),
                                  Container(height: 12, color: Colors.grey[300]),
                                  _widgetSummary(context, portfolioBody),
                                  Padding(padding: EdgeInsets.only(left: 2, right: 2),
                                      child: _widgetDateChooser(context)),
                                  _widgetDay(context),
                                  Container(
                                    height: 250,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 4, right: 4),
                                      child: charts.TimeSeriesChart(_chartData(portfolioBody.portfolio.graph),
                                        animate: _animate,
                                        defaultRenderer: charts.LineRendererConfig(),
                                        customSeriesRenderers: [charts.PointRendererConfig(customRendererId: 'stocksPoint')],
                                        dateTimeFactory: charts.LocalDateTimeFactory(),
                                        selectionModels: [
                                          charts.SelectionModelConfig(
                                              type: charts.SelectionModelType.info,
                                              changedListener: _onChanged)
                                        ],
                                      ),
                                    ),
                                  ),
                                  _widgetDescriptor(context),
                                  Container(height: 12, color: Colors.grey[300]),
                                  _widgetInvestments(
                                      context,
                                      portfolioBody.portfolio.portfolioReport
                                          .investments)
                                ],
                              ),
                            ),
                          );
                        });
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
        ));
  }


  Widget _widgetDay(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 12),
        child: _widgetBodyText2(context, DateFormat('d MMMM yyyy').format(_dateTime)));
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
            onTap: () => _showToast(context, 'Not implemented'),
            child: Container(
                height: 30,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyText2.merge(
                        TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      children: [
                        WidgetSpan(
                          child: Padding(
                            padding: EdgeInsets.only(right: 2.0),
                            child: Icon(Icons.date_range, size: 20),
                          ),
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
            height: 30,
            minWidth: 32,
            child: FlatButton(
                color: _pressWeekAttention
                    ? Constants.faRed[900]
                    : Colors.white,
                child: Text(_week,
                    style: Theme.of(context).textTheme.bodyText2.merge(
                          TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _pressWeekAttention
                                  ? Colors.white
                                  : Colors.black),
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

                      _animate = false;
                    }),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: _pressWeekAttention
                            ? Constants.faRed[900]
                            : Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    borderRadius: new BorderRadius.circular(20.0)))),
      )),
      Expanded(
          flex: 2,
          child: Center(
        child: ButtonTheme(
          height: 30,
          minWidth: 32,
          child: FlatButton(
              color: _pressMonthAttention
                  ? Constants.faRed[900]
                  : Colors.white,
              child: Text(_month,
                  style: Theme.of(context).textTheme.bodyText2.merge(
                        TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _pressMonthAttention
                                ? Colors.white
                                : Colors.black),
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

                    _animate = false;
                  }),
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: _pressMonthAttention
                          ? Constants.faRed[900]
                          : Colors.black,
                      width: 1,
                      style: BorderStyle.solid),
                  borderRadius: new BorderRadius.circular(20.0))),
        ),
      )),
      Expanded(
          flex: 2,
          child: Center(
        child: ButtonTheme(
          height: 30,
          minWidth: 32,
          child: FlatButton(
              color: _press3MonthAttention
                  ? Constants.faRed[900]
                  : Colors.white,
              child: Text(_threeMonth,
                  style: Theme.of(context).textTheme.bodyText2.merge(
                        TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _press3MonthAttention
                                ? Colors.white
                                : Colors.black),
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

                    _animate = false;
                  }),
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: _press3MonthAttention
                          ? Constants.faRed[900]
                          : Colors.black,
                      width: 1,
                      style: BorderStyle.solid),
                  borderRadius: new BorderRadius.circular(20.0))),
        ),
      )),
      Expanded(
          flex: 2,
          child: Center(
        child: ButtonTheme(
            height: 30,
            minWidth: 32,
            child: FlatButton(
                color: _press6MonthAttention
                    ? Constants.faRed[900]
                    : Colors.white,
                child: Text(_sixMonth,
                    style: Theme.of(context).textTheme.bodyText2.merge(
                          TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _press6MonthAttention
                                  ? Colors.white
                                  : Colors.black),
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

                      _animate = false;
                    }),
                shape: RoundedRectangleBorder(
                    side: BorderSide(
                        color: _press6MonthAttention
                            ? Constants.faRed[900]
                            : Colors.black,
                        width: 1,
                        style: BorderStyle.solid),
                    borderRadius: new BorderRadius.circular(20.0)))),
      )),
      Expanded(
          flex: 2,
          child: Center(
            child: ButtonTheme(
                height: 30,
                minWidth: 32,
                child: FlatButton(
                    color: _pressYTDAttention
                        ? Constants.faRed[900]
                        : Colors.white,
                    child: Text(_ytd,
                        style: Theme.of(context).textTheme.bodyText2.merge(
                          TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _pressYTDAttention
                                  ? Colors.white
                                  : Colors.black),
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

                      _animate = false;
                    }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressYTDAttention
                                ? Constants.faRed[900]
                                : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          ))
    ]);
  }

  Widget _widgetSummary(BuildContext context, PortfolioBody portfolio) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Net asset value'),
              Center(
                  child: Text(
                    portfolio.portfolio.portfolioReport.netAssetValue.toString() + ' €',
                    style: Theme.of(context).textTheme.headline6.merge(
                      TextStyle(fontSize: 19)
                    ),
                  ))
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Market value'),
              Center(
                  child: Text(
                    portfolio.portfolio.portfolioReport.marketValue.toString() + ' €',
                      style: Theme.of(context).textTheme.headline6.merge(
                          TextStyle(fontSize: 19)
                      )
                  ))
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Cash balance'),
              Center(
                  child: Text(
                    portfolio.portfolio.portfolioReport.cashBalance.toString() + ' €',
                      style: Theme.of(context).textTheme.headline6.merge(
                          TextStyle(fontSize: 19)
                      )
                  ))
            ],
          ),
        ),
      ]),
    );
  }

  Widget _widgetDescriptor(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
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
            child: Divider(thickness: 3, color: Constants.faRed[900]),
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

  Widget _widgetInvestments(BuildContext context, List<Investment> investments) {
//    deviceList.sort((a, b) => b.deviceLocation.deviceTime.compareTo(a.deviceLocation.deviceTime));

    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 6, right: 6),
        child: ListView.builder(
            itemCount: investments.length,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int i) {
              return InvestmentItem(investment: investments[i]);
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

  List<charts.Series<TimeSeries, DateTime>> _chartData(Graph graph) {
    List<TimeSeries> portfolioMinus100Series = [];
    List<TimeSeries> portfolioMinus100Pointers = [];
    List<TimeSeries> benchmarkMinus100Series = [];

    var lastDate = graph
        .dailyValues.dailyValue[graph.dailyValues.dailyValue.length - 1].date;
    var firstDate = graph.dailyValues.dailyValue[0].date;
    var comparisonDate;
    if (_graphDateCriteria == 'all')
      comparisonDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
    if (_graphDateCriteria == _week)
      comparisonDate = DateTime(lastDate.year, lastDate.month, lastDate.day - 7);
    if (_graphDateCriteria == _month)
      comparisonDate = DateTime(lastDate.year, lastDate.month - 1, lastDate.day);
    if (_graphDateCriteria == _threeMonth)
      comparisonDate = DateTime(lastDate.year, lastDate.month - 3, lastDate.day);
    if (_graphDateCriteria == _sixMonth)
      comparisonDate = DateTime(lastDate.year, lastDate.month - 6, lastDate.day);
    if (_graphDateCriteria == _ytd)
      comparisonDate = DateTime(lastDate.year, 1, 1);

    for (var i = 0; i < graph.dailyValues.dailyValue.length; i++) {
      var v = graph.dailyValues.dailyValue[i];
      if (v.date.isAfter(comparisonDate)) {
        portfolioMinus100Series.add(TimeSeries(v.date, v.portfolioMinus100));
//      if (i % 1000 == 0) portfolioMinus100Pointers.add(TimeSeriesSales(v.date, v.portfolioMinus100));
        benchmarkMinus100Series.add(TimeSeries(v.date, v.benchmarkMinus100));
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
