/// Tareas del desafío de liveness. El pool y el ORDEN los decide el servidor:
/// que el cliente no sepa la secuencia antes de capturar es justamente la
/// protección anti-replay, así que aquí nunca se genera una.
enum LivenessStep {
  arriba('arriba'),
  abajo('abajo'),
  izquierda('izquierda'),
  derecha('derecha'),
  parpadeo('parpadeo');

  const LivenessStep(this.wireName);

  /// Nombre exacto que viaja en la API.
  final String wireName;

  /// Devuelve null si el servidor manda una tarea que esta versión de la app
  /// no conoce: se trata como respuesta inválida en vez de adivinarla.
  static LivenessStep? fromWire(String value) {
    for (final step in LivenessStep.values) {
      if (step.wireName == value) return step;
    }
    return null;
  }
}
