import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/device/application/device_actions.dart';
import '../../../../feature/security/application/disable_biometric_use_case.dart';
import '../../../../feature/security/application/enable_biometric_use_case.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'biometric_settings_bloc.freezed.dart';
part 'biometric_settings_event.dart';
part 'biometric_settings_state.dart';

/// Encender o apagar la huella. "Encendida" es: hay credencial guardada en
/// este teléfono (el servidor la confirma la próxima vez que se use).
class BiometricSettingsBloc
    extends Bloc<BiometricSettingsEvent, BiometricSettingsState> {
  BiometricSettingsBloc({
    required EnableBiometricUseCase enable,
    required DisableBiometricUseCase disable,
    required DeviceActions device,
  }) : _enable = enable,
       _disable = disable,
       _device = device,
       super(const BiometricSettingsState()) {
    on<BiometricSettingsStarted>(_onStarted);
    on<BiometricSettingsEnableRequested>((event, emit) {
      if (_locked ||
          state.status != BiometricSettingsStatus.ready ||
          !state.available) {
        return;
      }
      emit(
        state.copyWith(
          status: BiometricSettingsStatus.askingPin,
          pin: '',
          error: null,
          justEnabled: false,
        ),
      );
    });
    on<BiometricSettingsPinDigit>(_onDigit);
    on<BiometricSettingsPinBackspace>((event, emit) {
      if (_locked ||
          state.status != BiometricSettingsStatus.askingPin ||
          state.pin.isEmpty) {
        return;
      }
      emit(state.copyWith(pin: state.pin.substring(0, state.pin.length - 1)));
    });
    on<BiometricSettingsPinCancelled>((event, emit) {
      if (_locked) return;
      emit(
        state.copyWith(
          status: BiometricSettingsStatus.ready,
          pin: '',
          error: null,
        ),
      );
    });
    on<BiometricSettingsDisableRequested>(_onDisable);
  }

  final EnableBiometricUseCase _enable;
  final DisableBiometricUseCase _disable;
  final DeviceActions _device;

  /// Tras el bloqueo el estado es terminal: el servidor ya cerró la sesión.
  bool get _locked => state.lockedUntil != null;

  Future<void> _onStarted(
    BiometricSettingsStarted event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    final available = await _enable.isAvailable();
    final enabled = await _device.readBiometricCredential() != null;
    emit(
      BiometricSettingsState(
        status: BiometricSettingsStatus.ready,
        available: available,
        enabled: enabled,
      ),
    );
  }

  Future<void> _onDigit(
    BiometricSettingsPinDigit event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    if (_locked ||
        state.status != BiometricSettingsStatus.askingPin ||
        state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, error: null));
    if (pin.length < 6) return;

    emit(state.copyWith(status: BiometricSettingsStatus.working));
    final result = await _enable(pin: pin, reason: event.reason);
    emit(
      result.match(
        (failure) => switch (failure) {
          ServerFailure(failure: SecurityWrongPin(:final attemptsLeft)) =>
            state.copyWith(
              status: BiometricSettingsStatus.askingPin,
              pin: '',
              error: BiometricSettingsError.wrongPin,
              attemptsLeft: attemptsLeft,
            ),
          ServerFailure(failure: SecurityLocked(:final until)) =>
            state.copyWith(lockedUntil: until),
          ServerFailure(failure: SecurityBiometricUnavailable()) =>
            state.copyWith(
              status: BiometricSettingsStatus.ready,
              pin: '',
              available: false,
              error: BiometricSettingsError.unavailable,
            ),
          _ => state.copyWith(
            status: BiometricSettingsStatus.ready,
            pin: '',
            error: BiometricSettingsError.generic,
          ),
        },
        (activada) => state.copyWith(
          status: BiometricSettingsStatus.ready,
          pin: '',
          enabled: activada,
          justEnabled: activada,
        ),
      ),
    );
  }

  Future<void> _onDisable(
    BiometricSettingsDisableRequested event,
    Emitter<BiometricSettingsState> emit,
  ) async {
    if (_locked || state.status != BiometricSettingsStatus.ready) return;
    emit(state.copyWith(status: BiometricSettingsStatus.working));
    await _disable();
    emit(
      state.copyWith(
        status: BiometricSettingsStatus.ready,
        enabled: false,
        justEnabled: false,
      ),
    );
  }
}
