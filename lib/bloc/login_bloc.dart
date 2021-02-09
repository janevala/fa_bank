import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/podo/login/login_body.dart';
import 'package:fa_bank/podo/token/token.dart';
import 'package:fa_bank/utils/preferences_manager.dart';

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
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

  LoginBloc(LoginState initialState) : super(initialState);

  @override
  LoginState get _initialState => LoginInitial();

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
    Token token = await ApiRepository().postLoginUser(loginBody);
    if (token.error != null) {
      yield LoginFailure(token.error);
      return;
    }
    await _sharedPreferencesManager.putString(PreferencesManager.keyAccessToken, token.accessToken);
    await _sharedPreferencesManager.putString(PreferencesManager.keyRefreshToken, token.refreshToken);
    await _sharedPreferencesManager.putBool(PreferencesManager.keyIsLogin, true);
    await _sharedPreferencesManager.putInt(PreferencesManager.keyAuthMSecs, DateTime.now().millisecondsSinceEpoch);
    await _sharedPreferencesManager.putString(PreferencesManager.keyPortfolioUserName, loginBody.username);
    yield LoginSuccess();
  }
}