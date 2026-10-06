import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/security/application/security_actions.dart';
import '../../../../feature/security/domain/linked_device.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'linked_devices_bloc.freezed.dart';
part 'linked_devices_event.dart';
part 'linked_devices_state.dart';

/// Lista y desvincula teléfonos. Que el dispositivo ya no exista (otro
/// teléfono lo sacó antes) es el resultado que el usuario quería: éxito.
class LinkedDevicesBloc extends Bloc<LinkedDevicesEvent, LinkedDevicesState> {
  LinkedDevicesBloc(this._actions) : super(const LinkedDevicesState()) {
    on<LinkedDevicesStarted>((event, emit) => _load(emit));
    on<LinkedDevicesUnlinkRequested>(_onUnlink);
  }

  final SecurityActions _actions;

  Future<void> _load(
    Emitter<LinkedDevicesState> emit, {
    DevicesMessage? message,
  }) async {
    final result = await _actions.devices();
    emit(
      result.match(
        (_) => state.copyWith(
          status: LinkedDevicesStatus.error,
          unlinking: null,
          message: message,
        ),
        (devices) => state.copyWith(
          status: LinkedDevicesStatus.ready,
          devices: devices,
          unlinking: null,
          message: message,
        ),
      ),
    );
  }

  Future<void> _onUnlink(
    LinkedDevicesUnlinkRequested event,
    Emitter<LinkedDevicesState> emit,
  ) async {
    if (state.unlinking != null) return;
    emit(state.copyWith(unlinking: event.id, message: null));
    final result = await _actions.unlinkDevice(event.id);
    final message = result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: SecurityDeviceNotFound()) =>
          DevicesMessage.unlinked,
        ServerFailure(failure: SecurityCannotUnlinkCurrent()) =>
          DevicesMessage.cannotUnlinkCurrent,
        _ => DevicesMessage.error,
      },
      (_) => DevicesMessage.unlinked,
    );
    await _load(emit, message: message);
  }
}
