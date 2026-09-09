part of 'liveness_bloc.dart';

@freezed
sealed class LivenessEvent with _$LivenessEvent {
  /// Pide el desafío al servidor. También sirve para rehacerlo tras vencer.
  const factory LivenessEvent.started() = LivenessStarted;

  /// El usuario dice que está listo: se graba la ráfaga de la tarea actual.
  const factory LivenessEvent.stepCaptureRequested() = LivenessStepCaptureRequested;
}
