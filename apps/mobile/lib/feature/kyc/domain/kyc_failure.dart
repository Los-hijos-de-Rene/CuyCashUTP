/// Failures de KYC (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
///
/// Ojo con lo que NO está aquí: que la verificación rechace a la persona no es
/// un failure, es un veredicto (`KycVerification.approved == false`).
/// Mezclarlos haría que un rechazo normal se viera como un error del sistema.
sealed class KycFailure {
  const KycFailure();

  const factory KycFailure.challengeExpired() = ChallengeExpired;
  const factory KycFailure.unauthorized() = Unauthorized;
  const factory KycFailure.invalidResponse() = InvalidResponse;
  const factory KycFailure.serviceUnavailable() = ServiceUnavailable;
}

/// El token venció (TTL del servidor), ya se usó o no existe: hay que pedir
/// uno nuevo y rehacer el desafío desde el principio.
final class ChallengeExpired extends KycFailure {
  const ChallengeExpired();
}

/// El servidor rechazó la llamada por credenciales. Es un fallo de
/// configuración del despliegue, no del usuario.
final class Unauthorized extends KycFailure {
  const Unauthorized();
}

/// El servicio respondió algo que no encaja con el contrato (una tarea
/// desconocida, un campo faltante). No se adivina: se falla.
final class InvalidResponse extends KycFailure {
  const InvalidResponse();
}

/// No se pudo contactar al servicio, o respondió 5xx.
final class ServiceUnavailable extends KycFailure {
  const ServiceUnavailable();
}
