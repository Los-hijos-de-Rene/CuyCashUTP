/// De dónde salen las ráfagas de frames que se le mandan al servicio.
///
/// Existe como contrato —y no como llamada directa a la cámara— porque el bloc
/// del liveness es lógica pura: con un doble se puede probar el recorrido
/// completo (orden de tareas, reintentos, vencimiento) sin cámara ni permisos.
abstract interface class FrameSource {
  /// Captura [frames] fotogramas seguidos y los devuelve como JPEG en base64,
  /// sin el prefijo `data:`.
  ///
  /// Son datos biométricos: quien los reciba no debe escribirlos a disco ni a
  /// logs, y debe soltarlos al terminar el flujo.
  Future<List<String>> captureBurst({int frames});
}

/// Falla al capturar (cámara no lista, permiso revocado a mitad del flujo).
class FrameCaptureException implements Exception {
  const FrameCaptureException(this.message);
  final String message;

  @override
  String toString() => 'FrameCaptureException: $message';
}
