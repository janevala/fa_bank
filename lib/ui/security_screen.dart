import 'package:fa_bank/bloc/security_bloc.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/security/graph.dart';
import 'package:fa_bank/podo/security/security.dart';
import 'package:fa_bank/podo/security/security_body.dart';
import 'package:fa_bank/ui/investment_item.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/material.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:intl/intl.dart';

/// "Security" as in financial nomenclature, not data or information security.
///
/// "Security" is a fungible, negotiable financial instrument that holds some type of monetary value.

class SecurityScreen extends StatefulWidget {
  static const String route = '/security_screen';

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

String securityQuery = """
query Security(\$securityCode: String) {
  securities( securityCode: \$securityCode ) {
    name
    securityCode
    marketData: latestMarketData {
      latestValue:close
    }
    graph:marketDataHistory(timePeriodCode:"YEARS-1") {
      date:obsDate
      price:close
    }
    currency {
      currencyCode:securityCode
    }
  }
}
""";

final SharedPreferencesManager _sharedPreferencesManager =
    locator<SharedPreferencesManager>();

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityBloc _securityBloc = SecurityBloc();

  final bool animate = false;

  String _graphDateCriteria = 'all';
  bool _pressWeekAttention = false;
  bool _pressMonthAttention = false;
  bool _press3MonthAttention = false;
  bool _press6MonthAttention = false;
  static const String _week = '1w';
  static const String _month = '1m';
  static const String _threeMonth = '3m';
  static const String _sixMonth = '6m';

  @override
  void initState() {
    super.initState();

    doRefreshToken();
  }

  static final HttpLink httpLink = HttpLink(uri: Constants.faAuthApi);

  static final AuthLink authLink = AuthLink(
      getToken: () async =>
          'Bearer ' +
          _sharedPreferencesManager
              .getString(SharedPreferencesManager.keyAccessToken));

  static final Link link = authLink.concat(httpLink);

