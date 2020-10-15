import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardFailure extends DashboardState {
  final String error;

  DashboardFailure(this.error);
}

class DashboardSuccess extends DashboardState {
  final PortfolioBody portfolioBody;

  DashboardSuccess(this.portfolioBody);
}

class DashboardCache extends DashboardState {
  final PortfolioBody portfolioBody;

  DashboardCache(this.portfolioBody);
}

class DashboardEvent extends DashboardState {
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiRepository _apiRepository = ApiRepository();
  final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

  DashboardBloc(DashboardState initialState) : super(initialState);

  @override
  DashboardState get _initialState => DashboardInitial();

  @override
  Stream<DashboardState> mapEventToState(DashboardEvent event) async* {
    bool expired = true;
    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs)) {
      int wasThen = _sharedPreferencesManager.getInt(SharedPreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        expired = false;
      }
    }

    yield DashboardLoading();

    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyPortfolioBody)) {
      var portfolioString = _sharedPreferencesManager.getString(SharedPreferencesManager.keyPortfolioBody);
      PortfolioBody p = PortfolioBody.fromJson(jsonDecode(portfolioString));
      yield DashboardCache(p);
    }

    Token token;
    if (expired) {
      String refreshToken = _sharedPreferencesManager.getString(SharedPreferencesManager.keyRefreshToken);
      RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
      token = await _apiRepository.postRefreshAuth(refreshTokenBody);
      if (token.error != null) {
        yield DashboardFailure(token.error);
        return;
      }

      await _sharedPreferencesManager.putString(SharedPreferencesManager.keyAccessToken, token.accessToken);
      await _sharedPreferencesManager.putString(SharedPreferencesManager.keyRefreshToken, token.refreshToken);
      await _sharedPreferencesManager.putBool(SharedPreferencesManager.keyIsLogin, true);
      await _sharedPreferencesManager.putInt(SharedPreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    }

    if (_sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyPortfolioId)) {
      int userId  = _sharedPreferencesManager.getInt(SharedPreferencesManager.keyPortfolioId);
      String accessToken = token == null ? _sharedPreferencesManager.getString(SharedPreferencesManager.keyAccessToken) : token.accessToken;
      PortfolioBody portfolioBody = await _apiRepository.postPortfolioQuery(accessToken, userId);
      if (portfolioBody.error != null) {
        yield DashboardFailure(portfolioBody.error);
        return;
      }

      await _sharedPreferencesManager.putString(SharedPreferencesManager.keyPortfolioBody, jsonEncode(portfolioBody.toJson()));

      yield DashboardSuccess(portfolioBody);
    } else {
      yield DashboardFailure('Error');
    }
  }
}