import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector/injector.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure(this.error);
}

class LoginSuccess extends LoginState {
}

class LoginEvent extends LoginState {
  final LoginBody loginBody;

  LoginEvent(this.loginBody);
}

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final ApiRepository apiRepository = ApiRepository();
  final SharedPreferencesManager sharedPreferencesManager = locator<SharedPreferencesManager>();

  @override
  LoginState get initialState => LoginInitial();

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    LoginBody loginBody = event.loginBody;
    if (loginBody.username.isEmpty) {
      yield LoginFailure('Username is required');
      return;
    } else if (loginBody.password.isEmpty) {
      yield LoginFailure('Password is required');
      return;
    }
    yield LoginLoading();
    Token token = await apiRepository.postLoginUser(loginBody);
    if (token.error != null) {
      yield LoginFailure(token.error);
      return;
    }
    await sharedPreferencesManager.putString(SharedPreferencesManager.keyAccessToken, token.accessToken);
    await sharedPreferencesManager.putString(SharedPreferencesManager.keyRefreshToken, token.refreshToken);
    await sharedPreferencesManager.putBool(SharedPreferencesManager.keyIsLogin, true);
    await sharedPreferencesManager.putInt(SharedPreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    await sharedPreferencesManager.putString(SharedPreferencesManager.keyUsername, loginBody.username);
    await sharedPreferencesManager.putDouble(SharedPreferencesManager.keyUid, 10527024); //10527075
    yield LoginSuccess();
  }
}