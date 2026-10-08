import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:image/image.dart' as img;

/// Proporción del DNI peruano (tarjeta ID-1, ISO/IEC 7810: 85,6 × 54 mm).
const double kIdCardAspectRatio = 85.6 / 54;

/// Marco del documento dentro de la vista previa: horizontal, centrado y con
/// la proporción exacta de la tarjeta. El mismo rectángulo se dibuja en
/// pantalla y se usa para recortar, así que lo que el usuario encuadra es lo
/// que se envía.
Rect documentFrameFor(Size viewport) {
  final width = math.min(viewport.width * 0.88,
      viewport.height * 0.70 * kIdCardAspectRatio);
  final height = width / kIdCardAspectRatio;
  return Rect.fromCenter(
    center: Offset(viewport.width / 2, viewport.height * 0.45),
    width: width,
    height: height,
  );
}

/// Traduce [frame] (en píxeles de pantalla) a fracciones 0..1 de la foto.
///
/// La vista previa se muestra con `BoxFit.cover`: llena el recuadro y recorta
/// lo que sobra por los lados. Por eso no basta con dividir entre el tamaño
/// de la pantalla: hay que deshacer la escala y el desplazamiento del cover.
/// [content] es el tamaño de la vista previa en vertical (sus píxeles reales).
Rect normalizedCropFor({
  required Rect frame,
  required Size viewport,
  required Size content,
  double margin = 0.06,
}) {
  final scale = math.max(
      viewport.width / content.width, viewport.height / content.height);
  final shownWidth = content.width * scale;
  final shownHeight = content.height * scale;
  final dx = (shownWidth - viewport.width) / 2;
  final dy = (shownHeight - viewport.height) / 2;

  // Un margen alrededor del marco: el usuario casi nunca lo calza exacto, y
  // cortar un borde del DNI (o la foto) es peor que enviar un poco de mesa.
  final grown = frame.inflate(frame.shortestSide * margin);
  final rect = Rect.fromLTRB(
    (grown.left + dx) / shownWidth,
    (grown.top + dy) / shownHeight,
    (grown.right + dx) / shownWidth,
    (grown.bottom + dy) / shownHeight,
  );
  return rect.intersect(const Rect.fromLTWH(0, 0, 1, 1));
}

/// Recorta la foto al marco y la limita a [maxWidth], en un isolate.
///
/// Si algo falla al decodificar, devuelve la foto original: es preferible
/// enviar la imagen entera a dejar al usuario sin poder continuar.
Future<Uint8List> cropDocument(
  Uint8List jpeg,
  Rect normalized, {
  int maxWidth = 1600,
}) =>
    Isolate.run(() => cropDocumentSync(jpeg, normalized, maxWidth: maxWidth));

/// Versión síncrona de [cropDocument], para pruebas.
Uint8List cropDocumentSync(
  Uint8List jpeg,
  Rect normalized, {
  int maxWidth = 1600,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(jpeg);
  } catch (_) {
    // Con bytes corruptos el decodificador lanza en vez de devolver null.
    return jpeg;
  }
  if (decoded == null) return jpeg;
  // La cámara suele guardar la foto "acostada" con una marca EXIF de giro;
  // se aplica antes de recortar para que las fracciones caigan donde deben.
  final upright = img.bakeOrientation(decoded);

  final x = (normalized.left * upright.width).round();
  final y = (normalized.top * upright.height).round();
  final width = (normalized.width * upright.width).round();
  final height = (normalized.height * upright.height).round();
  if (width <= 0 || height <= 0) return jpeg;

  var cropped = img.copyCrop(upright, x: x, y: y, width: width, height: height);
  if (cropped.width > maxWidth) {
    cropped = img.copyResize(cropped, width: maxWidth);
  }
  return img.encodeJpg(cropped, quality: 90);
}
