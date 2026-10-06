import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/device/application/device_actions.dart';
import '../../../../feature/device/domain/remembered_user.dart';
import '../../../../feature/profile/application/profile_actions.dart';
import '../../../../feature/profile/domain/alias_rules.dart';
import '../../../../feature/profile/domain/profile_failure.dart';

part 'edit_alias_bloc.freezed.dart';
part 'edit_alias_event.dart';
part 'edit_alias_state.dart';

/// Edita el alias. Al guardar también actualiza el usuario recordado en este
/// teléfono, para que el saludo del inicio lo muestre sin volver a entrar.
class EditAliasBloc extends Bloc<EditAliasEvent, EditAliasState> {
  EditAliasBloc({
    required ProfileActions profile,
    required DeviceActions device,
    required String initial,
  })  : _profile = profile,
        _device = device,
        super(EditAliasState(
          initial: initial,
          input: initial.startsWith('@') ? initial.substring(1) : initial,
        )) {
    on<EditAliasChanged>((event, emit) =>
        emit(state.copyWith(input: event.input, error: null)));
    on<EditAliasSubmitted>(_onSubmitted);
  }

  final ProfileActions _profile;
  final DeviceActions _device;

  Future<void> _onSubmitted(
    EditAliasSubmitted event,
    Emitter<EditAliasState> emit,
  ) async {
    if (!state.canSave) return;
    emit(state.copyWith(status: EditAliasStatus.saving, error: null));
    final result = await _profile.updateAlias(state.normalized);
    await result.match(
      (failure) async => emit(state.copyWith(
        status: EditAliasStatus.editing,
        error: switch (failure) {
          ServerFailure(failure: ProfileInvalidAlias()) => AliasError.invalid,
          ServerFailure(failure: ProfileNetworkFailure()) => AliasError.network,
          _ => AliasError.generic,
        },
      )),
      (alias) async {
        final user = await _device.readUser();
        if (user != null) {
          await _device.saveUser(RememberedUser(
              dni: user.dni, fullName: user.fullName, alias: alias));
        }
        emit(state.copyWith(status: EditAliasStatus.saved));
      },
    );
  }
}
