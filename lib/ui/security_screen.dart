import 'package:charts_flutter/flutter.dart' as charts;
import 'package:fa_bank/api/graphql.dart';
import 'package:fa_bank/bloc/security_bloc.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/podo/portfolio/investment.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/security/graph.dart';
import 'package:fa_bank/podo/security/security.dart';
import 'package:fa_bank/podo/security/security_body.dart';
import 'package:fa_bank/ui/investment_item.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/utils/utils.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// "Security" as in financial nomenclature, not data or information security.
///
/// "Security" is a fungible, negotiable financial instrument that holds some type of monetary value.

class SecurityScreen extends StatefulWidget {
  static const String route = '/security_screen';

  @override
  _SecurityScreenState createState() => _SecurityScreenState();
}

final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityBloc _securityBloc = SecurityBloc();

  final TextEditingController _controllerAmount = TextEditingController();
  String _controllerOnChanged;
  final TextEditingController _controllerDate = TextEditingController();

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

  bool _dialogVisible = false;
  String _transactionType = '';

  DateTime _dateRangeFirst = DateTime.now();
  DateTime _dateRangeLast = DateTime.now();

  @override
  void initState() {
    super.initState();

    _doRefreshToken();
  }

  static final HttpLink _httpLink = HttpLink(uri: Constants.faAuthApi);

  static final AuthLink _authLink = AuthLink(
      getToken: () async =>
          'Bearer ' + _sharedPreferencesManager.getString(SharedPreferencesManager.keyAccessToken));

  static final Link _link = _authLink.concat(_httpLink);

  ValueNotifier<GraphQLClient> _faClient = ValueNotifier(
    GraphQLClient(
      cache: InMemoryCache(),
      link: _link,
    ),
  );

  _doOnExpiry() async {
    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs))
      await _sharedPreferencesManager.clearKey(SharedPreferencesManager.keyAuthMSecs);
  }

  _doRefreshToken() async {
    String refreshToken =
        _sharedPreferencesManager.getString(SharedPreferencesManager.keyRefreshToken);
    RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
    _securityBloc.add(SecurityEvent(refreshTokenBody));
  }

  String _getNow() {
    DateTime now = DateTime.now();
    return DateFormat('d MMMM yyyy').format(now);
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
    Scaffold.of(context)
        .showSnackBar(SnackBar(duration: Duration(milliseconds: 400), content: Text(text)));
  }

  _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title, style: Theme.of(context).textTheme.headline6),
            content: Text(content, style: Theme.of(context).textTheme.subtitle2),
            actions: [
              FlatButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Ok', style: Theme.of(context).textTheme.subtitle2),
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text(title, style: Theme.of(context).textTheme.headline6),
            content: Text(content, style: Theme.of(context).textTheme.subtitle2),
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

  @override
  Widget build(BuildContext context) {
    final SecurityArgument arg = ModalRoute.of(context).settings.arguments;
    final Investment investment = arg.investment;
    final Security security = arg.investment.security;
    final String shortName = arg.shortName;

    _controllerDate.text = _getNowAgain();

    return GraphQLProvider(
        client: _faClient,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              security.name,
              style: Theme.of(context).textTheme.headline6.merge(
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
            ),
            backgroundColor: Constants.faRed[900],
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
                  _showToast(context, state.error);
                }
              },
              child: BlocBuilder<SecurityBloc, SecurityState>(
                builder: (context, state) {
                  if (state is SecurityLoading) {
                    return Spinner();
                  } else if (state is SecuritySuccess) {
                    return Query(
                        options: QueryOptions(documentNode: gql(securityQuery), variables: {"securityCode": security.securityCode}, pollInterval: 60000),
                        builder: (QueryResult result, {VoidCallback refetch, FetchMore fetchMore}) {
                          if (result.hasException) {
                            if (result.exception.clientException != null) {
                              String msg = result.exception.clientException.message;
                              if (msg.contains('Network Error: 401')) {
                                _doOnExpiry();
                                _doRefreshToken();
                              } else {
                                return Center(child: Text(msg));
                              }
                            } else if (result.exception.graphqlErrors[0] != null) {
                              return Center(child: Text(result.exception.graphqlErrors[0].message));
                            } else {
                              return Center(child: Text('Network Error'));
                            }
                          }
                          if (result.loading) return Spinner();

                          SecurityBody securityBody = SecurityBody.fromJson(result.data);

                          return _widgetMainView(context, securityBody, investment, shortName);
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

  Widget _widgetMainView(BuildContext context, SecurityBody securityBody, Investment investment, String shortName) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double heightScreen = mediaQueryData.size.height;

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
                  _widgetSummary(context, securityBody, investment),
                  Divider(color: Colors.grey),
                  _widgetDetail(context, securityBody, investment),
                  Padding(
                      padding: EdgeInsets.only(left: 2, right: 2),
                      child: _widgetDateChooser(context)),
                  _widgetDayTitle(context),
                  Container(
                    height: 250,
                    child: Padding(
                      padding: EdgeInsets.only(left: 4, right: 4),
                      child: charts.TimeSeriesChart(
                        _chartData(securityBody.securities[0].graph),
                        animate: _animate,
                        defaultRenderer: charts.LineRendererConfig(),
                        customSeriesRenderers: [
                          charts.PointRendererConfig(
                              customRendererId: 'stocksPoint')
                        ],
                        dateTimeFactory: const charts.LocalDateTimeFactory(),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey[300],
                    child: Padding(
                      padding: EdgeInsets.only(left: 56, right: 56),
                      child: Column(children: <Widget>[
                        _widgetInformation(
                            context, securityBody.securities[0].url),
                        Divider(color: Colors.black),
                        _widgetTextRow(
                            context,
                            'Market Value', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'Purchase Value', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'Return', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'EGS Rating', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'Risk Score', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'Purchase Value', securityBody.securities[0].marketData.latestValue.toString()),
                        _widgetTextRow(
                            context,
                            'Ticker', investment.security.securityCode),


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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: SizedBox.expand(
                            child: FlatButton(
                                child: Text('SELL',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .merge(
                                      TextStyle(
                                          color: Colors.white,
                                          fontSize: 20),
                                    )),
                                color: Constants.faRed[900],
                                onPressed: () {
                                  setState(() {
                                    _controllerAmount.text = '';
                                    _controllerOnChanged = '';
                                    _dialogVisible = true;
                                    _transactionType = 'M'; //logical, sell in Finnish
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    new BorderRadius.circular(5.0))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: SizedBox.expand(
                            child: FlatButton(
                                child: Text('BUY',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .merge(
                                      TextStyle(
                                          color: Colors.white,
                                          fontSize: 20),
                                    )),
                                color: Colors.green,
                                onPressed: () {
                                  setState(() {
                                    _controllerAmount.text = '';
                                    _controllerOnChanged = '';
                                    _dialogVisible = true;
                                    _transactionType = 'B';
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    new BorderRadius.circular(5.0))),
                          ),
                        ),
                      ),
                    ]),
              )),

          _widgetPurchaseScreen(context, securityBody, shortName)

        ],
      ),
    );
  }

  double _calculateOnChanged(double askPrice) {
    if (_controllerOnChanged == null || _controllerOnChanged.isEmpty) return 0;
    if (!_isNumeric(_controllerOnChanged)) return 0;
    return askPrice * double.parse(_controllerOnChanged);
  }

  Widget _widgetPurchaseScreen(BuildContext context, SecurityBody securityBody, String shortName) {
    return IgnorePointer(
        ignoring: !_dialogVisible,
        child: AnimatedOpacity(
          opacity: _dialogVisible ? 1 : 0,
          duration: Duration(milliseconds: 500),
          child: SizedBox.expand(
            child: Container(
              color: Colors.white,
              child: Padding(
                  padding: EdgeInsets.only(left: 32, right: 32),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                              padding: EdgeInsets.only(top: 16, bottom: 16),
                              child: _widgetHeadline6(context, 'NEW TRANSACTION')),
                          _widgetAmount(context),
                          _widgetDate(context),
                          _widgetTextRow(context, 'Ask:', securityBody.securities[0].marketData.latestValue.toString() + ' €'),
                          _widgetTextRow(context, 'Estimated price:', _calculateOnChanged(securityBody.securities[0].marketData.latestValue).toStringAsFixed(2) + ' €'),
                          _widgetTextRow(context, 'Current balance:', '-'),
                          Container(height: 16),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: FlatButton(
                                      child: Text('CANCEL',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline6
                                              .merge(
                                            TextStyle(
                                                color: Colors.black,
                                                fontSize: 20),
                                          )),
                                      color: Colors.white,
                                      onPressed: () {
                                        FocusScope.of(context).unfocus();

                                        setState(() {
                                          _dialogVisible = false;
                                        });
                                      },
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: Colors.black,
                                              width: 1,
                                              style: BorderStyle.solid),
                                          borderRadius: BorderRadius.circular(5.0))),
                                ),
                                Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: _widgetMutation(context, securityBody, shortName)),
                                ),
                              ])
                        ]),
                  )),
            ),
          ),
        ));
  }

  Widget _widgetMutation(BuildContext context, SecurityBody securityBody, String shortName) {
    return Mutation(
      options: MutationOptions(
        documentNode:
        gql(transactionMutation),
        update: (Cache cache, QueryResult result) {
          if (result.hasException) {
            if (result.exception.clientException != null) {
              String msg = result.exception.clientException.message;
              if (msg.contains('Network Error: 401')) {
                _doOnExpiry();
                _doRefreshToken();
                _showDialog(context, 'Updated', 'Please try again');
              }
            }
          } else {
            bool resultOk = false;
            List<dynamic> list = result.data['importTradeOrders'];
            for (var i = 0; i < list.length; i++) {
              Map<String, dynamic> v = list[i];
              if (v.containsKey( 'importStatus') && v.containsValue('OK')) {
                resultOk = true;
              }
            }

            if (resultOk) {
              //refetch();
              setState(() {
                _dialogVisible = false;
              });
              _showDialog(context, 'Success', 'Transaction was submitted successfully.\n\nIt will be added to Open Orders shortly');
            } else {
              _showDialog(context, 'Error', result.data.toString());
            }
          }

          return cache;
        },
      ),
      builder: (RunMutation runMutation, QueryResult result) {
        return FlatButton(
            child: Text(_transactionType == 'B' ? 'SEND BUY ORDER' : 'SEND SELL ORDER',
                style: Theme.of(context).textTheme.headline6.merge(
                  TextStyle(
                      color:
                      Colors.white,
                      fontSize: 20),
                )),
            color: _transactionType == 'B' ? Colors.green : Constants.faRed[900],
            onPressed: () {
              FocusScope.of(context).unfocus();

              String _amount = _controllerAmount.text.trim();
              String _date = _controllerDate.text.trim();
              if (_amount.isEmpty || _date.isEmpty) {
                _showToast(context, 'Please correct input and try again');
              } else {
                runMutation({
                  'parentPortfolio': shortName,
                  'security': securityBody.securities[0].securityCode,
                  'amount': double.parse(_amount),
                  'price': securityBody.securities[0].marketData.latestValue,
                  'currency': securityBody.securities[0].currency.currencyCode,
                  'type': _transactionType,
                  'dateString': _date
                });
              }
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)));
      },
    );
  }

  Widget _widgetDateChooser(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _showToast(context, 'Not implemented'),
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
                height: 28,
                minWidth: 30,
                child: FlatButton(
                    color: _pressWeekAttention ? Constants.faRed[900] : Colors.white,
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressWeekAttention ? Constants.faRed[900] : Colors.black,
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
                  color: _pressMonthAttention ? Constants.faRed[900] : Colors.white,
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

                        _animate = false;
                      }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _pressMonthAttention ? Constants.faRed[900] : Colors.black,
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
                  color: _press3MonthAttention ? Constants.faRed[900] : Colors.white,
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

                        _animate = false;
                      }),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: _press3MonthAttention ? Constants.faRed[900] : Colors.black,
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
                    color: _press6MonthAttention ? Constants.faRed[900] : Colors.white,
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _press6MonthAttention ? Constants.faRed[900] : Colors.black,
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
                    color: _pressYTDAttention ? Constants.faRed[900] : Colors.white,
                    child: Text(_ytd,
                        style: Theme.of(context).textTheme.bodyText2.merge(
                              TextStyle(
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

                          _animate = false;
                        }),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: _pressYTDAttention ? Constants.faRed[900] : Colors.black,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: new BorderRadius.circular(20.0)))),
          ))
    ]);
  }

  Widget _widgetParsedNumberText(BuildContext context, String str) {
    final formatter = NumberFormat("#,###");// using comma here will not work, even by escaping with back slash
    String newString = formatter.format(int.parse(str));
    return Text('€' + newString.replaceAll(',', '.'), style: Theme.of(context).textTheme.headline6);
  }

  Widget _widgetSummary(BuildContext context, SecurityBody securityBody, Investment investment) {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Total amount'),
              _widgetBoldHeadline6(context,
                  investment.amount.toStringAsFixed(0), Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Total current value'),
              _widgetParsedNumberText(context, (investment.amount * securityBody.securities[0].marketData.latestValue).toStringAsFixed(0))
            ],
          ),
        ),
      ]),
    );
  }

  Widget _widgetDayTitle(BuildContext context) {
    DateTime dateFirst = DateTime(_dateRangeFirst.year, _dateRangeFirst.month, _dateRangeFirst.day);
    DateTime dateLast = DateTime(_dateRangeLast.year, _dateRangeLast.month, _dateRangeLast.day);
    bool visible = !(dateFirst.isAtSameMomentAs(dateLast));
    DateFormat fmt = DateFormat('dd.MM.yyyy');
    String s = fmt.format(_dateRangeFirst) + ' - ' + fmt.format(_dateRangeLast);
    return Container(
      color: Colors.white,
      height: 24,
      child: Visibility(
        visible: visible,
        child: Center(
          child: _widgetBodyText2(context, s),
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
                  style: Theme.of(context).textTheme.headline6.merge(
                        TextStyle(fontSize: 20),
                      ),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.subtitle2,
                  controller: _controllerAmount,
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    setState(() {
                      _controllerOnChanged = text;
                    });
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    WhitelistingTextInputFormatter(RegExp("[0-9]"))
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
                  style: Theme.of(context).textTheme.headline6.merge(
                        TextStyle(fontSize: 20),
                      ),
                ),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: TextField(
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.subtitle2,
                  enabled: false,
                  controller: _controllerDate,
                  keyboardType: TextInputType.datetime,
                ),
              ),
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
              _widgetBodyText2(context, 'Latest value'),
              _widgetBoldHeadline6(context,
                  '€' + securityBody.securities[0].marketData.latestValue.toString(), Colors.black)
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Return'),
              _widgetBoldHeadline6(
                  context,
                  investment.changePercent.toStringAsFixed(2) + '%',
                  Utils.getColor(investment.changePercent))
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: <Widget>[
              _widgetBodyText2(context, 'Today'),
              _widgetBoldHeadline6(
                  context,
                  'n/a',
                  Colors.black)
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
                    child: Text(
                  'Investment Details',
                  style: Theme.of(context).textTheme.headline6.merge(TextStyle(fontSize: 20),
                      ),
                )),
                Visibility(
                  visible: (url == null || url == '') ? false : true,
                  child: InkWell(
                    onTap: () async {
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        _showToast(context, 'Cannot open information');
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

  Widget _widgetTextRow(BuildContext context, String label, String text) {
    return Padding(
        padding: EdgeInsets.only(top: 12, bottom: 12),
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

  Widget _widgetBoldHeadline6(BuildContext context, String text, Color color) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6.merge(
            TextStyle(color: color),
          ),
    ));
  }

  Widget _widgetHeadline6(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6,
    ));
  }

  Widget _widgetSubtitle2(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.subtitle2,
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

  List<charts.Series<TimeSeries, DateTime>> _chartData(List<Graph> graphs) {
    List<TimeSeries> portfolioMinus100Series = [];
    List<TimeSeries> portfolioMinus100Pointers = [];

    if (graphs.length > 0) {
      var lastDate = graphs[graphs.length - 1].date;
      var firstDate = graphs[0].date;
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
      if (_graphDateCriteria == _ytd) comparisonDate = DateTime(lastDate.year, 1, 1);

      for (var i = 0; i < graphs.length; i++) {
        if (graphs[i].date.isAfter(comparisonDate)) {
          portfolioMinus100Series.add(TimeSeries(graphs[i].date, graphs[i].price));
//        if (i % 100 == 0) portfolioMinus100Pointers.add(TimeSeries(graphs[i].date, graphs[i].price));
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
          id: 'portfolioMinus100Pointers',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
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
