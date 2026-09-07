import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../../feature/auth/domain/auth_session.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc de auth. Consume `AuthActions` por constructor — nunca el repo directo.
/// Estado inicial sincrónico desde `currentSession`; se mueve con el stream. En
/// éxito de login/register NO emite directo: la sesión llega por el stream →
/// `AuthAuthenticated`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthActions actions)
      : _actions = actions,
        super(_resolve(actions.currentSession)) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthSignedOut>((event, emit) => _actions.signOut());
    on<_AuthSessionChanged>((event, emit) => emit(_resolve(event.session)));
    _sub = _actions.sessionChanges().listen(
          (session) => add(AuthEvent.sessionChanged(session)),
        );
  }

  final AuthActions _actions;
  late final StreamSubscription<AuthSession?> _sub;

  static AuthState _resolve(AuthSession? session) => session == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(session);

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated(status: FormStatus.submitting));
    final result =
        await _actions.signIn(identifier: event.identifier, pin: event.pin);
    result.match(
      (failure) => emit(AuthState.unauthenticated(error: _errorFor(failure))),
      (_) {}, // éxito → sessionChanged por el stream
    );
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
      _ => AuthError.generic,
    };
