import 'dart:convert';
import 'dart:io';

import 'package:fa_bank/bloc/login_bloc.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/config_model.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/ui/backend_screen.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/ui/kyc_screen.dart';
import 'package:fa_bank/ui/landing_screen.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  static const String route = '/login_screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

final PreferencesManager _preferencesManager = locator<PreferencesManager>();

class _LoginScreenState extends State<LoginScreen> {
  final LoginBloc _loginBloc = LoginBloc(LoginInitial());

  final TextEditingController _controllerUserName = TextEditingController();

  final TextEditingController _controllerPassword = TextEditingController();

  ConfigModel _configModel;

  _showToast(BuildContext context, var text) {
    Scaffold.of(context).showSnackBar(
        SnackBar(duration: Duration(milliseconds: 500), content: Text(text)));
  }

  _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        if (!kIsWeb && Platform.isIOS) {
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

    _loadConfigs();

  }

  _loadConfigs() async {
    try {
      var b64str = await DefaultAssetBundle.of(context).loadString("assets/config.b64");
      var b64chr = Base64Decoder().convert(b64str);

      _configModel = ConfigModel.fromJson(json.decode(String.fromCharCodes(b64chr)));

      if (_configModel != null) {
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyLoginUserName))
          _preferencesManager.putString(PreferencesManager.keyLoginUserName, _configModel.loginUserName);
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyLoginPassword))
          _preferencesManager.putString(PreferencesManager.keyLoginPassword, _configModel.loginPassword);
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyBackend))
          _preferencesManager.putString(PreferencesManager.keyBackend, _configModel.backend);
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyClientId))
          _preferencesManager.putString(PreferencesManager.keyClientId, _configModel.clientId);
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyClientSecret))
          _preferencesManager.putString(PreferencesManager.keyClientSecret, _configModel.clientSecret);
        if (!_preferencesManager.isKeyExists(PreferencesManager.keyPortfolioId))
          _preferencesManager.putInt(PreferencesManager.keyPortfolioId, _configModel.portfolioId);
      }

    } catch (error, stacktrace) {
      print(error);
    }
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
            } else if (state is LoginSuccess) {
              if (_preferencesManager.isKeyExists(PreferencesManager.keyKycCompleted)) {
                Navigator.pushNamedAndRemoveUntil(context, LandingScreen.route, (r) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, KycScreen.route, (r) => false);
              }
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
                            physics: NeverScrollableScrollPhysics(),
                            children: <Widget>[
                              _widgetImageHeader(),
                              _widgetSizedBox(16),
                              _widgetLabel('USER NAME'),
                              _widgetTextFieldUserName(),
                              _widgetSizedBox(16),
                              _widgetLabel('PASSWORD'),
                              _widgetTextFieldPassword(),
                              _widgetSizedBox(64),
                              _widgetButtonSignIn(),
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
                                      child: Text('FORGOT PASSWORD?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ))),
                            Container(
                              height: 36,
                            ),
                            Builder(
                                builder: (stupidToastContext) => InkWell(
                                    onTap: () => _showToast(stupidToastContext, 'Not implemented'),
                                      child: Text('PRIVACY POLICY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _widgetButtonSignIn() {
    return Padding(
      padding: EdgeInsets.only(left: 64, right: 64),
      child: FlatButton(
          child: Text(
            'SIGN IN',
            style: TextStyle(fontSize: 18, color: FaColor.red[900], fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            if (_configModel != null) {
              String username = _controllerUserName.text.trim();
              String password = _controllerPassword.text.trim();
              if (username.isEmpty || password.isEmpty) {
                var user = _preferencesManager.getString(PreferencesManager.keyLoginUserName);
                var pass = _preferencesManager.getString(PreferencesManager.keyLoginPassword);
                _loginBloc.add(LoginEvent(LoginBody(user, pass, 'password')));
              } else {
                _loginBloc.add(LoginEvent(LoginBody(username, password, 'password')));
              }
            }
          },
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
    );
  }

  Widget _widgetTextFieldUserName() {
    return TextField(
        style: TextStyle(fontSize: 18, color: Colors.white),
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

  Widget _widgetTextFieldPassword() {
    return TextField(
        style: TextStyle(fontSize: 18, color: Colors.white),
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

  Widget _widgetLabel(String label) {
    return Text(label,
      style: TextStyle(fontSize: 18, color: Colors.white),
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
