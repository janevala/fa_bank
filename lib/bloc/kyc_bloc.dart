import 'package:bloc/bloc.dart';
import 'package:fa_bank/api/repository.dart';
import 'package:fa_bank/injector.dart';
import 'package:fa_bank/utils/shared_preferences_manager.dart';

abstract class KycState {}

class KycInitial extends KycState {}

class KycLoading extends KycState {}

class KycFailure extends KycState {
  final String error;

  KycFailure(this.error);
}

class KycSuccess extends KycState {
  KycSuccess();
}

class KycCache extends KycState {
  KycCache();
}

class KycEvent extends KycState {
}

class KycBloc extends Bloc<KycEvent, KycState> {
  final ApiRepository _apiRepository = ApiRepository();
  final SharedPreferencesManager _sharedPreferencesManager = locator<SharedPreferencesManager>();

  KycBloc(KycState initialState) : super(initialState);

  @override
  KycState get _initialState => KycInitial();

  @override
  Stream<KycState> mapEventToState(KycEvent event) async* {
      yield KycSuccess();
  }
}