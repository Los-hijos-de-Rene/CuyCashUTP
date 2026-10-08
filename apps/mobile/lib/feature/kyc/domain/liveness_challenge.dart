import 'liveness_step.dart';

/// Desafío de liveness abierto: token, orden de tareas y vencimiento.
///
/// El token vive solo en memoria mientras dura el flujo y se descarta al
/// terminar: es una credencial de sesión biométrica, no un dato de la cuenta.
class LivenessChallenge {
  const LivenessChallenge({
    required this.token,
    required this.steps,
    required this.expiresAt,
  });

  final String token;

  /// Tareas en el orden impuesto por el servidor.
  final List<LivenessStep> steps;

  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      other is LivenessChallenge &&
      other.token == token &&
      other.expiresAt == expiresAt &&
      _sameSteps(other.steps);

  bool _sameSteps(List<LivenessStep> other) {
    if (other.length != steps.length) return false;
    for (var i = 0; i < steps.length; i++) {
      if (other[i] != steps[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(token, expiresAt, Object.hashAll(steps));
}

/// Veredicto del flujo completo. [approved] es lo único que decide; el resto
/// existe para poder explicarle al usuario qué falló.
class KycVerification {
  const KycVerification({
    required this.approved,
    required this.reason,
    required this.documentValid,
    required this.isLive,
    required this.faceMatch,
    this.dniMatches,
    this.ticket,
  });

  final bool approved;
  final String reason;
  final bool documentValid;
  final bool isLive;
  final bool faceMatch;

  /// Si el DNI leído del reverso es el declarado. Null si no se envió el
  /// reverso o no se pudo leer.
  final bool? dniMatches;

  /// Ticket que el backend emite solo si aprobó TODO. `/register` lo exige:
  /// es lo que convierte el veredicto en algo que el servidor recuerda, en vez
  /// de algo que la app "dice".
  final String? ticket;
}
