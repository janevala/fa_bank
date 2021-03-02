import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/api_repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/utils/preferences_manager.dart';

abstract class KycState {}

class KycInitial extends KycState {}

class KycLoading extends KycState {}

class KycFailure extends KycState {
  final String error;

  KycFailure(this.error);
}

class KycSuccess extends KycState {
}

class KycCache extends KycState {
}

class KycEvent extends KycState {
}

class KycBloc extends Bloc<KycEvent, KycState> {
  final ApiRepository _apiRepository = ApiRepository();
  final PreferencesManager _sharedPreferencesManager = locator<PreferencesManager>();

  KycBloc(KycState initialState) : super(initialState);

  @override
  KycState get _initialState => KycInitial();

  @override
  Stream<KycState> mapEventToState(KycEvent event) async* {
      yield KycSuccess();
  }
}