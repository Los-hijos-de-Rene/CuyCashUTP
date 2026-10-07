import 'package:cuycash/feature/kyc/domain/face_observation.dart';
import 'package:cuycash/feature/kyc/domain/liveness_gestures.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gestures = LivenessGestures();

  FaceObservation face({
    double yaw = 0,
    double pitch = 0,
    double eyes = 0.9,
    double width = 0.45,
  }) =>
      FaceObservation(
        frameId: 0,
        faceCount: 1,
        centerX: 0.5,
        centerY: 0.5,
        widthRatio: width,
        yaw: yaw,
        pitchDegrees: pitch,
        leftEyeOpen: eyes,
        rightEyeOpen: eyes,
      );

  test('un rostro centrado, cerca, de frente y con los ojos abiertos sirve',
      () {
    expect(gestures.framingIssue(face()), isNull);
  });

  test('cada problema de encuadre tiene su indicación', () {
    expect(gestures.framingIssue(const FaceObservation.empty(0)),
        FramingIssue.noFace);
    expect(gestures.framingIssue(face(width: 0.1)), FramingIssue.tooFar);
    expect(gestures.framingIssue(face(width: 0.95)), FramingIssue.tooClose);
    expect(gestures.framingIssue(face(yaw: 0.3)), FramingIssue.notFrontal);
    expect(gestures.framingIssue(face(eyes: 0.1)), FramingIssue.eyesClosed);
  });

  test('"de frente" se mide respecto a la pose de partida del usuario', () {
    // Hay cámaras y rostros que nunca dan 0 exacto.
    final baseline = face(yaw: 0.1);
    expect(gestures.framingIssue(face(yaw: 0.12), baseline: baseline), isNull);
  });

  test('izquierda es giro positivo (su izquierda), derecha negativo', () {
    final baseline = face();
    expect(gestures.reachesPose(LivenessStep.izquierda, face(yaw: 0.2), baseline),
        isTrue);
    expect(gestures.reachesPose(LivenessStep.derecha, face(yaw: 0.2), baseline),
        isFalse);
    expect(gestures.reachesPose(LivenessStep.derecha, face(yaw: -0.2), baseline),
        isTrue);
  });

  test('el umbral del teléfono deja margen sobre el del servidor (0.06)', () {
    final baseline = face();
    expect(gestures.turnDelta, greaterThan(0.06));
    expect(
        gestures.reachesPose(LivenessStep.izquierda, face(yaw: 0.07), baseline),
        isFalse);
  });

  test('arriba y abajo se miden en grados de inclinación', () {
    final baseline = face();
    expect(gestures.reachesPose(LivenessStep.arriba, face(pitch: 15), baseline),
        isTrue);
    expect(gestures.reachesPose(LivenessStep.abajo, face(pitch: -15), baseline),
        isTrue);
  });
}
