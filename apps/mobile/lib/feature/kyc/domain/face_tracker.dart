import 'face_observation.dart';

/// La cámara frontal vista como una secuencia de observaciones del rostro.
///
/// Existe como contrato —y no como llamada directa a la cámara y a ML Kit—
/// porque el bloc del liveness es lógica pura: con un doble se recorre el
/// flujo entero (encuadre, gestos, envío, vencimiento) sin cámara ni permisos.
abstract interface class FaceTracker {
  /// Una observación por fotograma analizado. Empieza a emitir tras [start].
  Stream<FaceObservation> get observations;

  Future<void> start();

  /// Deja de analizar; se puede volver a llamar a [start] (reintento).
  Future<void> stop();

  /// Libera la cámara y el detector. Después ya no se puede usar.
  Future<void> dispose();

  /// JPEG en base64 (sin prefijo `data:`) del fotograma [frameId], o null si
  /// ya salió del búfer reciente.
  ///
  /// Hay que pedirlo en cuanto llega la observación: el tracker solo guarda
  /// los últimos fotogramas. Es un dato biométrico: quien lo reciba no debe
  /// escribirlo a disco ni a logs.
  Future<String?> keepFrame(int frameId);
}

/// Falla al abrir o leer la cámara (permiso revocado, cámara ocupada).
class FaceTrackerException implements Exception {
  const FaceTrackerException(this.message);
  final String message;

  @override
  String toString() => 'FaceTrackerException: $message';
}
