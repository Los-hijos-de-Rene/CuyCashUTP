import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../../security/infrastructure/memory_security_state.dart';
import '../domain/auth_session.dart';

/// Memory* FUNCIONAL de auth (backend del flavor `mock` + contrato de tests).
/// [validPin] (default '000000') es el PIN que se acepta; vive en el estado
/// compartido [MemorySecurityState] para que cambiarlo desde el perfil cambie
/// también el del login.
class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({
    AuthSession? initial,
    String validPin = '000000',
    List<String> otherDeviceTokens = const [],
    MemorySecurityState? security,
    this.deviceTrusted = true,
    this.kycRequired = false,
  }) : _session = initial,
       _security =
           security ??
           MemorySecurityState.demo(clock: DateTime.now, pin: validPin),
       _otherDeviceTokens = [...otherDeviceTokens] {
    if (initial != null) _registered.add(initial.identifier);
  }

  final MemorySecurityState _security;

  /// Si es `false`, este teléfono no es de confianza (p. ej. lo desvincularon
  /// desde otro): el PIN correcto no abre sesión y `signIn` pide el OTP de
  /// dispositivo, como el backend real. Solo para simularlo en tests.
  bool deviceTrusted;

  /// Como el backend con `KYC_REQUIRED`: el alta exige un ticket de KYC.
  /// Apagado por defecto, igual que en producción hoy.
  final bool kycRequired;

  /// PIN aceptado por `signIn`. Cambia con `resetPin` y con el cambio de PIN
  /// del perfil (estado compartido).
  String get validPin => _security.pin;

  /// Tokens simulados de OTROS dispositivos. `resetPin` los invalida: cambiar
  /// el PIN cierra las sesiones abiertas en el resto de teléfonos.
  final List<String> _otherDeviceTokens;
  List<String> get otherDeviceTokens => List.unmodifiable(_otherDeviceTokens);

  AuthSession? _session;
  final Set<String> _registered = {};

  /// Nombre y alias de quien se registró aquí, por DNI. El backend los
  /// devuelve en toda respuesta que abre sesión: tras cerrar sesión el
  /// teléfono olvida al usuario y el login es la única fuente del nombre.
  final Map<String, AuthSession> _titulares = {};
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
    if (pin != _security.pin) {
      return left(const GlobalFailure.server(AuthFailure.invalidCredentials()));
    }
    return right(_sesionDe(identifier));
  }

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async {
    final result = await authenticate(identifier: identifier, pin: pin);
    return result.flatMap((session) {
      if (!deviceTrusted) {
        return left(
          const GlobalFailure.server(AuthFailure.deviceVerificationRequired()),
        );
      }
      _emit(session);
      return right(session);
    });
  }

  @override
  FutureResult<AuthFailure, bool> isCurrentPin({
    required String identifier,
    required String pin,
    String?
    otpTicket, // el backend real lo exige; aquí no hay a quién pedírselo
  }) async => right(pin == _security.pin);

  @override
  FutureResult<AuthFailure, Unit> resetPin({
    required String identifier,
    required String newPin,
    String? otpTicket,
  }) async {
    if (!_pinFormat.hasMatch(newPin)) {
      return left(const GlobalFailure.server(AuthFailure.weakPin()));
    }
    if (newPin == _security.pin) {
      return left(const GlobalFailure.server(AuthFailure.pinUnchanged()));
    }
    _security.pin = newPin;
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
    String? kycTicket,
  }) async {
    if (!_pinFormat.hasMatch(pin)) {
      return left(const GlobalFailure.server(AuthFailure.weakPin()));
    }
    if (_registered.contains(dni)) {
      return left(const GlobalFailure.server(AuthFailure.identifierTaken()));
    }
    // Como el servidor con KYC_REQUIRED: sin ticket de KYC aprobado, no hay alta.
    if (kycRequired && (kycTicket == null || kycTicket.isEmpty)) {
      return left(const GlobalFailure.server(AuthFailure.identityNotVerified()));
    }
    _registered.add(dni);
    final titular = AuthSession(
      userId: 'mem-${dni.hashCode}',
      identifier: dni,
      alias: _aliasFor(nombres, dni),
      fullName: '${nombres.trim()} ${apellidos.trim()}'.trim(),
    );
    _titulares[dni] = titular;
    // Crea la cuenta pero NO inicia sesión: la sesión se activa cuando el
    // usuario toca "Ir a mi cuenta" en la pantalla de éxito.
    return right(titular);
  }

  @override
  FutureResult<AuthFailure, Unit> activate(
    AuthSession session, {
    String? otpTicket,
  }) async {
    _emit(session);
    return right(unit);
  }

  @override
  FutureResult<AuthFailure, AuthSession> signInWithBiometric({
    required String dni,
    required String credential,
  }) async {
    final device = _security.credentials[credential];
    if (device != _security.thisDeviceId || dni != _security.dni) {
      return left(const GlobalFailure.server(AuthFailure.biometricRevoked()));
    }
    final session = _sesionDe(dni);
    _emit(session);
    return right(session);
  }

  @override
  FutureResult<AuthFailure, Unit> signOut() async {
    _session = null;
    _controller.add(null);
    return right(unit);
  }

  /// La sesión de [dni] con su nombre y alias si se registró aquí; si no,
  /// solo el identificador.
  AuthSession _sesionDe(String dni) =>
      _titulares[dni] ??
      AuthSession(userId: 'mem-${dni.hashCode}', identifier: dni);

  /// Alias mock derivado del primer nombre (ascii, minúsculas); si no queda
  /// nada usable, cae al DNI.
  /// Como `base_desde_nombre` del backend: el primer nombre sin tildes, con
  /// al menos 3 caracteres y una letra (si no, se completa con `cuy`). Nunca
  /// el DNI: el alias es público y lleva siempre una letra.
  static String _aliasFor(String nombres, String dni) {
    const tildes = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final first = nombres.trim().split(RegExp(r'\s+')).first.toLowerCase();
    final plano = first.split('').map((c) => tildes[c] ?? c).join();
    var slug = plano.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (slug.length > 16) slug = slug.substring(0, 16);
    if (slug.length < 3 || !slug.contains(RegExp('[a-z]'))) slug = 'cuy$slug';
    return '@$slug';
  }

  void _emit(AuthSession session) {
    // La huella del mock se ata al DNI con sesión; si quedara fijo el de la
    // demo, cualquier otro DNI vería su huella revocada al primer uso.
    _security.dni = session.identifier;
    _session = session;
    _controller.add(session);
  }
}
