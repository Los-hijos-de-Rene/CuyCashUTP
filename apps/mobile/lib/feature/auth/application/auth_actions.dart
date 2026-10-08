import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Agrupa las operaciones FINAS de auth (delegación directa sobre una sola
/// dependencia: el `AuthRepository`). El bloc la consume por constructor; nunca
/// toca el repo directo. Cuando una operación pase a orquestar 2+ dependencias,
/// sale a su propio `*_use_case.dart`.
class AuthActions {
  const AuthActions(this._repo);

  final AuthRepository _repo;

  AuthSession? get currentSession => _repo.currentSession;

  Stream<AuthSession?> sessionChanges() => _repo.sessionChanges();

  FutureResult<AuthFailure, AuthSession> authenticate({
    required String identifier,
    required String pin,
  }) =>
      _repo.authenticate(identifier: identifier, pin: pin);

  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) =>
      _repo.signIn(identifier: identifier, pin: pin);

  FutureResult<AuthFailure, bool> isCurrentPin({
    required String identifier,
    required String pin,
    String? otpTicket,
  }) =>
      _repo.isCurrentPin(
          identifier: identifier, pin: pin, otpTicket: otpTicket);

  FutureResult<AuthFailure, Unit> resetPin({
    required String identifier,
    required String newPin,
    String? otpTicket,
  }) =>
      _repo.resetPin(
          identifier: identifier, newPin: newPin, otpTicket: otpTicket);

  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
    String? kycTicket,
  }) =>
      _repo.register(
        dni: dni,
        nombres: nombres,
        apellidos: apellidos,
        email: email,
        pin: pin,
        kycTicket: kycTicket,
      );

  /// Activa (inicia sesión) una sesión creada por `register`.
  FutureResult<AuthFailure, Unit> activate(AuthSession session,
          {String? otpTicket}) =>
      _repo.activate(session, otpTicket: otpTicket);

  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  }) =>
      _repo.signInWithBiometric(dni: dni, credential: credential);

  FutureResult<AuthFailure, Unit> signOut() => _repo.signOut();
}
