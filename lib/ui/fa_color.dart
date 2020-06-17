import 'package:flutter/material.dart';

class FaColor {
  static Map<int, Color> redCodes = {
    50: Color.fromRGBO(191, 2, 1, .1),
    100: Color.fromRGBO(191, 2, 1, .2),
    200: Color.fromRGBO(191, 2, 1, .3),
    300: Color.fromRGBO(191, 2, 1, .4),
    400: Color.fromRGBO(191, 2, 1, .5),
    500: Color.fromRGBO(191, 2, 1, .6),
    600: Color.fromRGBO(191, 2, 1, .7),
    700: Color.fromRGBO(191, 2, 1, .8),
    800: Color.fromRGBO(191, 2, 1, .9),
    900: Color.fromRGBO(191, 2, 1, 1),
  };

  static MaterialColor red = MaterialColor(0xFFBF0201, redCodes);
}