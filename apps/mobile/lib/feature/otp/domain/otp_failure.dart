/// Por qué se canceló un reto: se agotaron los intentos o los reenvíos. La UI
/// necesita distinguirlos para redactar el motivo.
enum OtpCancelReason { attempts, resends }

/// Failures de OTP (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
sealed class OtpFailure {
  const OtpFailure();

  const factory OtpFailure.invalidCode(int attemptsLeft) = InvalidCode;
  const factory OtpFailure.codeExpired() = CodeExpired;
  const factory OtpFailure.challengeCancelled(OtpCancelReason reason) =
      ChallengeCancelled;
  const factory OtpFailure.identifierLocked(DateTime until) = IdentifierLocked;
  const factory OtpFailure.challengeNotFound() = ChallengeNotFound;
}

/// Código incorrecto; quedan [attemptsLeft] intentos.
final class InvalidCode extends OtpFailure {
  const InvalidCode(this.attemptsLeft);
  final int attemptsLeft;
}

/// El código venció (TTL). No consume intentos: pedir uno nuevo es la salida.
final class CodeExpired extends OtpFailure {
  const CodeExpired();
}

/// El reto quedó invalidado. Después de esto no hay camino de reenvío: hay que
/// rehacer el flujo desde el inicio.
final class ChallengeCancelled extends OtpFailure {
  const ChallengeCancelled(this.reason);
  final OtpCancelReason reason;
}

/// El identificador está en enfriamiento tras una cancelación.
final class IdentifierLocked extends OtpFailure {
  const IdentifierLocked(this.until);
  final DateTime until;
}

/// No existe un reto con ese id (o ya se consumió).
final class ChallengeNotFound extends OtpFailure {
  const ChallengeNotFound();
}
