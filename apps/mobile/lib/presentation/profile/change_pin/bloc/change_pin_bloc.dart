import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../feature/auth/domain/pin_rules.dart';
import '../../../../feature/security/application/security_actions.dart';
import '../../../../feature/security/domain/security_failure.dart';

part 'change_pin_bloc.freezed.dart';
part 'change_pin_event.dart';
part 'change_pin_state.dart';

/// Cambiar el PIN con sesión abierta: actual → nuevo → confirmar, sobre la
/// misma ruta y sin botón (el sexto dígito avanza), como `ResetPinBloc`.
///
/// El PIN actual se verifica en el servidor AL FINAL, en la misma llamada que
/// fija el nuevo: un endpoint que solo verifique sería un oráculo.
///
/// Sin red el resultado es DESCONOCIDO: no se reintenta solo, porque si el
/// cambio sí ocurrió, reintentar con el PIN "actual" viejo fallaría y sumaría
/// un intento al bloqueo.
class ChangePinBloc extends Bloc<ChangePinEvent, ChangePinState> {
  ChangePinBloc(this._actions) : super(const ChangePinState()) {
    on<ChangePinDigitPressed>(_onDigit);
    on<ChangePinBackspace>((event, emit) {
      if (_locked ||
          state.status != ChangePinStatus.idle ||
          state.pin.isEmpty) {
        return;
      }
      emit(
        state.copyWith(
          pin: state.pin.substring(0, state.pin.length - 1),
          error: null,
        ),
      );
    });
    on<ChangePinBack>(_onBack);
  }

  final SecurityActions _actions;

  /// Tras el bloqueo el estado es terminal: el servidor ya cerró la sesión y
  /// el teclado no debe reenviar nada contra la cuenta bloqueada.
  bool get _locked => state.lockedUntil != null;

  Future<void> _onDigit(
    ChangePinDigitPressed event,
    Emitter<ChangePinState> emit,
  ) async {
    if (_locked ||
        state.status != ChangePinStatus.idle ||
        state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, error: null));
    if (pin.length < 6) return;

    switch (state.step) {
      case ChangePinStep.actual:
        emit(
          state.copyWith(step: ChangePinStep.nuevo, currentPin: pin, pin: ''),
        );
      case ChangePinStep.nuevo:
        if (!PinRules.isValid(pin)) {
          emit(state.copyWith(pin: '', error: ChangePinError.weakPin));
        } else if (pin == state.currentPin) {
          emit(state.copyWith(pin: '', error: ChangePinError.samePin));
        } else {
          emit(
            state.copyWith(step: ChangePinStep.confirmar, newPin: pin, pin: ''),
          );
        }
      case ChangePinStep.confirmar:
        await _confirm(pin, emit);
    }
  }

  Future<void> _confirm(String pin, Emitter<ChangePinState> emit) async {
    if (pin != state.newPin) {
      emit(
        state.copyWith(
          step: ChangePinStep.nuevo,
          pin: '',
          newPin: '',
          error: ChangePinError.mismatch,
        ),
      );
      return;
    }
    emit(state.copyWith(status: ChangePinStatus.submitting));
    final result = await _actions.changePin(
      current: state.currentPin,
      nuevo: pin,
    );
    emit(
      result.match(
        (failure) => switch (failure) {
          ServerFailure(failure: SecurityWrongPin(:final attemptsLeft)) =>
            ChangePinState(
              error: ChangePinError.wrongPin,
              attemptsLeft: attemptsLeft,
            ),
          ServerFailure(failure: SecurityLocked(:final until)) =>
            state.copyWith(
              status: ChangePinStatus.idle,
              pin: '',
              currentPin: '',
              newPin: '',
              lockedUntil: until,
            ),
          ServerFailure(failure: SecurityWeakPin()) => state.copyWith(
            status: ChangePinStatus.idle,
            step: ChangePinStep.nuevo,
            pin: '',
            newPin: '',
            error: ChangePinError.weakPin,
          ),
          ServerFailure(failure: SecurityPinUnchanged()) => state.copyWith(
            status: ChangePinStatus.idle,
            step: ChangePinStep.nuevo,
            pin: '',
            newPin: '',
            error: ChangePinError.samePin,
          ),
          ServerFailure(failure: SecurityNetworkFailure()) => state.copyWith(
            status: ChangePinStatus.idle,
            pin: '',
            error: ChangePinError.unknownOutcome,
          ),
          _ => state.copyWith(
            status: ChangePinStatus.idle,
            pin: '',
            error: ChangePinError.generic,
          ),
        },
        (revocadas) => state.copyWith(
          status: ChangePinStatus.done,
          revokedSessions: revocadas,
        ),
      ),
    );
  }

  void _onBack(ChangePinBack event, Emitter<ChangePinState> emit) {
    if (_locked || state.status != ChangePinStatus.idle) return;
    switch (state.step) {
      case ChangePinStep.actual:
        return;
      case ChangePinStep.nuevo:
        emit(const ChangePinState());
      case ChangePinStep.confirmar:
        emit(
          state.copyWith(
            step: ChangePinStep.nuevo,
            pin: '',
            newPin: '',
            error: null,
          ),
        );
    }
  }
}
