import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

class Constants {
  static DateFormat dateFormatFull = DateFormat("dd.MM.yyyy hh:mm aaa");
  static DateFormat dateFormatTime = DateFormat("hh:mm aaa");

  static const String faBaseUrl = 'https://fadev.fasolutions.com/';
  static const String faAuthApi = faBaseUrl + 'graphql';
  @JsonKey(name: 'client_id')
  static const String clientId = 'fa-back';
  @JsonKey(name: 'client_secret')
  static const String clientSecret = 'f692d597-0f4a-4495-a90e-1d090e7288fa';

  static Map<int, Color> faColorRedCodes = {
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

  static MaterialColor faColorRed = MaterialColor(0xFFBF0201, faColorRedCodes);

  static Map<int, Color> faColorGreyCodes = {
    50: Color.fromRGBO(151, 151, 151, .1),
    100: Color.fromRGBO(151, 151, 151, .2),
    200: Color.fromRGBO(151, 151, 151, .3),
    300: Color.fromRGBO(151, 151, 151, .4),
    400: Color.fromRGBO(151, 151, 151, .5),
    500: Color.fromRGBO(151, 151, 151, .6),
    600: Color.fromRGBO(151, 151, 151, .7),
    700: Color.fromRGBO(151, 151, 151, .8),
    800: Color.fromRGBO(151, 151, 151, .9),
    900: Color.fromRGBO(151, 151, 151, 1),
  };

  static MaterialColor faColorGrey = MaterialColor(0xFF979797, faColorGreyCodes);
}