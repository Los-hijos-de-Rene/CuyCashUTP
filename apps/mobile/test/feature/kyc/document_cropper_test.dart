import 'dart:typed_data';
import 'dart:ui';

import 'package:cuycash/feature/kyc/infrastructure/document_cropper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('el marco tiene la proporción del DNI y entra en la pantalla', () {
    const viewport = Size(400, 700);
    final frame = documentFrameFor(viewport);

    expect(frame.width / frame.height, closeTo(kIdCardAspectRatio, 0.001));
    expect(frame.left, greaterThanOrEqualTo(0));
    expect(frame.right, lessThanOrEqualTo(viewport.width));
    expect(frame.center.dx, viewport.width / 2);
  });

  test('sin recorte del cover, el marco se traduce tal cual', () {
    // Pantalla y vista previa con la misma proporción: escala pura.
    final rect = normalizedCropFor(
      frame: const Rect.fromLTWH(100, 200, 200, 100),
      viewport: const Size(400, 800),
      content: const Size(1080, 2160),
      margin: 0,
    );

    expect(rect.left, closeTo(0.25, 1e-9));
    expect(rect.top, closeTo(0.25, 1e-9));
    expect(rect.width, closeTo(0.5, 1e-9));
    expect(rect.height, closeTo(0.125, 1e-9));
  });

  test('deshace el BoxFit.cover: la foto es más alta que la pantalla', () {
    // Vista previa 1080×1920 mostrada en 400×600: escala 400/1080, se ve
    // 400×711 y se recortan 55,5 px arriba y abajo.
    const viewport = Size(400, 600);
    const content = Size(1080, 1920);
    final rect = normalizedCropFor(
      frame: const Rect.fromLTWH(0, 0, 400, 600),
      viewport: viewport,
      content: content,
      margin: 0,
    );

    final shownHeight = 1920 * (400 / 1080);
    final cut = (shownHeight - 600) / 2 / shownHeight;
    expect(rect.left, closeTo(0, 1e-9));
    expect(rect.right, closeTo(1, 1e-9));
    expect(rect.top, closeTo(cut, 1e-9));
    expect(rect.bottom, closeTo(1 - cut, 1e-9));
  });

  test('el margen nunca sale de la foto', () {
    final rect = normalizedCropFor(
      frame: const Rect.fromLTWH(0, 0, 400, 800),
      viewport: const Size(400, 800),
      content: const Size(1080, 2160),
    );

    expect(rect, const Rect.fromLTWH(0, 0, 1, 1));
  });

  test('recorta la foto a la región pedida y limita el ancho', () {
    final photo = img.encodeJpg(img.Image(width: 4000, height: 3000));

    final out = img.decodeJpg(
      cropDocumentSync(
        photo,
        const Rect.fromLTWH(0.1, 0.2, 0.8, 0.5),
        maxWidth: 1600,
      ),
    )!;

    expect(out.width, 1600);
    expect(out.height, closeTo(1500 * 1600 / 3200, 1));
  });

  test('si la foto no se puede leer, devuelve la original', () {
    final basura = Uint8List.fromList([1, 2, 3]);

    expect(cropDocumentSync(basura, const Rect.fromLTWH(0, 0, 1, 1)), basura);
  });
}
