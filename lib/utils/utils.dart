import 'dart:ui';

import 'package:fa_bank/constants.dart';
import 'package:flutter/material.dart';

class Utils {
  static Color getColor(double d) {
    if (d > 0)
      return Colors.green;
    else if (d < 0)
      return Constants.faRed[900];
    else
      return Colors.black;
  }
}