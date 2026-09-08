import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/otp_challenge.dart';
import '../domain/otp_failure.dart';
import '../domain/otp_policy.dart';
import '../domain/otp_repository.dart';

/// Memory* FUNCIONAL del OTP (backend del flavor `mock` + contrato de tests).
///
/// El reloj entra por constructor: sin eso los tres relojes de `OtpPolicy` no
/// se pueden testear. Dentro de esta clase NO se llama a `DateTime.now()`.
class MemoryOtpRepository implements OtpRepository {
  MemoryOtpRepository({
    required DateTime Function() clock,
    String Function(String identifier)? emailResolver,
    this.validCode = OtpPolicy.validCode,
  })  : _now = clock,
        _emailResolver = emailResolver ?? _defaultEmail;

  final DateTime Function() _now;
  final String Function(String identifier) _emailResolver;
  final String validCode;

  final Map<String, _Challenge> _challenges = {};

  /// Enfriamiento por identificador tras cancelar un flujo.
  final Map<String, DateTime> _lockouts = {};

  /// Avisos "enviados" al correo registrado (log del mock).
  final List<String> notifications = [];

  var _seq = 0;

  /// Instante hasta el que [identifier] está bloqueado, o null.
  DateTime? lockoutFor(String identifier) {
    final until = _lockouts[identifier];
    if (until == null) return null;
    return _now().isBefore(until) ? until : null;
  }

  @override
  FutureResult<OtpFailure, OtpChallenge> request(String identifier) async {
    final now = _now();
    final locked = lockoutFor(identifier);
    if (locked != null) {
      return left(GlobalFailure.server(OtpFailure.identifierLocked(locked)));
    }
    _lockouts.remove(identifier); // vencido: se limpia
    final challenge = _Challenge(
      id: 'otp-${_seq++}',
      identifier: identifier,
      maskedEmail: maskEmail(_emailResolver(identifier)),
      expiresAt: now.add(OtpPolicy.ttl),
      cooldownUntil: now.add(OtpPolicy.cooldown),
      attemptsLeft: OtpPolicy.maxAttempts,
      resendsLeft: OtpPolicy.maxResends,
    );
    _challenges[challenge.id] = challenge;
    return right(challenge.toDomain());
  }

  @override
  FutureResult<OtpFailure, Unit> verify({
    required String challengeId,
    required String code,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      return left(const GlobalFailure.server(OtpFailure.challengeNotFound()));
    }
    if (challenge.cancelledReason != null) {
      return left(GlobalFailure.server(
          OtpFailure.challengeCancelled(challenge.cancelledReason!)));
    }
    // El vencimiento se evalúa antes que el código y NO consume intentos.
    if (!_now().isBefore(challenge.expiresAt)) {
      return left(const GlobalFailure.server(OtpFailure.codeExpired()));
    }
    if (code == validCode) {
      _challenges.remove(challengeId); // se consume
      return right(unit);
    }
    challenge.attemptsLeft -= 1;
    if (challenge.attemptsLeft <= 0) {
      _cancel(challenge, OtpCancelReason.attempts);
      return left(const GlobalFailure.server(
          OtpFailure.challengeCancelled(OtpCancelReason.attempts)));
    }
    return left(
        GlobalFailure.server(OtpFailure.invalidCode(challenge.attemptsLeft)));
  }

  @override
  FutureResult<OtpFailure, OtpChallenge> resend(String challengeId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      return left(const GlobalFailure.server(OtpFailure.challengeNotFound()));
    }
    if (challenge.cancelledReason != null) {
      return left(GlobalFailure.server(
          OtpFailure.challengeCancelled(challenge.cancelledReason!)));
    }
    if (challenge.resendsLeft <= 0) {
      _cancel(challenge, OtpCancelReason.resends);
      return left(const GlobalFailure.server(
          OtpFailure.challengeCancelled(OtpCancelReason.resends)));
    }
    final now = _now();
    challenge
      ..resendsLeft -= 1
      ..expiresAt = now.add(OtpPolicy.ttl)
      ..cooldownUntil = now.add(OtpPolicy.cooldown);
    return right(challenge.toDomain());
  }

  /// Invalida el reto, deja constancia del aviso al correo y aplica el
  /// enfriamiento al identificador. Después de esto no hay reenvío posible.
  void _cancel(_Challenge challenge, OtpCancelReason reason) {
    challenge.cancelledReason = reason;
    _lockouts[challenge.identifier] = _now().add(OtpPolicy.lockout);
    notifications.add(
        'aviso a ${challenge.maskedEmail}: flujo cancelado (${reason.name})');
  }

  /// Enmascara el correo dejando visible la primera letra: `j•••••@gmail.com`.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return email;
    final domain = email.substring(at);
    return '${email[0]}${'•' * 5}$domain';
  }

  /// Si el identificador ya es un correo se usa tal cual; si es un DNI, el mock
  /// devuelve el correo de la cuenta simulada.
  static String _defaultEmail(String identifier) =>
      identifier.contains('@') ? identifier : 'juan.perez@gmail.com';
}

/// Reto mutable interno (el `OtpChallenge` público es inmutable).
class _Challenge {
  _Challenge({
    required this.id,
    required this.identifier,
    required this.maskedEmail,
    required this.expiresAt,
    required this.cooldownUntil,
    required this.attemptsLeft,
    required this.resendsLeft,
  });

  final String id;
  final String identifier;
  final String maskedEmail;
  DateTime expiresAt;
  DateTime cooldownUntil;
  int attemptsLeft;
  int resendsLeft;
  OtpCancelReason? cancelledReason;

  OtpChallenge toDomain() => OtpChallenge(
        id: id,
        maskedEmail: maskedEmail,
        expiresAt: expiresAt,
        cooldownUntil: cooldownUntil,
        attemptsLeft: attemptsLeft,
        resendsLeft: resendsLeft,
      );
}
