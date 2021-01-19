import 'dart:ui';
import 'dart:math';

import 'package:fa_bank/ui/fa_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';

class Utils {
  static Color getColor(double d) {
    if (d > 0)
      return Colors.green;
    else if (d < 0)
      return FaColor.red[900];
    else
      return Colors.black;
  }

  static Color getColorLight(double d) {
    if (d > 0)
      return Colors.green[200];
    else if (d < 0)
      return FaColor.red[200];
    else
      return Colors.grey;
  }

  static MoneyFormatterSettings getMoneySetting(String symbol, int decimal) {
    if (symbol.toUpperCase() == 'EUR') {
      return MoneyFormatterSettings(
        symbol: '€',
        thousandSeparator: '.',
        decimalSeparator: ',',
        symbolAndNumberSeparator: ' ',
        fractionDigits: decimal,
        compactFormatType: CompactFormatType.short,
      );
    } else {
      return MoneyFormatterSettings(
        symbol: symbol.toUpperCase(),
        thousandSeparator: '.',
        decimalSeparator: ',',
        symbolAndNumberSeparator: ' ',
        fractionDigits: decimal,
        compactFormatType: CompactFormatType.short,
      );
    }
  }
}
