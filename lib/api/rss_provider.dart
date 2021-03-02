import 'package:dio/dio.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/utils/dio_logging_interceptors.dart';
import 'package:fa_bank/utils/preferences_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:webfeed/webfeed.dart';

final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

class RssProvider {
  final Dio _dio = Dio();

  RssProvider() {
    _dio.options.baseUrl = "https://is.fi/";
    _dio.interceptors.add(DioLoggingInterceptors(_dio));
  }

  Future<RssFeed> getRSs() async {
    try {
      final response = await _dio.get("rss/taloussanomat.xml");
      if (response.statusCode == 200) {
        return RssFeed.parse(response.data);
      }
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
    }
    return null;
  }

  void _printError(error, StackTrace stacktrace) {
    debugPrint('error: $error & stacktrace: $stacktrace');
  }
}
