import 'dart:io';

import 'package:fa_bank/bloc/login_bloc.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatelessWidget {
  static const String route = '/login_screen';

  final LoginBloc _loginBloc = LoginBloc();
  final TextEditingController _controllerUserName = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

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
  Widget build(BuildContext context) {
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
                        color: Constants.faRed[900],
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
                              _widgetSizedBox(32),
                            ],
                          ),
                        ),
                      ),
                      Container(//centering can be issue on unusually tall/short displays. height of this should be remainder of screen
                        padding: EdgeInsets.only(top: 32, bottom: 64),
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
                              height: 32,
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
                  TextStyle(color: Constants.faRed[900], fontWeight: FontWeight.bold),
                ),
          ),
          onPressed: () {
            String username = _controllerUserName.text.trim();
            String password = _controllerPassword.text.trim();
            if (username.isEmpty || password.isEmpty) {
              _loginBloc.add(LoginEvent(LoginBody('codemate', 'sNY5x18tfy4W', 'password')));
            } else {
              _loginBloc.add(LoginEvent(LoginBody(username, password, 'password')));
            }
          },
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(5.0))),
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
      child: Container(
        child: Image.asset('assets/images/fa-bank-login.png'),
      ),
    );
  }

  Widget _widgetSizedBox(double height) => SizedBox(height: height);
}
