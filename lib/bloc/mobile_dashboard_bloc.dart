import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/portfolio/portfolio_body.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/preferences_manager.dart';

abstract class MobileDashboardState {}

class MobileDashboardInitial extends MobileDashboardState {}

class MobileDashboardLoading extends MobileDashboardState {}

class MobileDashboardFailure extends MobileDashboardState {
  final String error;

  MobileDashboardFailure(this.error);
}

class MobileDashboardSuccess extends MobileDashboardState {
  final PortfolioBody portfolioBody;

  MobileDashboardSuccess(this.portfolioBody);
}

class MobileDashboardCache extends MobileDashboardState {
  final PortfolioBody portfolioBody;

  MobileDashboardCache(this.portfolioBody);
}

class MobileDashboardEvent extends MobileDashboardState {
}

class MobileDashboardBloc extends Bloc<MobileDashboardEvent, MobileDashboardState> {
  final ApiRepository _apiRepository = ApiRepository();
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

  MobileDashboardBloc(MobileDashboardState initialState) : super(initialState);

  @override
  MobileDashboardState get _initialState => MobileDashboardInitial();

  @override
  Stream<MobileDashboardState> mapEventToState(MobileDashboardEvent event) async* {
    bool expired = true;
    if (_sharedPreferencesManager.isKeyExists(PreferencesManager.keyAuthMSecs)) {
      int wasThen = _sharedPreferencesManager.getInt(PreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        expired = false;
      }
    }

    yield MobileDashboardLoading();

    if (_sharedPreferencesManager.isKeyExists(PreferencesManager.keyPortfolioBody)) {
      var portfolioString = _sharedPreferencesManager.getString(PreferencesManager.keyPortfolioBody);
      PortfolioBody p = PortfolioBody.fromJson(jsonDecode(portfolioString));
      yield MobileDashboardCache(p);
    }

    Token token;
    if (expired) {
      String refreshToken = _sharedPreferencesManager.getString(PreferencesManager.keyRefreshToken);
      RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
      token = await _apiRepository.postRefreshAuth(refreshTokenBody);
      if (token.error != null) {
        yield MobileDashboardFailure(token.error);
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
        yield MobileDashboardFailure(portfolioBody.error);
        return;
      }

      await _sharedPreferencesManager.putString(PreferencesManager.keyPortfolioBody, jsonEncode(portfolioBody.toJson()));

      yield MobileDashboardSuccess(portfolioBody);
    } else {
      yield MobileDashboardFailure('Error');
    }
  }
}