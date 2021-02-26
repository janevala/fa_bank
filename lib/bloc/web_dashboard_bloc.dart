import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/preferences_manager.dart';

abstract class WebDashboardState {}

class WebDashboardInitial extends WebDashboardState {}

class WebDashboardLoading extends WebDashboardState {}

class WebDashboardFailure extends WebDashboardState {
  final String error;

  WebDashboardFailure(this.error);
}

class WebDashboardSuccess extends WebDashboardState {
  final PortfolioBody portfolioBody;

  WebDashboardSuccess(this.portfolioBody);
}

class WebDashboardCache extends WebDashboardState {
  final PortfolioBody portfolioBody;

  WebDashboardCache(this.portfolioBody);
}

class WebDashboardEvent extends WebDashboardState {
}

class WebDashboardBloc extends Bloc<WebDashboardEvent, WebDashboardState> {
  final ApiRepository _apiRepository = ApiRepository();
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

  WebDashboardBloc(WebDashboardState initialState) : super(initialState);

  @override
  WebDashboardState get _initialState => WebDashboardInitial();

  @override
  Stream<WebDashboardState> mapEventToState(WebDashboardEvent event) async* {
    bool expired = true;
    if (_sharedPreferencesManager.isKeyExists(PreferencesManager.keyAuthMSecs)) {
      int wasThen = _sharedPreferencesManager.getInt(PreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        expired = false;
      }
    }

    yield WebDashboardLoading();

    if (_sharedPreferencesManager.isKeyExists(PreferencesManager.keyPortfolioBody)) {
      var portfolioString = _sharedPreferencesManager.getString(PreferencesManager.keyPortfolioBody);
      PortfolioBody p = PortfolioBody.fromJson(jsonDecode(portfolioString));
      yield WebDashboardCache(p);
    }

    Token token;
    if (expired) {
      String refreshToken = _sharedPreferencesManager.getString(PreferencesManager.keyRefreshToken);
      RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
      token = await _apiRepository.postRefreshAuth(refreshTokenBody);
      if (token.error != null) {
        yield WebDashboardFailure(token.error);
        return;
      }

      await _sharedPreferencesManager.putString(PreferencesManager.keyAccessToken, token.accessToken);
      await _sharedPreferencesManager.putString(PreferencesManager.keyRefreshToken, token.refreshToken);
      await _sharedPreferencesManager.putBool(PreferencesManager.keyIsLogin, true);
      await _sharedPreferencesManager.putInt(PreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    }

    if (_sharedPreferencesManager.isKeyExists(PreferencesManager.keyPortfolioId)) {
      int userId  = _sharedPreferencesManager.getInt(PreferencesManager.keyPortfolioId);
      String accessToken = token == null ? _sharedPreferencesManager.getString(PreferencesManager.keyAccessToken) : token.accessToken;
      PortfolioBody portfolioBody = await _apiRepository.postPortfolioQuery(accessToken, userId);
      if (portfolioBody.error != null) {
        yield WebDashboardFailure(portfolioBody.error);
        return;
      }

      await _sharedPreferencesManager.putString(PreferencesManager.keyPortfolioBody, jsonEncode(portfolioBody.toJson()));

      yield WebDashboardSuccess(portfolioBody);
    } else {
      yield WebDashboardFailure('Error');
    }
  }
}