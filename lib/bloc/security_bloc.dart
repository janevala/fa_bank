
import 'dart:convert';

import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/mutation/mutation_data.dart';
import 'package:fa_bank/podo/mutation/mutation_response.dart';
import 'package:fa_bank/podo/refreshtoken/refresh_token_body.dart';
import 'package:fa_bank/podo/security/security_body.dart';
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

class SecurityQuerySuccess extends SecurityState {
  final SecurityBody securityBody;

  SecurityQuerySuccess(this.securityBody);
}

class SecurityMutationSuccess extends SecurityState {
  final SecurityBody securityBody;

  SecurityMutationSuccess(this.securityBody);
}

class SecurityCache extends SecurityState {
  final SecurityBody securityBody;

  SecurityCache(this.securityBody);
}

class SecurityEvent extends SecurityState {
  final MutationData mutationData;

  SecurityEvent(this.mutationData);
}

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  final ApiRepository apiRepository = ApiRepository();
  final SharedPreferencesManager sharedPreferencesManager = locator<SharedPreferencesManager>();

  @override
  SecurityState get initialState => SecurityInitial();

  @override
  Stream<SecurityState> mapEventToState(SecurityEvent event) async* {
    bool expired = true;
    if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.keyAuthMSecs)) {
      int wasThen = sharedPreferencesManager.getInt(SharedPreferencesManager.keyAuthMSecs);
      int isNow = DateTime.now().millisecondsSinceEpoch;
      int elapsed = isNow - wasThen;
      if (elapsed < 50000) { // auth token expiry 60000
        expired = false;
      }
    }

    yield SecurityLoading();

    Token token;
    if (expired) {
      String refreshToken = sharedPreferencesManager.getString(SharedPreferencesManager.keyRefreshToken);
      RefreshTokenBody refreshTokenBody = RefreshTokenBody('refresh_token', refreshToken);
      token = await apiRepository.postRefreshAuth(refreshTokenBody);
      if (token.error != null) {
        yield SecurityFailure(token.error);
        return;
      }

      await sharedPreferencesManager.putString(SharedPreferencesManager.keyAccessToken, token.accessToken);
      await sharedPreferencesManager.putString(SharedPreferencesManager.keyRefreshToken, token.refreshToken);
      await sharedPreferencesManager.putBool(SharedPreferencesManager.keyIsLogin, true);
      await sharedPreferencesManager.putInt(SharedPreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    }

    SecurityBody securityBody;
    if (event.mutationData == null) { //we do query
        String securityCode  = sharedPreferencesManager.getString(SharedPreferencesManager.securityCode);
        if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.securityBody + securityCode)) {
          var securityString = sharedPreferencesManager.getString(SharedPreferencesManager.securityBody + securityCode);
          securityBody = SecurityBody.fromJson(jsonDecode(securityString));
          yield SecurityCache(securityBody);
        }

        String accessToken = token == null ? sharedPreferencesManager.getString(SharedPreferencesManager.keyAccessToken) : token.accessToken;
        securityBody = await apiRepository.postSecurityQuery(accessToken, securityCode);
        if (securityBody.error != null) {
          yield SecurityFailure(securityBody.error);
          return;
        }

        await sharedPreferencesManager.putString(SharedPreferencesManager.securityBody + securityCode, jsonEncode(securityBody.toJson()));

        yield SecurityQuerySuccess(securityBody);

    } else { //do mutation
      String accessToken = token == null ? sharedPreferencesManager.getString(SharedPreferencesManager.keyAccessToken) : token.accessToken;
      MutationResponse mutationResponse = await apiRepository.postSecurityMutation(accessToken, event.mutationData);
      if (mutationResponse.error != null) {
        yield SecurityFailure(mutationResponse.error);
        return;
      }

      if (securityBody == null) {
        String securityCode  = sharedPreferencesManager.getString(SharedPreferencesManager.securityCode);
        if (sharedPreferencesManager.isKeyExists(SharedPreferencesManager.securityBody + securityCode)) {
          var securityString = sharedPreferencesManager.getString(SharedPreferencesManager.securityBody + securityCode);
          securityBody = SecurityBody.fromJson(jsonDecode(securityString));
          yield SecurityMutationSuccess(securityBody);
        }
      }
    }
  }
}