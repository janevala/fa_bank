import 'dart:io';

import 'package:fa_bank/ui/fa_color.dart';
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
    height: 60,
    width: 60,
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(FaColor.red[800]),
      backgroundColor: FaColor.red[300],
    ),
  );
}

Widget _buildCupertinoSpinner(BuildContext context) {
  return SizedBox(
    child: CupertinoActivityIndicator(radius: 18)
  );
}