import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';

part 'reset_pin_bloc.freezed.dart';
part 'reset_pin_event.dart';
part 'reset_pin_state.dart';

/// Restablecimiento del PIN tras verificar el código. Consume `AuthActions`
/// por constructor.
///
/// Dos pasos secuenciales, un campo a la vez, y SIN botón: el sexto dígito es
/// el commit, igual que al desbloquear el teléfono. Además de liberar espacio,
/// adelanta la validación — que el PIN elegido sea el actual se descubre al
/// terminar el paso 1, no después de escribir doce dígitos.
class ResetPinBloc extends Bloc<ResetPinEvent, ResetPinState> {
  ResetPinBloc({required AuthActions actions, required String identifier})
      : _actions = actions,
        _identifier = identifier,
        super(const ResetPinState()) {
    on<ResetPinDigitPressed>(_onDigit);
    on<ResetPinBackspace>(_onBackspace);
    on<ResetPinBackToFirstStep>(_onBackToFirstStep);
  }

  final AuthActions _actions;
  final String _identifier;

  Future<void> _onDigit(
    ResetPinDigitPressed event,
    Emitter<ResetPinState> emit,
  ) async {
    if (state.status == ResetPinStatus.submitting || state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, error: null));
    if (pin.length < 6) return;

    switch (state.step) {
      case ResetPinStep.crear:
        await _finishFirstStep(pin, emit);
      case ResetPinStep.confirmar:
        await _finishSecondStep(pin, emit);
    }
  }

  /// Cierra el paso 1: rechaza el PIN actual y, si sirve, pasa a confirmar.
  Future<void> _finishFirstStep(String pin, Emitter<ResetPinState> emit) async {
    emit(state.copyWith(status: ResetPinStatus.submitting));
    final result =
        await _actions.isCurrentPin(identifier: _identifier, pin: pin);
    emit(result.match(
      (failure) => state.copyWith(
        status: ResetPinStatus.idle,
        pin: '',
        error: _errorFor(failure),
      ),
      (isCurrent) => isCurrent
          // Casillas limpias y a elegir otro: seguir a confirmar un PIN que ya
          // se va a rechazar sería hacerle perder seis dígitos.
          ? state.copyWith(
              status: ResetPinStatus.idle,
              pin: '',
              error: ResetPinError.samePin,
            )
          : state.copyWith(
              status: ResetPinStatus.idle,
              step: ResetPinStep.confirmar,
              chosenPin: pin,
              pin: '',
            ),
    ));
  }

  /// Cierra el paso 2: confirma y guarda.
  Future<void> _finishSecondStep(
    String pin,
    Emitter<ResetPinState> emit,
  ) async {
    if (pin != state.chosenPin) {
      // Se limpian SOLO las casillas de este paso; el PIN elegido se conserva.
      emit(state.copyWith(pin: '', error: ResetPinError.mismatch));
      return;
    }

    emit(state.copyWith(status: ResetPinStatus.submitting));
    final result =
        await _actions.resetPin(identifier: _identifier, newPin: pin);
    emit(result.match(
      (failure) => state.copyWith(
        status: ResetPinStatus.idle,
        // El PIN se rechaza en el paso donde se elige: se vuelve al 1.
        step: ResetPinStep.crear,
        pin: '',
        chosenPin: '',
        error: _errorFor(failure),
      ),
      (_) => state.copyWith(status: ResetPinStatus.idle, done: true),
    ));
  }

  void _onBackspace(ResetPinBackspace event, Emitter<ResetPinState> emit) {
    if (state.status == ResetPinStatus.submitting || state.pin.isEmpty) return;
    emit(state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1), error: null));
  }

  void _onBackToFirstStep(
    ResetPinBackToFirstStep event,
    Emitter<ResetPinState> emit,
  ) {
    if (state.step == ResetPinStep.crear) return;
    emit(state.copyWith(
      step: ResetPinStep.crear,
      pin: '',
      chosenPin: '',
      error: null,
    ));
  }

  static ResetPinError _errorFor(GlobalFailure<AuthFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: PinUnchanged()) => ResetPinError.samePin,
        ServerFailure(failure: WeakPin()) => ResetPinError.weakPin,
        _ => ResetPinError.generic,
      };
}
