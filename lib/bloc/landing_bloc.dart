import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/api_repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/utils/preferences_manager.dart';

abstract class LandingState {}

class LandingInitial extends LandingState {}

class LandingLoading extends LandingState {}

class LandingFailure extends LandingState {
  final String error;

  LandingFailure(this.error);
}

class LandingSuccess extends LandingState {
  LandingSuccess();
}

class LandingCache extends LandingState {
  LandingCache();
}

class LandingEvent extends LandingState {
}

class LandingBloc extends Bloc<LandingEvent, LandingState> {
  final ApiRepository _apiRepository = ApiRepository();
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

  LandingBloc(LandingState initialState) : super(initialState);

  @override
  LandingState get _initialState => LandingInitial();

  @override
  Stream<LandingState> mapEventToState(LandingEvent event) async* {
      yield LandingSuccess();
  }
}