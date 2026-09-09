import 'dart:convert';

import 'package:cuycash/feature/kyc/infrastructure/simulated_frame_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Necesario para cargar assets reales del paquete.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('entrega tantos frames como se le piden, todos utilizables', () async {
    final source = SimulatedFrameSource(delayPerFrame: Duration.zero);

    final frames = await source.captureBurst(frames: 8);

    expect(frames, hasLength(8));
    // Base64 decodificable y no vacío: si el servicio real los recibiera, los
    // rechazaría por contenido, no por venir malformados.
    for (final frame in frames) {
      expect(base64Decode(frame), isNotEmpty);
    }
  });

  test('la cantidad la decide quien captura, no la fuente', () async {
    final source = SimulatedFrameSource(delayPerFrame: Duration.zero);

    // Por debajo del mínimo del servicio la tarea se rechaza igual que con
    // cámara real: la simulación no se salta esa regla.
    expect(await source.captureBurst(frames: 4), hasLength(4));
    expect(await source.captureBurst(), hasLength(8));
  });

  test('la imagen de documento sale del mismo origen que los frames',
      () async {
    final documento = await SimulatedFrameSource.sampleDocument();
    final frames = await SimulatedFrameSource(delayPerFrame: Duration.zero)
        .captureBurst(frames: 1);

    expect(documento, isNotEmpty);
    expect(base64Encode(documento), frames.single);
  });
}
