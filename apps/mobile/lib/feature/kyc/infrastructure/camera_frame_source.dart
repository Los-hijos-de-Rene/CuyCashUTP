import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';

import '../domain/frame_source.dart';

/// Captura ráfagas con la cámara frontal usando `takePicture()` en bucle.
///
/// POR QUÉ ASÍ Y NO CON `startImageStream`: el stream entrega `CameraImage` en
/// YUV420 (Android) o BGRA8888 (iOS), y convertirlo a JPEG en Dart cuesta
/// cientos de milisegundos por frame — justo en los teléfonos de gama baja que
/// este servicio dice querer soportar. `takePicture()` devuelve JPEG ya
/// codificado por el hardware; es más lento por frame pero no quema CPU ni
/// arriesga quedarse sin memoria.
///
/// La contrapartida es que una ráfaga de 8-10 frames tarda ~2-4 s en vez de los
/// 1,5 s que sugiere el servicio. No rompe nada: lo que el análisis necesita es
/// que el movimiento quede registrado a lo largo de la secuencia, no una
/// cadencia exacta. Si en pruebas reales resulta insuficiente, el siguiente
/// paso es codificar el JPEG en nativo, no volver al stream en Dart.
class CameraFrameSource implements FrameSource {
  CameraFrameSource(this._controller);

  final CameraController _controller;

  @override
  Future<List<String>> captureBurst({int frames = 8}) async {
    if (!_controller.value.isInitialized) {
      throw const FrameCaptureException('La cámara no está lista');
    }

    final captured = <String>[];
    for (var i = 0; i < frames; i++) {
      try {
        final shot = await _controller.takePicture();
        final bytes = await shot.readAsBytes();
        captured.add(base64Encode(bytes));
        // El plugin escribe cada toma en un archivo temporal. Se borra en
        // cuanto se leyó: un frame del rostro no debe quedar en el disco.
        await _deleteQuietly(shot.path);
      } on CameraException catch (error) {
        throw FrameCaptureException(error.description ?? error.code);
      }
    }
    return captured;
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Si el sistema de archivos no deja borrarlo, no se interrumpe el flujo:
      // queda en la caché de la app, que el sistema recoge.
    }
  }
}
