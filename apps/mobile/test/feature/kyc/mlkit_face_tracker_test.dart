import 'dart:math';
import 'dart:ui';

import 'package:cuycash/feature/kyc/domain/liveness_gestures.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:cuycash/feature/kyc/infrastructure/mlkit_face_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Un rostro como lo devuelve ML Kit: mejillas en x=100 (`leftCheek`) y x=200
/// (`rightCheek`), nariz en [noseX].
Face face(int noseX) => Face(
  boundingBox: const Rect.fromLTWH(80, 100, 140, 180),
  landmarks: {
    FaceLandmarkType.leftCheek: FaceLandmark(
      type: FaceLandmarkType.leftCheek,
      position: const Point(100, 200),
    ),
    FaceLandmarkType.rightCheek: FaceLandmark(
      type: FaceLandmarkType.rightCheek,
      position: const Point(200, 200),
    ),
    FaceLandmarkType.noseBase: FaceLandmark(
      type: FaceLandmarkType.noseBase,
      position: Point(noseX, 190),
    ),
  },
  contours: const {},
  leftEyeOpenProbability: 0.9,
  rightEyeOpenProbability: 0.9,
);

void main() {
  const size = Size(300, 400);
  const gestures = LivenessGestures();
  final frente = MlKitFaceTracker.observe(0, [face(150)], size);

  // Visto en un iPhone: girar el stream de iOS lo dejaba acostado y el
  // servidor no reconocía la cara contra el DNI.
  test('iOS no gira el stream (ya llega derecho); Android sí', () {
    expect(
      MlKitFaceTracker.frameRotation(isIOS: true, sensorOrientation: 90),
      0,
    );
    expect(
      MlKitFaceTracker.frameRotation(isIOS: false, sensorOrientation: 270),
      270,
    );
  });

  test('de frente, el giro es cero', () {
    expect(frente.yaw, 0);
  });

  // Signo VERIFICADO en un teléfono Android: la nariz hacia `rightCheek` es el
  // usuario girando a SU izquierda. Con el signo contrario la app pedía
  // "gira a tu derecha" y solo pasaba girando a la izquierda.
  test('nariz hacia rightCheek = gira a su izquierda', () {
    final giro = MlKitFaceTracker.observe(1, [face(180)], size);

    expect(giro.yaw, greaterThan(0));
    expect(gestures.reachesPose(LivenessStep.izquierda, giro, frente), isTrue);
    expect(gestures.reachesPose(LivenessStep.derecha, giro, frente), isFalse);
  });

  test('en espejo (iOS) el mismo desplazamiento es el giro contrario', () {
    final giro =
        MlKitFaceTracker.observe(3, [face(180)], size, mirrored: true);

    expect(giro.yaw, lessThan(0));
    expect(gestures.reachesPose(LivenessStep.derecha, giro, frente), isTrue);
    expect(gestures.reachesPose(LivenessStep.izquierda, giro, frente), isFalse);
  });

  test('nariz hacia leftCheek = gira a su derecha', () {
    final giro = MlKitFaceTracker.observe(2, [face(120)], size);

    expect(giro.yaw, lessThan(0));
    expect(gestures.reachesPose(LivenessStep.derecha, giro, frente), isTrue);
  });
}
