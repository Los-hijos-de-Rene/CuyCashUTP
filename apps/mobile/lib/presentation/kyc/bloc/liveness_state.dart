part of 'liveness_bloc.dart';

/// En qué punto del desafío está la pantalla.
enum LivenessPhase {
  /// Pidiendo el desafío al servidor.
  preparing,

  /// Mostrando la instrucción de la tarea actual, esperando al usuario.
  waiting,

  /// Grabando la ráfaga de la tarea actual.
  capturing,

  /// La ráfaga está en el servidor.
  evaluating,

  /// La última tarea no pasó: se reintenta LA MISMA.
  retry,

  /// Todas las tareas pasaron; corriendo la verificación final.
  verifying,

  /// Terminó con veredicto.
  done,

  /// El flujo se cayó (token vencido, servicio caído, cámara).
  failed,
}

/// Por qué se cayó el flujo. Lo traduce la UI; el bloc no carga texto.
enum LivenessError {
  challengeExpired,
  unauthorized,
  serviceUnavailable,
  camera,
  rejected,
  generic,
}

@freezed
abstract class LivenessState with _$LivenessState {
  const factory LivenessState({
    @Default(LivenessPhase.preparing) LivenessPhase phase,
    String? token,

    /// Tareas en el orden que impuso el servidor.
    @Default(<LivenessStep>[]) List<LivenessStep> steps,

    /// Índice de la tarea pendiente.
    @Default(0) int currentIndex,

    /// Motivo del último intento fallido, tal como lo explicó el servidor.
    String? lastReason,
    LivenessError? error,
    KycVerification? verification,
  }) = _LivenessState;

  const LivenessState._();

  /// Tarea que toca ahora, o null si ya no queda ninguna.
  LivenessStep? get currentStep =>
      currentIndex < steps.length ? steps[currentIndex] : null;

  int get completedSteps => currentIndex;

  bool get isApproved => verification?.approved ?? false;

  /// Mientras se captura o se evalúa no se aceptan más pulsaciones: una
  /// segunda ráfaga sobre la misma tarea la mandaría fuera de orden.
  bool get isBusy =>
      phase == LivenessPhase.capturing ||
      phase == LivenessPhase.evaluating ||
      phase == LivenessPhase.verifying ||
      phase == LivenessPhase.preparing;
}
