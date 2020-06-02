import 'dart:ui';

import 'package:flutter/material.dart';

class Utils {
  static Color getColor(double d) {
    if (d > 0)
      return Colors.green;
    else if (d < 0)
      return Colors.red;
    else
      return Colors.black;
  }
}