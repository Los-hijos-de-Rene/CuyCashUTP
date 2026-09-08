import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../../feature/auth/domain/auth_session.dart';
import '../../../feature/device/application/device_actions.dart';
import '../../../feature/lockout/application/identifier_lockout_actions.dart';
import '../../../feature/lockout/domain/lockout_policy.dart';
import '../../../feature/device/domain/remembered_user.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc de auth. Consume `AuthActions` y `DeviceActions` por constructor —
/// nunca los repos directos. Estado inicial sincrónico desde `currentSession`;
/// se mueve con el stream.
///
/// El login valida el PIN SIN iniciar sesión (`authenticate`): si el teléfono
/// no está vinculado a esa cuenta, la sesión queda pendiente en
/// `pendingDeviceSession` y la pantalla manda a verificar el dispositivo. Solo
/// tras el OTP se llama a `activate`.
///
/// El bloqueo por PIN fallido se lleva contra el DNI (`IdentifierLockoutActions`),
/// NO contra el teléfono: si se atara al dispositivo, bastaría con probar desde
/// otro para saltárselo. El bloqueo local del acceso rápido es otro contador,
/// con otro alcance (ver `DeviceActions`).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    AuthActions actions,
    DeviceActions device,
    IdentifierLockoutActions lockout, {
    DateTime Function()? clock,
  })  : _actions = actions,
        _device = device,
        _lockout = lockout,
        _now = clock ?? DateTime.now,
        super(_resolve(actions.currentSession)) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthDeviceVerified>(_onDeviceVerified);
    on<AuthSignedOut>((event, emit) => _actions.signOut());
    on<_AuthSessionChanged>((event, emit) => emit(_resolve(event.session)));
    _sub = _actions.sessionChanges().listen(
          (session) => add(AuthEvent.sessionChanged(session)),
        );
  }

  final AuthActions _actions;
  final DeviceActions _device;
  final IdentifierLockoutActions _lockout;
  final DateTime Function() _now;
  late final StreamSubscription<AuthSession?> _sub;

  static AuthState _resolve(AuthSession? session) => session == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(session);

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    // Bloqueo vigente sobre ESE DNI: ni se intenta. La pantalla va a
    // /bloqueado.
    final current = await _lockout.read(event.identifier);
    if (current.isLocked(_now())) {
      emit(AuthState.unauthenticated(lockedUntil: current.lockedUntil));
      return;
    }

    emit(const AuthState.unauthenticated(status: FormStatus.submitting));
    final result = await _actions.authenticate(
        identifier: event.identifier, pin: event.pin);
    await result.match(
      (failure) async {
        final error = _errorFor(failure);
        // Solo el PIN equivocado cuenta como intento fallido; un error de red
        // no debe acercar al usuario al bloqueo.
        if (error != AuthError.invalidCredentials) {
          emit(AuthState.unauthenticated(error: error));
          return;
        }
        final lockout =
            await _lockout.registerFailedAttempt(event.identifier, _now());
        emit(lockout.isLocked(_now())
            ? AuthState.unauthenticated(lockedUntil: lockout.lockedUntil)
            : AuthState.unauthenticated(
                error: error,
                attemptsLeft:
                    LockoutPolicy.maxAttempts - lockout.failedAttempts,
                nextLockout: _lockout.policy.nextLockoutFor(lockout.level),
              ));
      },
      (session) async {
        await _lockout.reset(event.identifier);
        final remembered = await _device.readUser();
        if (remembered?.dni == session.identifier) {
          // Teléfono ya vinculado → adentro (sessionChanged por el stream).
          await _actions.activate(session);
        } else {
          emit(AuthState.unauthenticated(pendingDeviceSession: session));
        }
      },
    );
  }

  /// El OTP del dispositivo salió bien: se vincula el teléfono y recién ahí se
  /// abre la sesión.
  Future<void> _onDeviceVerified(
    AuthDeviceVerified event,
    Emitter<AuthState> emit,
  ) async {
    final session = event.session;
    await _device.saveUser(RememberedUser(
      dni: session.identifier,
      fullName: session.fullName ?? session.identifier,
      alias: session.alias ?? '@${session.identifier}',
    ));
    await _actions.activate(session);
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

/// Mapea el `AuthFailure` a `AuthError` (sin texto; la UI lo traduce).
AuthError _errorFor(GlobalFailure<AuthFailure> failure) => switch (failure) {
      ServerFailure(failure: InvalidCredentials()) =>
        AuthError.invalidCredentials,
      ServerFailure(failure: IdentifierTaken()) => AuthError.identifierTaken,
      ServerFailure(failure: WeakPin()) => AuthError.weakPin,
      ServerFailure(failure: PinUnchanged()) => AuthError.pinUnchanged,
      _ => AuthError.generic,
    };
