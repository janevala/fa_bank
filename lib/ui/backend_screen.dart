import 'dart:io';

import 'package:fa_bank/app.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/ui/fa_color.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

class BackendScreen extends StatelessWidget {
  static const String route = '/backend_screen';

  TextEditingController _controllerUserName = TextEditingController();
  TextEditingController _controllerPassword = TextEditingController();
  TextEditingController _controllerBackend = TextEditingController();
  TextEditingController _controllerClientId = TextEditingController();
  TextEditingController _controllerClientSecret = TextEditingController();
  TextEditingController _controllerPortfolioId = TextEditingController();

  @override
  Widget build(BuildContext context) {

    _controllerUserName.text = _sharedPreferencesManager.getString(SharedPreferencesManager.keyLoginUserName);
    _controllerPassword.text = _sharedPreferencesManager.getString(SharedPreferencesManager.keyLoginPassword);
    _controllerBackend.text = _sharedPreferencesManager.getString(SharedPreferencesManager.keyBackend);
    _controllerClientId.text = _sharedPreferencesManager.getString(SharedPreferencesManager.keyClientId);
    _controllerClientSecret.text = _sharedPreferencesManager.getString(SharedPreferencesManager.keyClientSecret);
    _controllerPortfolioId.text = _sharedPreferencesManager.getInt(SharedPreferencesManager.keyPortfolioId).toString();

    return Scaffold(
      backgroundColor: FaColor.red[900],
      body: SafeArea(
        child: Container(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: SingleChildScrollView(
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'USER NAME'),
                    _widgetFieldUserName(context),
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'PASSWORD'),
                    _widgetFieldPlainTextPassword(context),
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'BACKEND'),
                    _widgetFieldBackend(context),
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'CLIENT ID'),
                    _widgetFieldClientId(context),
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'CLIENT SECRET'),
                    _widgetFieldClientSecret(context),
                    _widgetSizedBox(16),
                    _widgetLabel(context, 'PORTFOLIO ID'),
                    _widgetFieldPortfolioId(context),
                    _widgetSizedBox(16),
                    _widgetSaveAndReboot(context),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _widgetSaveAndReboot(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 32, right: 32),
      child: FlatButton(
          child: Text(
            'SAVE AND RESTART',
            style: Theme.of(context).textTheme.subtitle2.merge(
                  TextStyle(color: FaColor.red[900], fontWeight: FontWeight.bold),
                ),
          ),
          onPressed: () async {
            String username = _controllerUserName.text.trim();
            String password = _controllerPassword.text.trim();
            String backend = _controllerBackend.text.trim();
            String clientId = _controllerClientId.text.trim();
            String clientSecret = _controllerClientSecret.text.trim();
            String portfolioId = _controllerPortfolioId.text.trim();
            if (username.isNotEmpty || password.isNotEmpty || backend.isNotEmpty || clientId.isNotEmpty || clientSecret.isNotEmpty || portfolioId.isNotEmpty ) {
              await _sharedPreferencesManager.clearAll();

              await _sharedPreferencesManager.putString(SharedPreferencesManager.keyLoginUserName, username);
              await _sharedPreferencesManager.putString(SharedPreferencesManager.keyLoginPassword, password);
              await _sharedPreferencesManager.putString(SharedPreferencesManager.keyBackend, backend);
              await _sharedPreferencesManager.putString(SharedPreferencesManager.keyClientId, clientId);
              await _sharedPreferencesManager.putString(SharedPreferencesManager.keyClientSecret, clientSecret);
              await _sharedPreferencesManager.putInt(SharedPreferencesManager.keyPortfolioId, int.parse(portfolioId));

              await Future.delayed(const Duration(seconds: 2));

              RestartWidget.restartApp(context);
            }
          },
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
    );
  }

  Widget _widgetFieldUserName(BuildContext context) {
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

  Widget _widgetFieldPlainTextPassword(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
          TextStyle(
            color: Colors.white,
          ),
        ),
        controller: _controllerPassword,
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

  Widget _widgetFieldBackend(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
          TextStyle(
            color: Colors.white,
          ),
        ),
        controller: _controllerBackend,
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

  Widget _widgetFieldClientId(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
          TextStyle(
            color: Colors.white,
          ),
        ),
        controller: _controllerClientId,
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

  Widget _widgetFieldClientSecret(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
          TextStyle(
            color: Colors.white,
              fontSize: 16
          ),
        ),
        controller: _controllerClientSecret,
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

  Widget _widgetFieldPortfolioId(BuildContext context) {
    return TextField(
        style: Theme.of(context).textTheme.subtitle2.merge(
          TextStyle(
            color: Colors.white,
          ),
        ),
        controller: _controllerPortfolioId,
        keyboardType: Platform.isIOS ? TextInputType.numberWithOptions(signed: true) : TextInputType.number,
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

  Widget _widgetSizedBox(double height) => SizedBox(height: height);
}
