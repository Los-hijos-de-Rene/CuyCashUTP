import 'face_observation.dart';
import 'liveness_step.dart';

/// Qué le falta al encuadre para poder empezar o seguir.
enum FramingIssue {
  noFace,
  multipleFaces,
  tooFar,
  tooClose,
  offCenter,
  notFrontal,
  eyesClosed,
}

/// Reglas del lado del teléfono: cuándo el rostro está bien encuadrado y
/// cuándo un gesto ya se hizo.
///
/// Son umbrales de GUÍA, más exigentes que los del servidor a propósito: si
/// el teléfono da un gesto por hecho, los fotogramas que manda deben pasar con
/// margen la validación real (`HEAD_POSE_MOVE_THRESHOLD = 0.06` allá).
class LivenessGestures {
  const LivenessGestures({
    this.minWidthRatio = 0.28,
    this.maxWidthRatio = 0.80,
    this.centerTolerance = 0.20,
    this.frontalYaw = 0.07,
    this.frontalPitchDegrees = 12,
    this.turnDelta = 0.12,
    this.pitchDeltaDegrees = 12,
    this.eyeClosed = 0.25,
    this.eyeOpen = 0.6,
  });

  final double minWidthRatio;
  final double maxWidthRatio;
  final double centerTolerance;

  /// Cuánto puede alejarse el giro del frente y seguir contando como "de frente".
  final double frontalYaw;
  final double frontalPitchDegrees;

  /// Giro mínimo, respecto a la pose de partida, para dar por hecho un gesto.
  final double turnDelta;
  final double pitchDeltaDegrees;

  final double eyeClosed;
  final double eyeOpen;

  /// Null si el encuadre sirve. Con [baseline] se mide "de frente" respecto a
  /// la pose de partida del usuario, no respecto a un cero teórico: hay
  /// rostros y cámaras que nunca dan 0 exacto.
  FramingIssue? framingIssue(FaceObservation o, {FaceObservation? baseline}) {
    if (o.faceCount == 0) return FramingIssue.noFace;
    if (o.faceCount > 1) return FramingIssue.multipleFaces;
    if (o.widthRatio < minWidthRatio) return FramingIssue.tooFar;
    if (o.widthRatio > maxWidthRatio) return FramingIssue.tooClose;
    if ((o.centerX - 0.5).abs() > centerTolerance ||
        (o.centerY - 0.5).abs() > centerTolerance) {
      return FramingIssue.offCenter;
    }
    if (!isFrontal(o, baseline: baseline)) return FramingIssue.notFrontal;
    if (!o.eyesOpenAbove(eyeOpen)) return FramingIssue.eyesClosed;
    return null;
  }

  bool isFrontal(FaceObservation o, {FaceObservation? baseline}) =>
      (o.yaw - (baseline?.yaw ?? 0)).abs() <= frontalYaw &&
      (o.pitchDegrees - (baseline?.pitchDegrees ?? 0)).abs() <=
          frontalPitchDegrees;

  /// Si [o] ya muestra el giro que pide [step] respecto a [baseline].
  /// El parpadeo no es una pose sino una secuencia: lo lleva el bloc.
  bool reachesPose(
    LivenessStep step,
    FaceObservation o,
    FaceObservation baseline,
  ) {
    final yaw = o.yaw - baseline.yaw;
    final pitch = o.pitchDegrees - baseline.pitchDegrees;
    return switch (step) {
      LivenessStep.izquierda => yaw >= turnDelta,
      LivenessStep.derecha => yaw <= -turnDelta,
      LivenessStep.arriba => pitch >= pitchDeltaDegrees,
      LivenessStep.abajo => pitch <= -pitchDeltaDegrees,
      LivenessStep.parpadeo => false,
    };
  }
}
