import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/frame_source.dart';

/// `FrameSource` para el flavor `mock`: devuelve una imagen de relleno en lugar
/// de abrir la cámara.
///
/// Existe porque el simulador de iOS no tiene cámara y muchos emuladores dan
/// una imagen inservible. Sin esto, el registro se queda encallado en el paso 3
/// justo donde más falta hace poder recorrerlo: al demostrarlo o al desarrollar
/// las pantallas siguientes.
///
/// NO es un atajo para saltarse la verificación: solo se usa con el
/// `MemoryKycRepository`, que valida el orden y los reintentos igual que el
/// servicio. Contra un servidor real estos frames serían rechazados, que es
/// exactamente lo que debe pasar.
class SimulatedFrameSource implements FrameSource {
  SimulatedFrameSource({
    this.assetPath = 'assets/cuycash.png',
    this.delayPerFrame = const Duration(milliseconds: 60),
  });

  final String assetPath;

  /// Se imita el coste de capturar para que la UI se vea como en un teléfono
  /// real: si respondiera al instante, los estados de "capturando" no se
  /// podrían revisar.
  final Duration delayPerFrame;

  String? _cached;

  @override
  Future<List<String>> captureBurst({int frames = 8}) async {
    final frame = _cached ??= base64Encode(await _loadAsset());
    final captured = <String>[];
    for (var i = 0; i < frames; i++) {
      await Future<void>.delayed(delayPerFrame);
      captured.add(frame);
    }
    return captured;
  }

  Future<Uint8List> _loadAsset() async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  /// Imagen de relleno para el documento, del mismo origen que los frames.
  static Future<Uint8List> sampleDocument({
    String assetPath = 'assets/cuycash.png',
  }) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}
