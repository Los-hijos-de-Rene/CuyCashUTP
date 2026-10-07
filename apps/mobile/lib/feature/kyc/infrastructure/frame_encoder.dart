import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Formatos crudos que entrega el stream de la cámara.
enum RawFrameFormat {
  /// Android (CameraX con `ImageFormatGroup.nv21`): un solo plano Y + VU.
  nv21,

  /// iOS (AVFoundation): un solo plano BGRA de 4 bytes por píxel.
  bgra8888,
}

/// Copia de un fotograma del stream, lista para codificar fuera del hilo de UI.
///
/// Es una COPIA a propósito: el plugin recicla el buffer de cada `CameraImage`
/// en cuanto termina el callback, y codificar tarda más que eso.
class RawFrame {
  const RawFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.format,
    required this.rotationDegrees,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final RawFrameFormat format;

  /// Giro horario para dejar la imagen vertical (la orientación del sensor).
  final int rotationDegrees;
}

/// JPEG vertical en base64, codificado en un isolate.
///
/// POR QUÉ ASÍ: convertir YUV a JPEG en Dart cuesta del orden de cientos de
/// milisegundos por fotograma. En el hilo de UI congelaría la vista previa
/// justo mientras el usuario hace el gesto; en un isolate no se nota, y solo
/// se codifican los ~15 fotogramas clave que se envían, no todo el stream.
Future<String> encodeFrameAsBase64Jpeg(RawFrame frame) =>
    Isolate.run(() => base64Encode(encodeFrameJpeg(frame)));

/// Versión síncrona de [encodeFrameAsBase64Jpeg], para pruebas.
Uint8List encodeFrameJpeg(RawFrame frame, {int quality = 85}) {
  var image = switch (frame.format) {
    RawFrameFormat.nv21 => _nv21ToImage(frame),
    RawFrameFormat.bgra8888 => img.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: frame.bytes.buffer,
        bytesOffset: frame.bytes.offsetInBytes,
        rowStride: frame.bytesPerRow,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      ),
  };
  if (frame.rotationDegrees % 360 != 0) {
    image = img.copyRotate(image, angle: frame.rotationDegrees);
  }
  return img.encodeJpg(image, quality: quality);
}

/// NV21: plano Y de `bytesPerRow * height`, seguido de V/U intercalados a
/// media resolución. Conversión BT.601 en enteros (rango completo).
img.Image _nv21ToImage(RawFrame frame) {
  final width = frame.width;
  final height = frame.height;
  final stride = frame.bytesPerRow;
  final data = frame.bytes;
  final uvStart = stride * height;
  final out = img.Image(width: width, height: height);

  for (var row = 0; row < height; row++) {
    final yRow = row * stride;
    final uvRow = uvStart + (row >> 1) * stride;
    for (var col = 0; col < width; col++) {
      final y = data[yRow + col];
      final uvIndex = uvRow + (col & ~1);
      final v = data[uvIndex] - 128;
      final u = data[uvIndex + 1] - 128;
      // Coeficientes ×1024: 1.402, 0.344, 0.714, 1.772.
      final r = y + ((1436 * v) >> 10);
      final g = y - ((352 * u + 731 * v) >> 10);
      final b = y + ((1815 * u) >> 10);
      out.setPixelRgb(col, row, _clamp(r), _clamp(g), _clamp(b));
    }
  }
  return out;
}

int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
