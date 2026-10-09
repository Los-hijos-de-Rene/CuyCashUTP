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
    // El estado es global: sin esto, "Te quedan 2 intentos" seguía en
    // pantalla al volver al DNI y probar con otro.
    on<AuthFormReset>((event, emit) {
      if (state case AuthUnauthenticated(status: FormStatus.idle)) {
        emit(const AuthState.unauthenticated());
      }
    });
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
        // Con backend, el contador y el bloqueo los decide ÉL: llevarlos en el
        // teléfono permitiría ponerlos a cero reinstalando la app.
        if (failure case ServerFailure(failure: AccessLocked(:final until))) {
          emit(AuthState.unauthenticated(lockedUntil: until));
          return;
        }
        if (failure
            case ServerFailure(failure: TooManyAttempts(:final attemptsLeft))) {
          emit(AuthState.unauthenticated(
            error: AuthError.invalidCredentials,
            attemptsLeft: attemptsLeft,
          ));
          return;
        }

        final error = _errorFor(failure);
        // Solo el PIN equivocado cuenta como intento fallido; un error de red
        // no debe acercar al usuario al bloqueo.
        if (error != AuthError.invalidCredentials) {
          emit(AuthState.unauthenticated(error: error));
          return;
        }
        // Sin backend (flavor `mock`) el conteo sigue siendo local.
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
          // El teléfono RECUERDA este DNI, pero quien decide si es de confianza
          // es el servidor: puede no reconocerlo (reinstalación, desvinculado
          // desde otro teléfono, cuenta creada en otro). Antes el fallo de
          // `activate` se ignoraba y la pantalla quedaba en "Verificando tu
          // PIN" para siempre, también con otro DNI (el estado es global).
          final activated = await _actions.activate(session);
          activated.match(
            (failure) => emit(switch (failure) {
              ServerFailure(failure: DeviceVerificationRequired()) =>
                AuthState.unauthenticated(pendingDeviceSession: session),
              _ => AuthState.unauthenticated(error: _errorFor(failure)),
            }),
            // Adentro: la sesión llega por `sessionChanges`.
            (_) {},
          );
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
      // Nunca el DNI como nombre: si aún no llegó, vacío. Al activar, la
      // sesión trae el nombre y `AppRoot` lo guarda.
      fullName: session.fullName ?? '',
      alias: session.alias ?? '@${session.identifier}',
    ));
    await _actions.activate(session, otpTicket: event.otpTicket);
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
      ServerFailure(failure: TooManyAttempts()) => AuthError.invalidCredentials,
      _ => AuthError.generic,
    };
