import 'package:fa_bank/api/api_auth_provider.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';

class ApiRepository {
  final ApiAuthProvider _apiAuthProvider = ApiAuthProvider();

  Future<Token> postLoginUser(LoginBody loginBody) => _apiAuthProvider.loginUser(loginBody);

  Future<Token> postRefreshAuth(RefreshTokenBody refreshTokenBody) => _apiAuthProvider.refreshAuth(refreshTokenBody);
}
