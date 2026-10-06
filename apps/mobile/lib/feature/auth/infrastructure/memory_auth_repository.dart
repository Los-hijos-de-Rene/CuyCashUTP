import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Memory* FUNCIONAL de auth (backend del flavor `mock` + contrato de tests).
/// [validPin] (default '000000') es el PIN que se acepta.
class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({
    AuthSession? initial,
    String validPin = '000000',
    List<String> otherDeviceTokens = const [],
  })  : _session = initial,
        _validPin = validPin,
        _otherDeviceTokens = [...otherDeviceTokens] {
    if (initial != null) _registered.add(initial.identifier);
  }

  String _validPin;

  /// PIN aceptado por `signIn`. Cambia con `resetPin`.
  String get validPin => _validPin;

  /// Tokens simulados de OTROS dispositivos. `resetPin` los invalida: cambiar
  /// el PIN cierra las sesiones abiertas en el resto de teléfonos.
  final List<String> _otherDeviceTokens;
  List<String> get otherDeviceTokens => List.unmodifiable(_otherDeviceTokens);

  AuthSession? _session;
  final Set<String> _registered = {};
  final _controller = StreamController<AuthSession?>.broadcast();

  static final _pinFormat = RegExp(r'^\d{6}$');

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  FutureResult<AuthFailure, AuthSession> authenticate({
    required String identifier,
    required String pin,
  }) async {
    if (pin != _validPin) {
      return left(const GlobalFailure.server(AuthFailure.invalidCredentials()));
    }
    return right(AuthSession(
        userId: 'mem-${identifier.hashCode}', identifier: identifier));
  }

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async {
    final result = await authenticate(identifier: identifier, pin: pin);
    return result.map((session) {
      _emit(session);
      return session;
    });
  }

  @override
  FutureResult<AuthFailure, bool> isCurrentPin({
    required String identifier,
    required String pin,
    String? otpTicket,  // el backend real lo exige; aquí no hay a quién pedírselo
  }) async =>
      right(pin == _validPin);

  @override
  FutureResult<AuthFailure, Unit> resetPin({
    required String identifier,
    required String newPin,
    String? otpTicket,
  }) async {
    if (!_pinFormat.hasMatch(newPin)) {
      return left(const GlobalFailure.server(AuthFailure.weakPin()));
    }
    if (newPin == _validPin) {
      return left(const GlobalFailure.server(AuthFailure.pinUnchanged()));
    }
    _validPin = newPin;
    // Cambiar el PIN cierra las sesiones del resto de dispositivos. La de este
    // teléfono tampoco queda abierta: restablecer no otorga sesión.
    _otherDeviceTokens.clear();
    return right(unit);
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
  FutureResult<AuthFailure, Unit> activate(AuthSession session,
      {String? otpTicket}) async {
    _emit(session);
    return right(unit);
  }

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
