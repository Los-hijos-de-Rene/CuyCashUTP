import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../../feature/device/application/device_actions.dart';
import '../../../feature/lockout/domain/lockout_policy.dart';
import '../../../feature/device/domain/remembered_user.dart';
import '../../../feature/security/application/biometric_sign_in_use_case.dart';

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
    required BiometricSignInUseCase biometric,
    required RememberedUser user,
    DateTime Function()? clock,
  }) : _auth = auth,
       _biometric = biometric,
       _device = device,
       _now = clock ?? DateTime.now,
       super(QuickAccessState(user: user)) {
    on<QuickAccessDigitPressed>(_onDigit);
    on<QuickAccessBackspace>((event, emit) {
      if (state.pin.isNotEmpty && state.status == QuickAccessStatus.idle) {
        emit(
          state.copyWith(
            pin: state.pin.substring(0, state.pin.length - 1),
            lastWrong: false,
          ),
        );
      }
    });
    on<QuickAccessStarted>(_onStarted);
    on<QuickAccessBiometric>(_onBiometric);
  }

  final AuthActions _auth;
  final DeviceActions _device;
  final BiometricSignInUseCase _biometric;
  final DateTime Function() _now;

  Future<void> _onDigit(
    QuickAccessDigitPressed event,
    Emitter<QuickAccessState> emit,
  ) async {
    if (state.status == QuickAccessStatus.verifying || state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(
      state.copyWith(
        pin: pin,
        lastWrong: false,
        biometricFailed: false,
        unavailable: false,
      ),
    );
    if (pin.length < 6) return;

    emit(state.copyWith(status: QuickAccessStatus.verifying));
    final result = await _auth.signIn(identifier: state.user.dni, pin: pin);
    await result.match(
      (failure) async {
        if (failure case ServerFailure(failure: DeviceVerificationRequired())) {
          // El PIN fue correcto: no es un intento fallido. Falta verificar el
          // teléfono, y eso lo hace el login con su OTP.
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              needsDeviceVerification: true,
            ),
          );
          return;
        }
        // Con backend, el contador y el bloqueo los decide ÉL (por DNI), como
        // en el login: los fallos pudieron ser en otro teléfono.
        if (failure case ServerFailure(failure: AccessLocked(:final until))) {
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lockedUntil: until,
            ),
          );
          return;
        }
        if (failure
            case ServerFailure(failure: TooManyAttempts(:final attemptsLeft))) {
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lastWrong: true,
              attemptsLeft: attemptsLeft,
              // La duración del próximo bloqueo la sabe el servidor; no se
              // inventa una con el contador local.
              nextLockout: null,
            ),
          );
          return;
        }
        // Sin red o con el servidor caído el PIN no se llegó a comprobar: no
        // es un intento fallido. Antes contaba, y se podía quedar bloqueado
        // sin haberse equivocado.
        if (failure case ServerFailure(failure: InvalidCredentials())) {
          // Sigue: PIN errado sin conteo del servidor (flavor `mock`).
        } else {
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              unavailable: true,
            ),
          );
          return;
        }
        final lockout = await _device.registerFailedAttempt(_now());
        if (lockout.isLocked(_now())) {
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lockedUntil: lockout.lockedUntil,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lastWrong: true,
              attemptsLeft: LockoutPolicy.maxAttempts - lockout.failedAttempts,
              nextLockout: _device.policy.nextLockoutFor(lockout.level),
            ),
          );
        }
      },
      (_) async {
        await _device.resetLockout();
      }, // éxito → sesión por el stream → home
    );
  }

  Future<void> _onStarted(
    QuickAccessStarted event,
    Emitter<QuickAccessState> emit,
  ) async {
    emit(state.copyWith(biometricAvailable: await _biometric.canUse()));
  }

  Future<void> _onBiometric(
    QuickAccessBiometric event,
    Emitter<QuickAccessState> emit,
  ) async {
    if (state.status == QuickAccessStatus.verifying ||
        !state.biometricAvailable) {
      return;
    }
    emit(
      state.copyWith(
        status: QuickAccessStatus.verifying,
        lastWrong: false,
        biometricFailed: false,
      ),
    );
    final resultado = await _biometric(
      dni: state.user.dni,
      reason: event.reason,
    );
    switch (resultado) {
      case BiometricSignInSuccess():
        // La sesión llega por el stream → home.
        await _device.resetLockout();
        emit(state.copyWith(status: QuickAccessStatus.idle));
      case BiometricSignInCancelled():
        emit(state.copyWith(status: QuickAccessStatus.idle));
      case BiometricSignInFailed():
        // Antes volvía en silencio y parecía que el botón no hacía nada.
        emit(
          state.copyWith(status: QuickAccessStatus.idle, biometricFailed: true),
        );
      case BiometricSignInUnavailable():
        emit(
          state.copyWith(
            status: QuickAccessStatus.idle,
            biometricAvailable: false,
          ),
        );
      case BiometricSignInRevoked():
        emit(
          state.copyWith(
            status: QuickAccessStatus.idle,
            biometricAvailable: false,
            biometricRevoked: true,
          ),
        );
      case BiometricSignInLocked(:final until):
        // La pantalla ya navega a /bloqueado al ver lockedUntil.
        emit(
          state.copyWith(status: QuickAccessStatus.idle, lockedUntil: until),
        );
    }
  }
}
