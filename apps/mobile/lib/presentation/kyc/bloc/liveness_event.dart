part of 'liveness_bloc.dart';

@freezed
sealed class LivenessEvent with _$LivenessEvent {
  /// Abre la cámara y pide el desafío. También sirve para rehacerlo.
  const factory LivenessEvent.started() = LivenessStarted;

  /// El detector del teléfono analizó un fotograma.
  const factory LivenessEvent.observed(FaceObservation observation) =
      LivenessObserved;
}
