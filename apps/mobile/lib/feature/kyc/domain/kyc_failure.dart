import 'liveness_step.dart';

/// Failures de KYC (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
///
/// Ojo con lo que NO está aquí: que una tarea no pase (`passed:false`) no es un
/// failure, es el usuario reintentando. Mezclarlos haría que un reintento
/// normal se viera como un error del sistema.
sealed class KycFailure {
  const KycFailure();

  const factory KycFailure.challengeExpired() = ChallengeExpired;
  const factory KycFailure.stepOutOfOrder(LivenessStep expected) =
      StepOutOfOrder;
  const factory KycFailure.challengeCompleted() = ChallengeCompleted;
  const factory KycFailure.unauthorized() = Unauthorized;
  const factory KycFailure.invalidResponse() = InvalidResponse;
  const factory KycFailure.serviceUnavailable() = ServiceUnavailable;
}

/// El token venció (TTL del servidor) o no existe: hay que pedir uno nuevo y
/// rehacer el desafío desde el principio.
final class ChallengeExpired extends KycFailure {
  const ChallengeExpired();
}

/// Se envió una tarea distinta a la pendiente. Es un bug del cliente, no algo
/// que el usuario pueda corregir: el orden lo manda el servidor.
final class StepOutOfOrder extends KycFailure {
  const StepOutOfOrder(this.expected);
  final LivenessStep expected;
}

/// Todas las tareas ya pasaron: corresponde ir a la verificación final.
final class ChallengeCompleted extends KycFailure {
  const ChallengeCompleted();
}

/// API key inválida o ausente. Es un fallo de configuración del despliegue, no
/// del usuario.
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
