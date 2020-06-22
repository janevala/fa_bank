import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fa_bank/api/graphql.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/mutation_data.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/security/security_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/dio_logging_interceptors.dart';
import 'package:flutter/cupertino.dart';

class ApiProvider {
  final Dio _dio = new Dio();

  ApiProvider() {
    _dio.options.baseUrl = Constants.faBaseUrl;
    _dio.interceptors.add(DioLoggingInterceptors(_dio));
  }

  Future<PortfolioBody> postPortfolioQuery(String authCookie, int uid) async {
    try {
      final response = await _dio.post('graphql',
          data: getPortfolioQuery(uid),
          options: Options(
              contentType: "application/graphql",
              headers: {
                "Authorization": 'Bearer ' + authCookie,
              },
              followRedirects: false
          ));

      Map<String, dynamic> data = response.data;

      if (response.statusCode == 200) {
        if (data['errors'] != null) {
          String s = jsonEncode(data['errors']['message']);
          return PortfolioBody.withError(s);
        } else {
          return PortfolioBody.fromJson(data['data']);
        }
      } else {
        return PortfolioBody.withError('Network Error');
      }
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
      return PortfolioBody.withError('$error');
    }
  }

  Future<SecurityBody> postSecurityQuery(String authCookie, String securityCode) async {
    try {
      final response = await _dio.post('graphql',
          data: getSecurityQuery(securityCode),
          options: Options(
              contentType: "application/graphql",
              headers: {
                "Authorization": 'Bearer ' + authCookie,
              },
              followRedirects: false
          ));

      Map<String, dynamic> data = response.data;

      if (response.statusCode == 200) {
        if (data['errors'] != null) {
          String s = jsonEncode(data['errors']['message']);
          return SecurityBody.withError(s);
        } else {
          return SecurityBody.fromJson(data['data']);
        }
      } else {
        return SecurityBody.withError('Network Error');
      }
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
      return SecurityBody.withError('$error');
    }
  }

  Future<void> postTransactionMutation(String authCookie, MutationData m) async {
    try {
      final response = await _dio.post('graphql',
          data: getTransactionMutation(m.parentPortfolio, m.security, m.amount, m.price, m.currency, m.type, m.dateString),
          options: Options(
              contentType: "application/graphql",
              headers: {
                "Authorization": 'Bearer ' + authCookie,
              },
              followRedirects: false
          ));

      Map<String, dynamic> data = response.data;

      if (response.statusCode == 200) {
        bool resultOk = false;
        List<dynamic> list = data['data']['importTradeOrders'];
        for (var i = 0; i < list.length; i++) {
          Map<String, dynamic> v = list[i];
          if (v.containsKey( 'importStatus') && v.containsValue('OK')) {
            resultOk = true;
          }
        }

        if (resultOk) {

        }

        if (data['errors'] != null) {
          String s = jsonEncode(data['errors']['message']);
          return SecurityBody.withError(s);
        } else {
          return SecurityBody.fromJson(data['data']);
        }
      } else {
        return SecurityBody.withError('Network Error');
      }
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
      return SecurityBody.withError('$error');
    }
  }

  Future<Token> loginUser(LoginBody loginBody) async {
    try {
      final response = await _dio.post(
        'auth/realms/fa/protocol/openid-connect/token',
        data: loginBody.tokenString(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return Token.fromJson(response.data);
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
      return Token.withError('$error');
    }
  }

  Future<Token> refreshAuth(RefreshTokenBody refreshTokenBody) async {
    try {
      final response = await _dio.post(
        'auth/realms/fa/protocol/openid-connect/token',
        data: refreshTokenBody.tokenString(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return Token.fromJson(response.data);
    } catch (error, stacktrace) {
      _printError(error, stacktrace);
      return Token.withError('$error');
    }
  }

  void _printError(error, StackTrace stacktrace) {
    debugPrint('error: $error & stacktrace: $stacktrace');
  }
}
