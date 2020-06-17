import 'dart:ui';

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

  static MoneyFormatterSettings getMoneySetting(String symbol, int decimal) {
    if (symbol.toUpperCase() == 'EUR') {
      return MoneyFormatterSettings(
        symbol: '€',
        thousandSeparator: ' ',
        decimalSeparator: ',',
        symbolAndNumberSeparator: ' ',
        fractionDigits: decimal,
        compactFormatType: CompactFormatType.short,
      );
    } else {
      return MoneyFormatterSettings(
        symbol: symbol.toUpperCase(),
        thousandSeparator: ' ',
        decimalSeparator: ',',
        symbolAndNumberSeparator: ' ',
        fractionDigits: decimal,
        compactFormatType: CompactFormatType.short,
      );
    }

  }
}