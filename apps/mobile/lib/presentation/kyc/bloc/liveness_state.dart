part of 'liveness_bloc.dart';

/// En qué punto del desafío está la pantalla.
enum LivenessPhase {
  /// Abriendo la cámara y pidiendo el desafío al servidor.
  preparing,

  /// Esperando a que el rostro quede bien encuadrado y quieto.
  positioning,

  /// El usuario está haciendo el gesto [LivenessState.currentStep].
  performing,

  /// Entre dos gestos: volver a mirar al frente antes del siguiente.
  recentering,

  /// Todos los gestos hechos: enviando los fotogramas al servidor.
  sending,

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

    /// Tareas en el orden que impuso el servidor.
    @Default(<LivenessStep>[]) List<LivenessStep> steps,

    /// Índice de la tarea pendiente.
    @Default(0) int currentIndex,

    /// Qué corregir del encuadre ahora mismo (null = está bien).
    FramingIssue? framing,

    /// El gesto lleva rato sin completarse: sugerir hacerlo más marcado.
    @Default(false) bool slow,
    LivenessError? error,
    KycVerification? verification,
  }) = _LivenessState;

  const LivenessState._();

  /// Tarea que toca ahora, o null si ya no queda ninguna.
  LivenessStep? get currentStep =>
      currentIndex < steps.length ? steps[currentIndex] : null;

  int get completedSteps => currentIndex;

  bool get isApproved => verification?.approved ?? false;

  /// Si la cámara está siguiendo al usuario (hay que mostrar la guía).
  bool get isTracking =>
      phase == LivenessPhase.positioning ||
      phase == LivenessPhase.performing ||
      phase == LivenessPhase.recentering;
}
