import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/profile/application/profile_actions.dart';
import '../../../../feature/profile/domain/personal_data.dart';

part 'personal_data_bloc.freezed.dart';
part 'personal_data_event.dart';
part 'personal_data_state.dart';

/// Carga los datos del titular. `started` también sirve para reintentar.
class PersonalDataBloc extends Bloc<PersonalDataEvent, PersonalDataState> {
  PersonalDataBloc(this._actions) : super(const PersonalDataState()) {
    on<PersonalDataStarted>((event, emit) async {
      emit(const PersonalDataState());
      final result = await _actions.me();
      emit(
        result.match(
          (_) => const PersonalDataState(status: PersonalDataStatus.error),
          (datos) =>
              PersonalDataState(status: PersonalDataStatus.ready, datos: datos),
        ),
      );
    });
  }

  final ProfileActions _actions;
}
