import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/face_observation.dart';
import '../domain/face_tracker.dart';

/// `FaceTracker` del flavor `mock`: un "usuario" de mentira que repite en
/// bucle todos los gestos, sin abrir la cámara.
///
/// Existe porque el simulador de iOS no tiene cámara y muchos emuladores dan
/// una imagen inservible. Sin esto, el registro se queda encallado en el paso
/// del rostro justo donde más falta hace poder recorrerlo.
///
/// Como el guion recorre TODOS los gestos, cualquier desafío se completa en
/// a lo sumo dos vueltas, sea cual sea el orden que pidió el servidor.
///
/// NO es un atajo para saltarse la verificación: solo se usa con el
/// `MemoryKycRepository`. Contra un servidor real, estos fotogramas (el logo de
/// la app) serían rechazados, que es exactamente lo que debe pasar.
class SimulatedFaceTracker implements FaceTracker {
  SimulatedFaceTracker({
    this.assetPath = 'assets/cuycash.png',
    this.tick = const Duration(milliseconds: 100),
  });

  final String assetPath;
  final Duration tick;

  final _observations = StreamController<FaceObservation>.broadcast();
  Timer? _timer;
  var _frame = 0;
  String? _cached;

  /// Una vuelta del guion, una entrada por tick.
  static final List<FaceObservation Function(int id)> _script = [
    for (var i = 0; i < 12; i++) _frontal,
    for (var i = 0; i < 6; i++) (id) => _frontal(id, yaw: 0.22),
    for (var i = 0; i < 8; i++) _frontal,
    for (var i = 0; i < 6; i++) (id) => _frontal(id, yaw: -0.22),
    for (var i = 0; i < 8; i++) _frontal,
    for (var i = 0; i < 2; i++) (id) => _frontal(id, eyes: 0.05),
    for (var i = 0; i < 8; i++) _frontal,
    for (var i = 0; i < 6; i++) (id) => _frontal(id, pitch: 20),
    for (var i = 0; i < 8; i++) _frontal,
    for (var i = 0; i < 6; i++) (id) => _frontal(id, pitch: -20),
    for (var i = 0; i < 8; i++) _frontal,
  ];

  static FaceObservation _frontal(
    int id, {
    double yaw = 0,
    double pitch = 0,
    double eyes = 0.95,
  }) =>
      FaceObservation(
        frameId: id,
        faceCount: 1,
        centerX: 0.5,
        centerY: 0.48,
        widthRatio: 0.45,
        yaw: yaw,
        pitchDegrees: pitch,
        leftEyeOpen: eyes,
        rightEyeOpen: eyes,
      );

  @override
  Stream<FaceObservation> get observations => _observations.stream;

  @override
  Future<void> start() async {
    _timer ??= Timer.periodic(tick, (_) {
      final id = _frame++;
      _observations.add(_script[id % _script.length](id));
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _observations.close();
  }

  @override
  Future<String?> keepFrame(int frameId) async =>
      _cached ??= base64Encode(await _loadAsset(assetPath));

  /// Imagen de relleno para el documento en `mock`, del mismo origen.
  static Future<Uint8List> sampleDocument({
    String assetPath = 'assets/cuycash.png',
  }) =>
      _loadAsset(assetPath);

  static Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }
}
