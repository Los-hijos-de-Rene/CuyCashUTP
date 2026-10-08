import 'dart:typed_data';

import 'package:cuycash/feature/kyc/infrastructure/frame_encoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  /// NV21 de 4×2 con luma [y] y croma neutra (gris).
  RawFrame nv21({required int y, int rotation = 0}) {
    const width = 4;
    const height = 2;
    final bytes = Uint8List(width * height * 3 ~/ 2)
      ..fillRange(0, width * height, y)
      ..fillRange(width * height, width * height * 3 ~/ 2, 128);
    return RawFrame(
      bytes: bytes,
      width: width,
      height: height,
      bytesPerRow: width,
      format: RawFrameFormat.nv21,
      rotationDegrees: rotation,
    );
  }

  test('NV21 gris se codifica como JPEG gris', () {
    final jpg = img.decodeJpg(encodeFrameJpeg(nv21(y: 128)))!;
    final pixel = jpg.getPixel(1, 1);

    expect(jpg.width, 4);
    expect(jpg.height, 2);
    expect(pixel.r, closeTo(128, 4));
    expect(pixel.g, closeTo(128, 4));
    expect(pixel.b, closeTo(128, 4));
  });

  test('se gira a vertical según la orientación del sensor', () {
    // Las frontales Android entregan horizontal (270°): el servidor necesita
    // el rostro derecho para que MediaPipe y RetinaFace lo encuentren.
    final jpg = img.decodeJpg(encodeFrameJpeg(nv21(y: 90, rotation: 270)))!;

    expect(jpg.width, 2);
    expect(jpg.height, 4);
  });

  test('BGRA respeta el orden de canales', () {
    // Un píxel azul puro en BGRA es [255, 0, 0, 255].
    final bytes = Uint8List.fromList(
      List.generate(8 * 8, (_) => [255, 0, 0, 255]).expand((p) => p).toList(),
    );
    final jpg = img.decodeJpg(
      encodeFrameJpeg(
        RawFrame(
          bytes: bytes,
          width: 8,
          height: 8,
          bytesPerRow: 8 * 4,
          format: RawFrameFormat.bgra8888,
          rotationDegrees: 0,
        ),
      ),
    )!;
    final pixel = jpg.getPixel(4, 4);

    expect(pixel.b, greaterThan(200));
    expect(pixel.r, lessThan(60));
  });
}
