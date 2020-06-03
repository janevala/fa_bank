import 'dart:io';

import 'package:fa_bank/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Spinner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 100.0,
          height: 100.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          child: Center(
            child: Platform.isIOS ? _buildCupertinoSpinner(context) : _buildMaterialSpinner(context),
          ),
        ),
      ),
    );
  }
}

Widget _buildMaterialSpinner(BuildContext context) {
  return SizedBox(
    height: 70,
    width: 70,
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Constants.faRed[800]),
      backgroundColor: Constants.faRed[300],
    ),
  );
}

Widget _buildCupertinoSpinner(BuildContext context) {
  return SizedBox(
    height: 70,
    width: 70,
    child: CupertinoActivityIndicator()
  );
}