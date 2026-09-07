import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_session.dart';
import '../../../feature/device/application/device_actions.dart';
import '../../../feature/device/domain/lockout_policy.dart';
import '../../../feature/device/domain/remembered_user.dart';

part 'quick_access_bloc.freezed.dart';
part 'quick_access_event.dart';
part 'quick_access_state.dart';

/// Acceso rápido: verifica el PIN del usuario recordado vía `AuthActions.signIn`
/// y gestiona intentos/bloqueo vía `DeviceActions`. En éxito no navega: la
/// sesión emitida llega al AuthBloc → gate → home. Al bloquear, expone
/// `lockedUntil` (la pantalla escucha y navega a /bloqueado).
class QuickAccessBloc extends Bloc<QuickAccessEvent, QuickAccessState> {
  QuickAccessBloc({
    required AuthActions auth,
    required DeviceActions device,
    required RememberedUser user,
    DateTime Function()? clock,
  })  : _auth = auth,
        _device = device,
        _now = clock ?? DateTime.now,
        super(QuickAccessState(user: user)) {
    on<QuickAccessDigitPressed>(_onDigit);
    on<QuickAccessBackspace>((event, emit) {
      if (state.pin.isNotEmpty && state.status == QuickAccessStatus.idle) {
        emit(state.copyWith(
            pin: state.pin.substring(0, state.pin.length - 1), lastWrong: false));
      }
    });
    on<QuickAccessBiometric>(_onBiometric);
  }

  final AuthActions _auth;
  final DeviceActions _device;
  final DateTime Function() _now;

  Future<void> _onDigit(
    QuickAccessDigitPressed event,
    Emitter<QuickAccessState> emit,
  ) async {
    if (state.status == QuickAccessStatus.verifying || state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, lastWrong: false));
    if (pin.length < 6) return;

    emit(state.copyWith(status: QuickAccessStatus.verifying));
    final result = await _auth.signIn(identifier: state.user.dni, pin: pin);
    await result.match(
      (failure) async {
        final lockout = await _device.registerFailedAttempt(_now());
        if (lockout.isLocked(_now())) {
          emit(state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lockedUntil: lockout.lockedUntil));
        } else {
          emit(state.copyWith(
            status: QuickAccessStatus.idle,
            pin: '',
            lastWrong: true,
            attemptsLeft: LockoutPolicy.maxAttempts - lockout.failedAttempts,
          ));
        }
      },
      (_) async {
        await _device.resetLockout();
      }, // éxito → sesión por el stream → home
    );
  }

  Future<void> _onBiometric(
    QuickAccessBiometric event,
    Emitter<QuickAccessState> emit,
  ) async {
    // Biometría simulada: éxito inmediato → activa la sesión del recordado.
    await _device.resetLockout();
    await _auth.activate(AuthSession(
      userId: 'mem-${state.user.dni.hashCode}',
      identifier: state.user.dni,
      alias: state.user.alias,
      fullName: state.user.fullName,
    ));
  }
}
