import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector/injector.dart';
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
  final ApiRepository apiRepository = ApiRepository();
  final SharedPreferencesManager sharedPreferencesManager = locator<SharedPreferencesManager>();

  @override
  DashboardState get initialState => DashboardInitial();

  @override
  Stream<DashboardState> mapEventToState(DashboardEvent event) async* {
    bool expired = true;
    if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs)) {
      int wasThen = sharedPreferencesManager.getInt(SharedPreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        expired = false;
      }
    }

    yield DashboardLoading();

    Token token;
    if (expired) {
      String refreshToken = sharedPreferencesManager.getString(SharedPreferencesManager.keyRefreshToken);
      RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
      token = await apiRepository.postRefreshAuth(refreshTokenBody);
      if (token.error != null) {
        yield DashboardFailure(token.error);
        return;
      }

      await sharedPreferencesManager.putString(SharedPreferencesManager.keyAccessToken, token.accessToken);
      await sharedPreferencesManager.putString(SharedPreferencesManager.keyRefreshToken, token.refreshToken);
      await sharedPreferencesManager.putBool(SharedPreferencesManager.keyIsLogin, true);
      await sharedPreferencesManager.putInt(SharedPreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    }

    if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.portfolioBody)) {
      var portfolioString = sharedPreferencesManager.getString(SharedPreferencesManager.portfolioBody);
      PortfolioBody p = PortfolioBody.fromJson(jsonDecode(portfolioString));
      yield DashboardCache(p);
    }

    if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyUid)) {
      int userId  = sharedPreferencesManager.getInt(SharedPreferencesManager.keyUid);
      String accessToken = token == null ? sharedPreferencesManager.getString(SharedPreferencesManager.keyAccessToken) : token.accessToken;
      PortfolioBody portfolioBody = await apiRepository.postPortfolioQuery(accessToken, userId);
      if (portfolioBody.error != null) {
        yield DashboardFailure(portfolioBody.error);
        return;
      }

      await sharedPreferencesManager.putString(SharedPreferencesManager.portfolioBody, jsonEncode(portfolioBody.toJson()));

      yield DashboardSuccess(portfolioBody);
    } else {
      yield DashboardFailure('Error');
    }
  }
}