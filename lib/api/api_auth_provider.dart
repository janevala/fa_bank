import 'package:dio/dio.dart';
import 'package:fa_bank/constants.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/dio_logging_interceptors.dart';
import 'package:flutter/cupertino.dart';

class ApiAuthProvider {
  final Dio _dio = new Dio();

  ApiAuthProvider() {
    _dio.options.baseUrl = Constants.faBaseUrl;
    _dio.interceptors.add(DioLoggingInterceptors(_dio));
  }

  Future<Token> loginUser(LoginBody loginBody) async {
    try {
      final response = await _dio.post(
        'auth/realms/fa/protocol/openid-connect/token',
        data: loginBody.tokenString(),
        options: Options(
          contentType:Headers.formUrlEncodedContentType,
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
          contentType:Headers.formUrlEncodedContentType,
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
