import 'dart:io';

import 'package:fa_bank/constants.dart';
import 'package:fa_bank/ui/dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fa_bank/bloc/login_bloc.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/widget/spinner.dart';

class LoginScreen extends StatelessWidget {
  static const String route = '/login_screen';

  final LoginBloc _loginBloc = LoginBloc();
  final TextEditingController _controllerUserName = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    double heightScreen = mediaQueryData.size.height;

    return Scaffold(
      body: BlocProvider<LoginBloc>(
        create: (context) => _loginBloc,
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginFailure) {
              String title = 'Info';
              showDialog(
                context: context,
                builder: (context) {
                  if (Platform.isIOS) {
                    return CupertinoAlertDialog(
                      title: Text(title),
                      content: Text(state.error),
                    );
                  } else {
                    return AlertDialog(
                      title: Text(title),
                      content: Text(state.error),
                    );
                  }
                },
              );
            } else if (state is LoginSuccess) {
              Navigator.pushNamedAndRemoveUntil(
                  context, DashboardScreen.route, (r) => false);
            }
          },
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                ListView(
                  children: <Widget>[
                    Container(
                      height: heightScreen,
                      color: Constants.faColorRed[900],
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: ListView(
                          children: <Widget>[
                            _buildWidgetImageHeader(),
                            _buildWidgetSizedBox(32),
                            _buildWidgetLabel(context, 'USER NAME'),
                            _buildWidgetTextFieldUserName(context),
                            _buildWidgetSizedBox(32),
                            _buildWidgetLabel(context, 'PASSWORD'),
                            _buildWidgetTextFieldPassword(context),
                            _buildWidgetSizedBox(64),
                            _buildWidgetButtonSignin(context),
                            _buildWidgetSizedBox(64),
                          ],
                        ),
                      ),
                    ),
/*                    Container(
                      height: 150,
                      color: Colors.white,
                      child: _buildInformation(context),
                    )*/
                  ],
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

  Widget _buildInformation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildWidgetHeadline6(context, 'FORGOT PASSWORD?'),
        _buildWidgetHeadline6(context, 'PRIVACY POLICY'),
      ],
    );
  }

  Widget _buildWidgetHeadline6(BuildContext context, String text) {
    return Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.headline6,
        ));
  }

  Widget _buildWidgetButtonSignin(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 64, right: 64),
      child: FlatButton(
        child: Text(
          'SIGN IN',
          style: Theme.of(context).textTheme.subtitle2.merge(
            TextStyle(
                color: Constants.faColorRed[900],
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        onPressed: () {
          String username = _controllerUserName.text.trim();
          String password = _controllerPassword.text.trim();
          if (username.isEmpty || password.isEmpty) {
            _loginBloc.add(
                LoginEvent(LoginBody('codemate', 'sNY5x18tfy4W', 'password')));
          } else {
            _loginBloc
                .add(LoginEvent(LoginBody(username, password, 'password')));
          }
        },
        color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius:
              new BorderRadius
                  .circular(
                  5.0))
      ),
    );
  }

  Widget _buildWidgetTextFieldUserName(BuildContext context) {
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

  Widget _buildWidgetTextFieldPassword(BuildContext context) {
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

  Widget _buildWidgetLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.subtitle2.merge(
            TextStyle(
              color: Colors.white,
            ),
          ),
    );
  }

  Widget _buildWidgetSizedBox(double height) => SizedBox(height: height);

  Widget _buildWidgetImageHeader() {
    return Padding(
      padding: EdgeInsets.all(64),
      child: Container(
        child: Image.asset('assets/images/fa-bank-login.png'),
      ),
    );
  }

  Widget _buildWidgetOverlayBackgroundImageHeader(double heightScreen) {
    return Container(
      height: heightScreen / 2.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.white.withOpacity(1.0),
            Colors.white.withOpacity(0.1),
          ],
          stops: [
            0.1,
            0.5,
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetRectangleWhite(double heightScreen) {
    return Container(
      height: heightScreen / 2.4,
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 20.0,
        color: Colors.white,
      ),
    );
  }
}
