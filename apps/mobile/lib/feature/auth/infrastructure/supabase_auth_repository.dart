import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Esqueleto de la impl real (Supabase). El backend se cablea en un sprint
/// posterior; por ahora responde `AuthUnavailable` para no romper el contrato.
class SupabaseAuthRepository implements AuthRepository {
  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> sessionChanges() => const Stream.empty();

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async =>
      left(const GlobalFailure.server(AuthFailure.authUnavailable()));

  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  }) async =>
      left(const GlobalFailure.server(AuthFailure.authUnavailable()));

  @override
  Future<void> activate(AuthSession session) async {
    // TODO(backend): la sesión real la entrega Supabase Auth.
  }

  @override
  FutureResult<AuthFailure, Unit> signOut() async => right(unit);
}
