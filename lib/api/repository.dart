import 'package:fa_bank/api/api_provider.dart';
import 'package:fa_bank/podo/mutation/mutation_data.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/mutation/mutation_response.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/security/security_body.dart';
import 'package:fa_bank/podo/token/token.dart';

class ApiRepository {
  final ApiProvider _apiAuthProvider = ApiProvider();

  Future<PortfolioBody> postPortfolioQuery(String authCookie, int uid) => _apiAuthProvider.postPortfolioQuery(authCookie, uid);

  Future<SecurityBody> postSecurityQuery(String authCookie, String securityCode) => _apiAuthProvider.postSecurityQuery(authCookie, securityCode);

  Future<MutationResponse> postSecurityMutation(String authCookie, MutationData mutationData) => _apiAuthProvider.postSecurityMutation(authCookie, mutationData);

  Future<Token> postLoginUser(LoginBody loginBody) => _apiAuthProvider.loginUser(loginBody);

  Future<Token> postRefreshAuth(RefreshTokenBody refreshTokenBody) => _apiAuthProvider.refreshAuth(refreshTokenBody);
}