  ValueNotifier<GraphQLClient> faClient = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    ),
  );

  doOnExpiry() async {
    if (_sharedPreferencesManager
        .isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager
          .clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  doRefreshToken() async {
    String refreshToken = _sharedPreferencesManager
        .getString(SharedPreferencesManager.keyRefreshToken);
    RefreshTokenBody refreshTokenBody =
        RefreshTokenBody('refresh_token', refreshToken);
    _securityBloc.add(SecurityEvent(refreshTokenBody));
  }

  @override
  Widget build(BuildContext context) {
    final SecurityArgument arg = ModalRoute.of(context).settings.arguments;
    final Security security = arg.security;
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double heightScreen = mediaQueryData.size.height;

    return GraphQLProvider(
        client: faClient,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: Colors.white),
            title: Center(
              child: Text(
                security.name,
                style: Theme.of(context).textTheme.headline6.merge(
                      TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ),
            backgroundColor: Constants.faColorRed[900],
/*            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  doRefreshToken();
                },
              ),
            ],*/
          ),
          body: BlocProvider<SecurityBloc>(
            create: (context) => _securityBloc,
            child: BlocListener<SecurityBloc, SecurityState>(
              listener: (context, state) {
                if (state is SecurityFailure) {
                  showToast(context, state.error);
                }
              },
              child: BlocBuilder<SecurityBloc, SecurityState>(
                builder: (context, state) {
                  if (state is SecurityLoading) {
                    return Spinner();
                  } else if (state is SecuritySuccess) {
                    return Query(
                        options: QueryOptions(
                            documentNode: gql(securityQuery),
                            variables: {"securityCode": security.securityCode},
                            pollInterval: 30000),
                        builder: (QueryResult result,
                            {VoidCallback refetch, FetchMore fetchMore}) {
                          if (result.hasException) {
                            if (result.exception.clientException != null) {
                              String msg = result.exception.clientException.message;
                              if (msg.contains('Network Error: 401')) {
                                doOnExpiry();
                                doRefreshToken();
                              } else {
                                return Center(child: Text(msg));
                              }
                            } else if (result.exception.graphqlErrors[0] !=
                                null) {
                              return Center(child: Text(result.exception.graphqlErrors[0].message));
                            } else {
                              return Center(child: Text('Network Error'));
                            }
                          }
                          if (result.loading) return Spinner();

                          var securityBody = SecurityBody.fromJson(result.data);

                          return SafeArea(
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  height: heightScreen - 160, //fix this mess
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _buildSummary(context, securityBody),
                                        Divider(color: Colors.grey),
                                        _buildDetail(context, securityBody),
                                        _buildDateChooser(context),
                                        Container(
                                          height: 250,
                                          child: charts.TimeSeriesChart(_createChartData(securityBody.securities[0].graph),
                                            animate: animate,
                                            defaultRenderer: charts.LineRendererConfig(),
                                            customSeriesRenderers: [charts.PointRendererConfig(customRendererId: 'stocksPoint')],
                                            dateTimeFactory: const charts.LocalDateTimeFactory(),
                                          ),
                                        ),
                                        Container(
                                          color: Colors.grey[300],
                                          child: Padding(
                                            padding: EdgeInsets.only(left: 56, right: 56),
                                            child: Column(
                                                children: <Widget>[
                                                  _buildInformation(context),
                                                  Divider(color: Colors.black),
                                                  _buildRow(context, 'Ask', securityBody.securities[0].marketData.latestValue.toString()),
                                                  _buildRow(context, 'Bid', securityBody.securities[0].marketData.latestValue.toString()),
                                                  Divider(color: Colors.black),
                                                  _buildRow(context, 'High', securityBody.securities[0].marketData.latestValue.toString()),
                                                  _buildRow(context, 'Low', securityBody.securities[0].marketData.latestValue.toString()),
                                                ]),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 80,
                                      color: Colors.white,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(20),
                                                child: SizedBox.expand(
                                                  child: FlatButton(
                                                      child: Text('SELL',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .merge(
                                                                    TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            20),
                                                                  )),
                                                      color: Constants
                                                          .faColorRed[900],
                                                      onPressed: () => showToast(
                                                          context,
                                                          'Not implemented'),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              new BorderRadius
                                                                      .circular(
                                                                  5.0))),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.all(20),
                                                child: SizedBox.expand(
                                                  child: FlatButton(
                                                      child: Text('BUY',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .headline6
                                                                  .merge(
                                                                    TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            20),
                                                                  )),
                                                      color: Colors.green,
                                                      onPressed: () => showToast(
                                                          context,
                                                          'Not implemented'),
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              new BorderRadius
                                                                      .circular(
                                                                  5.0))),
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ))
                              ],
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

  Widget _buildDateChooser(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Expanded(
          flex: 2,
          child: Center(
            child: InkWell(
              onTap: () => showToast(context, 'Not implemented'),
              child: Container(
                  height: 30,
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
                            padding:
                            const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Icon(Icons.date_range),
                          ),
                        ),
                        TextSpan(text: 'Date range'),
                      ],
                    ),
                  )),
            ),
          )),
      Expanded(
          child: Center(
            child: ButtonTheme(
                height: 30,
                minWidth: 32,
                child: FlatButton(
                    color: _pressWeekAttention
                        ? Constants.faColorRed[900]
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
                    }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressWeekAttention
                                ? Constants.faColorRed[900]
                                : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          )),
      Expanded(
          child: Center(
            child: ButtonTheme(
              height: 30,
              minWidth: 32,
              child: FlatButton(
                  color: _pressMonthAttention
                      ? Constants.faColorRed[900]
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
                  }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _pressMonthAttention
                              ? Constants.faColorRed[900]
                              : Colors.black,
                          width: 1,
                          style: BorderStyle.solid),
                      borderRadius: new BorderRadius.circular(20.0))),
            ),
          )),
      Expanded(
          child: Center(
            child: ButtonTheme(
              height: 30,
              minWidth: 32,
              child: FlatButton(
                  color: _press3MonthAttention
                      ? Constants.faColorRed[900]
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
                  }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _press3MonthAttention
                              ? Constants.faColorRed[900]
                              : Colors.black,
                          width: 1,
                          style: BorderStyle.solid),
                      borderRadius: new BorderRadius.circular(20.0))),
            ),
          )),
      Expanded(
          child: Center(
            child: ButtonTheme(
                height: 30,
                minWidth: 32,
                child: FlatButton(
                    color: _press6MonthAttention
                        ? Constants.faColorRed[900]
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
                    }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _press6MonthAttention
                                ? Constants.faColorRed[900]
                                : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          )),
      Expanded(
          child: Center(
            child: ButtonTheme(
                height: 30,
                minWidth: 32,
                child: FlatButton(
                    color: false ? Constants.faColorRed[900] : Colors.white,
                    child: Text('ytd',
                        style: Theme.of(context).textTheme.bodyText2.merge(
                          TextStyle(
                              fontWeight: FontWeight.bold,
                              color: false ? Colors.white : Colors.black),
                        )),
                    onPressed: () => showToast(context, 'Not implemented'),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: false ? Constants.faColorRed[900] : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          ))
    ]);
  }

  Widget _buildSummary(BuildContext context, SecurityBody portfolio) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _buildWidgetBodyText2(context, 'Total amount'),
              _buildWidgetBoldHeadline6(
                  context,
                  portfolio.securities[0].marketData.latestValue.toString() +
                      ' €',
                  Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _buildWidgetBodyText2(context, 'Total current value'),
              _buildWidgetBoldHeadline6(
                  context,
                  portfolio.securities[0].marketData.latestValue.toString() +
                      ' €',
                  Colors.black)
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDetail(BuildContext context, SecurityBody portfolio) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _buildWidgetBodyText2(context, 'Latest value (EUR)'),
              _buildWidgetBoldHeadline6(
                  context,
                  portfolio.securities[0].marketData.latestValue.toString() +
                      ' €',
                  Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _buildWidgetBodyText2(context, 'Return'),
              _buildWidgetBoldHeadline6(
                  context,
                  portfolio.securities[0].marketData.latestValue.toString() +
                      ' €',
                  Utils.getColor(
                      portfolio.securities[0].marketData.latestValue))
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _buildWidgetBodyText2(context, 'Today'),
              _buildWidgetBoldHeadline6(
                  context,
                  portfolio.securities[0].marketData.latestValue.toString() +
                      ' €',
                  Utils.getColor(
                      portfolio.securities[0].marketData.latestValue))
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildInformation(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
                child: Text(
                  'INFORMATION',
                  style: Theme.of(context).textTheme.headline6.merge(
                    TextStyle(fontSize: 20),
                  ),
                )),
            Center(
                child: Text(
                  _getCurrentTime(),
                  style: Theme.of(context).textTheme.headline6.merge(
                    TextStyle(fontSize: 20),
                  ),
                ))
          ],
        ));
  }

  Widget _buildRow(BuildContext context, String label, String text) {
    return Padding(
        padding: EdgeInsets.only(top: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headline6.merge(
                    TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.headline6.merge(
                    TextStyle(fontSize: 20),
                  ),
                ),
              ),
            )
          ],
        ));
  }

  Widget _buildWidgetBoldHeadline6(
      BuildContext context, String text, Color color) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6.merge(
            TextStyle(color: color),
          ),
    ));
  }

  Widget _buildWidgetHeadline6(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6,
    ));
  }

  Widget _buildWidgetSubtitle2(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.subtitle2,
    ));
  }

  Widget _buildWidgetBodyText2(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.bodyText2.merge(
            TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
    ));
  }

  String _getCurrentTime() {
    DateTime now = DateTime.now();
    return DateFormat('d MMMM yyyy').format(now);
  }

  List<charts.Series<TimeSeries, DateTime>> _createChartData(
      List<Graph> graphs) {
    List<TimeSeries> portfolioMinus100Series = [];
    List<TimeSeries> portfolioMinus100Pointers = [];

    var lastDate = graphs[graphs.length - 1].date;
    var firstDate = graphs[0].date;
    var comparisonDate;
    if (_graphDateCriteria == 'all')
      comparisonDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
    if (_graphDateCriteria == _week)
      comparisonDate =
          DateTime(lastDate.year, lastDate.month, lastDate.day - 7);
    if (_graphDateCriteria == _month)
      comparisonDate =
          DateTime(lastDate.year, lastDate.month - 1, lastDate.day);
    if (_graphDateCriteria == _threeMonth)
      comparisonDate =
          DateTime(lastDate.year, lastDate.month - 3, lastDate.day);
    if (_graphDateCriteria == _sixMonth)
      comparisonDate =
          DateTime(lastDate.year, lastDate.month - 6, lastDate.day);

    for (var i = 0; i < graphs.length; i++) {
      if (graphs[i].date.isAfter(comparisonDate)) {
        portfolioMinus100Series
            .add(TimeSeries(graphs[i].date, graphs[i].price));
//        if (i % 100 == 0) portfolioMinus100Pointers.add(TimeSeries(graphs[i].date, graphs[i].price));
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
          id: 'portfolioMinus100Pointers',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          domainFn: (TimeSeries s, _) => s.time,
          measureFn: (TimeSeries s, _) => s.unit,
          data: portfolioMinus100Pointers)
        ..setAttribute(charts.rendererIdKey, 'stocksPoint'),
    ];
  }
}

showToast(BuildContext context, var text) {
  Scaffold.of(context).showSnackBar(
      SnackBar(duration: Duration(milliseconds: 400), content: Text(text)));
}

class TimeSeries {
  final DateTime time;
  final double unit;

  TimeSeries(this.time, this.unit);
}
