import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Memory* FUNCIONAL de auth (backend del flavor `mock` + contrato de tests).
/// [validPin] (default '000000') es el PIN que se acepta.
class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({AuthSession? initial, this.validPin = '000000'})
      : _session = initial {
    if (initial != null) _registered.add(initial.identifier);
  }

  final String validPin;
  AuthSession? _session;
  final Set<String> _registered = {};
  final _controller = StreamController<AuthSession?>.broadcast();

  static final _pinFormat = RegExp(r'^\d{6}$');

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async {
    if (pin != validPin) {
      return left(const GlobalFailure.server(AuthFailure.invalidCredentials()));
    }
    final session =
        AuthSession(userId: 'mem-${identifier.hashCode}', identifier: identifier);
    _emit(session);
    return right(session);
  }

  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  }) async {
    if (!_pinFormat.hasMatch(pin)) {
      return left(const GlobalFailure.server(AuthFailure.weakPin()));
    }
    if (_registered.contains(dni)) {
      return left(const GlobalFailure.server(AuthFailure.identifierTaken()));
    }
    _registered.add(dni);
    // Crea la cuenta pero NO inicia sesión: la sesión se activa cuando el
    // usuario toca "Ir a mi cuenta" en la pantalla de éxito.
    return right(AuthSession(
      userId: 'mem-${dni.hashCode}',
      identifier: dni,
      alias: _aliasFor(nombres, dni),
      fullName: '${nombres.trim()} ${apellidos.trim()}'.trim(),
    ));
  }

  @override
  Future<void> activate(AuthSession session) async => _emit(session);

  @override
  FutureResult<AuthFailure, Unit> signOut() async {
    _session = null;
    _controller.add(null);
    return right(unit);
  }

  /// Alias mock derivado del primer nombre (ascii, minúsculas); si no queda
  /// nada usable, cae al DNI.
  static String _aliasFor(String nombres, String dni) {
    final first = nombres.trim().split(RegExp(r'\s+')).first.toLowerCase();
    final slug = first.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return slug.isEmpty ? '@$dni' : '@$slug';
  }

  void _emit(AuthSession session) {
    _session = session;
    _controller.add(session);
  }
}
