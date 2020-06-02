
import 'package:fa_bank/api/api_repository.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Security" as in financial nomenclature, not data or information security.
///
/// "Security" is a fungible, negotiable financial instrument that holds some type of monetary value.

abstract class SecurityState {}

class SecurityInitial extends SecurityState {}

class SecurityLoading extends SecurityState {}

class SecurityFailure extends SecurityState {
  final String error;

  SecurityFailure(this.error);
}

class SecuritySuccess extends SecurityState {
}

class SecurityEvent extends SecurityState {
  final RefreshTokenBody refreshTokenBody;

  SecurityEvent(this.refreshTokenBody);
}

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final ApiRepository apiRepository = ApiRepository();
  final SharedPreferencesManager sharedPreferencesManager = locator<SharedPreferencesManager>();

  @override
  SecurityState get initialState => SecurityInitial();

  @override
  Stream<SecurityState> mapEventToState(SecurityEvent event) async* {
    if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs)) {
      int wasThen = sharedPreferencesManager.getInt(SharedPreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        yield SecuritySuccess();
        return;
      }
    }

    yield SecurityLoading();
    RefreshTokenBody refreshTokenBody = event.refreshTokenBody;
    Token token = await apiRepository.postRefreshAuth(refreshTokenBody);
    if (token.error != null) {
      yield SecurityFailure(token.error);
      return;
    }

    await sharedPreferencesManager.putString(SharedPreferencesManager.keyAccessToken, token.accessToken);
    await sharedPreferencesManager.putString(SharedPreferencesManager.keyRefreshToken, token.refreshToken);
    await sharedPreferencesManager.putBool(SharedPreferencesManager.keyIsLogin, true);
    await sharedPreferencesManager.putInt(SharedPreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);

    yield SecuritySuccess();
  }
}