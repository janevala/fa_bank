import 'dart:io';

import 'package:fa_bank/bloc/login_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/ui/backend_screen.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  static const String route = '/login_screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

class _LoginScreenState extends State<LoginScreen> {
  final LoginBloc _loginBloc = LoginBloc();

  final TextEditingController _controllerUserName = TextEditingController();

  final TextEditingController _controllerPassword = TextEditingController();

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
          );
        } else {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyLoginUserName))
      _sharedPreferencesManager.putString(SharedPreferencesManager.keyLoginUserName, 'codemate');
    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyLoginPassword))
      _sharedPreferencesManager.putString(SharedPreferencesManager.keyLoginPassword, 'sNY5x18tfy4W');
    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyBackend))
      _sharedPreferencesManager.putString(SharedPreferencesManager.keyBackend, 'https://fadev.fasolutions.com/');
    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyClientId))
      _sharedPreferencesManager.putString(SharedPreferencesManager.keyClientId, 'fa-back');
    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyClientSecret))
      _sharedPreferencesManager.putString(SharedPreferencesManager.keyClientSecret, 'f692d597-0f4a-4495-a90e-1d090e7288fa');
    if (!_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyPortfolioId))
      _sharedPreferencesManager.putInt(SharedPreferencesManager.keyPortfolioId, 10527024); //10527075
  }

  @override
  Widget build(BuildContext context) {
    //https://stackoverflow.com/questions/49553402/flutter-screen-size
    double height = MediaQuery.of(context).size.height;
    EdgeInsets padding = MediaQuery.of(context).padding;
    double screen = height - padding.top - padding.bottom;

    return Scaffold(
      body: BlocProvider<LoginBloc>(
        create: (context) => _loginBloc,
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginFailure) {
              _showDialog(context, 'Error', state.error);
              ;
            } else if (state is LoginSuccess) {
              Navigator.pushNamedAndRemoveUntil(context, DashboardScreen.route, (r) => false);
            }
          },
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: screen * 0.75,
                        color: FaColor.red[900],
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: <Widget>[
                              _widgetImageHeader(),
                              _widgetSizedBox(16),
                              _widgetLabel(context, 'USER NAME'),
                              _widgetTextFieldUserName(context),
                              _widgetSizedBox(16),
                              _widgetLabel(context, 'PASSWORD'),
                              _widgetTextFieldPassword(context),
                              _widgetSizedBox(64),
                              _widgetButtonSignIn(context),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: screen * 0.25,
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Builder(
                                builder: (stupidToastContext) => InkWell(
                                    onTap: () => _showToast(stupidToastContext, 'Not implemented'),
                                    child: Text(
                                      'FORGOT PASSWORD?',
                                      style: Theme.of(context).textTheme.subtitle2.merge(
                                        TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ))),
                            Container(
                              height: 36,
                            ),
                            Builder(
                                builder: (stupidToastContext) => InkWell(
                                    onTap: () => _showToast(stupidToastContext, 'Not implemented'),
                                    child: Text(
                                      'PRIVACY POLICY',
                                      style: Theme.of(context).textTheme.subtitle2.merge(
                                        TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ))),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                BlocBuilder<LoginBloc, LoginState>(
                  builder: (context, state) {
                    if (state is LoginLoading) {
                      return Spinner();
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _widgetHeadline6(BuildContext context, String text) {
    return Center(
        child: Text(
      text,
      style: Theme.of(context).textTheme.headline6,
    ));
  }

  Widget _widgetButtonSignIn(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 64, right: 64),
      child: FlatButton(
          child: Text(
            'SIGN IN',
            style: Theme.of(context).textTheme.subtitle2.merge(
                  TextStyle(color: FaColor.red[900], fontWeight: FontWeight.bold),
                ),
          ),
          onPressed: () {
            String username = _controllerUserName.text.trim();
            String password = _controllerPassword.text.trim();
            if (username.isEmpty || password.isEmpty) {
              var user = _sharedPreferencesManager.getString(SharedPreferencesManager.keyLoginUserName);
              var pass = _sharedPreferencesManager.getString(SharedPreferencesManager.keyLoginPassword);
              _loginBloc.add(LoginEvent(LoginBody(user, pass, 'password')));
            } else {
              _loginBloc.add(LoginEvent(LoginBody(username, password, 'password')));
            }
          },
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
    );
  }

  Widget _widgetTextFieldUserName(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
              TextStyle(
                color: Colors.white,
              ),
            ),
        controller: _controllerUserName,
        keyboardType: TextInputType.text,
        cursorColor: Colors.white,
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ));
  }

  Widget _widgetTextFieldPassword(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
              TextStyle(
                color: Colors.white,
              ),
            ),
        controller: _controllerPassword,
        keyboardType: TextInputType.text,
        obscureText: true,
        cursorColor: Colors.white,
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ));
  }

  Widget _widgetLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.subtitle2.merge(
            TextStyle(
              color: Colors.white,
            ),
          ),
    );
  }

  Widget _widgetImageHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 64, right: 64, top: 32, bottom: 32),
      child: InkWell(
        onLongPress: () => Navigator.pushNamed(context, BackendScreen.route),
        child: Image.asset('assets/images/fa-bank-login.png'),
      ),
    );
  }

  Widget _widgetSizedBox(double height) => SizedBox(height: height);
}
