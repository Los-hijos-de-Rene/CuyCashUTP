/// Lo que el detector del teléfono vio en UN fotograma de la cámara.
///
/// Sirve solo para GUIAR al usuario (encuadre, avance de un gesto al
/// siguiente): el veredicto lo da el servidor con los fotogramas que se le
/// envían. Por eso no hay aquí nada que decida si la persona está viva.
///
/// Coordenadas normalizadas a 0..1 sobre la imagen ya rotada a vertical, de
/// modo que no dependen de la resolución ni de la orientación del sensor.
class FaceObservation {
  const FaceObservation({
    required this.frameId,
    required this.faceCount,
    this.centerX = 0,
    this.centerY = 0,
    this.widthRatio = 0,
    this.yaw = 0,
    this.pitchDegrees = 0,
    this.leftEyeOpen,
    this.rightEyeOpen,
  });

  /// Ningún rostro en el fotograma.
  const FaceObservation.empty(int frameId) : this(frameId: frameId, faceCount: 0);

  /// Identifica el fotograma dentro del tracker, para pedirle después su JPEG.
  final int frameId;

  final int faceCount;

  /// Centro del rostro (0..1).
  final double centerX;
  final double centerY;

  /// Ancho del rostro sobre el ancho de la imagen: mide la distancia.
  final double widthRatio;

  /// Giro lateral normalizado, con la MISMA fórmula que el servidor:
  /// `(nariz.x - centroMejillas.x) / (mejillaIzq.x - mejillaDer.x)`, con
  /// izquierda y derecha del propio usuario. Positivo = gira a SU izquierda.
  ///
  /// Dividir entre un ancho con signo la hace independiente del espejado de la
  /// cámara frontal: espejar invierte numerador y denominador a la vez.
  final double yaw;

  /// Inclinación vertical en grados. Positivo = mira hacia arriba.
  final double pitchDegrees;

  /// Probabilidad 0..1 de ojo abierto; null si el detector no la dio.
  final double? leftEyeOpen;
  final double? rightEyeOpen;

  bool get hasSingleFace => faceCount == 1;

  /// Los dos ojos claramente cerrados.
  bool eyesClosedBelow(double threshold) =>
      (leftEyeOpen ?? 1) < threshold && (rightEyeOpen ?? 1) < threshold;

  /// Los dos ojos claramente abiertos. Sin dato se asume abierto: así un
  /// detector que no clasifica no deja el flujo encallado.
  bool eyesOpenAbove(double threshold) =>
      (leftEyeOpen ?? 1) >= threshold && (rightEyeOpen ?? 1) >= threshold;
}
