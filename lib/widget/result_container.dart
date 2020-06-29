import 'dart:io';

import 'package:fa_bank/ui/fa_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ResultContainer extends StatelessWidget {
  bool success;
  
  ResultContainer(this.success);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Platform.isIOS ? _getiOSResult(context, success) : _getAndroidResult(context, success),
      ),
    );
  }
}

Widget _getAndroidResult(BuildContext context, bool success) {
  return Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(
        Radius.circular(8.0),
      ),
    ),
    child: success ? Icon(Icons.check_circle, size: 80, color: Colors.green) : Icon(Icons.report_problem, size: 80, color: FaColor.red[900]),
  );
}

Widget _getiOSResult(BuildContext context, bool success) {
  return Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(
        Radius.circular(8.0),
      ),
    ),
    child: success ? Icon(Icons.check_circle, size: 50, color: Colors.green) : Icon(Icons.report_problem, size: 50, color: FaColor.red[900]),
  );
}