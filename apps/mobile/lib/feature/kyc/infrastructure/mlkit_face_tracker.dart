import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../domain/face_observation.dart';
import '../domain/face_tracker.dart';
import 'frame_encoder.dart';

/// `FaceTracker` real: stream de la cámara frontal + ML Kit en el teléfono.
///
/// ML Kit solo GUÍA (encuadre, cuándo pasar al siguiente gesto). Lo que decide
/// es el servidor, con los fotogramas clave que se le envían al final.
///
/// POR QUÉ STREAM Y NO `takePicture()`: ML Kit lee el `CameraImage` tal cual
/// (NV21 en Android, BGRA en iOS), sin convertirlo a JPEG, así que analizar
/// cada fotograma es barato. Solo se codifican a JPEG —en un isolate— los
/// pocos que se envían. Con `takePicture()` cada toma tardaba ~300 ms y
/// congelaba la vista previa: el usuario no podía hacer el gesto con fluidez.
///
/// La cámara debe abrirse con `ImageFormatGroup.nv21` en Android y
/// `ImageFormatGroup.bgra8888` en iOS (ver [preferredFormat]).
class MlKitFaceTracker implements FaceTracker {
  MlKitFaceTracker(
    this._controller, {
    FaceDetector? detector,
    this.bufferSize = 10,
  }) : _detector = detector ??
            FaceDetector(
              options: FaceDetectorOptions(
                enableClassification: true, // ojos abiertos/cerrados
                enableLandmarks: true, // nariz y mejillas para el giro
                performanceMode: FaceDetectorMode.fast,
                minFaceSize: 0.15,
              ),
            );

  /// Formato que este tracker sabe leer en la plataforma actual.
  static ImageFormatGroup get preferredFormat => Platform.isIOS
      ? ImageFormatGroup.bgra8888
      : ImageFormatGroup.nv21;

  final CameraController _controller;
  final FaceDetector _detector;

  /// Cuántos fotogramas analizados se conservan para poder pedir su JPEG.
  final int bufferSize;

  final _observations = StreamController<FaceObservation>.broadcast();
  // Un literal de mapa es un LinkedHashMap: conserva el orden de inserción,
  // que es lo que permite descartar el fotograma más viejo.
  final _recent = <int, RawFrame>{};
  var _nextId = 0;
  var _busy = false;
  var _running = false;

  @override
  Stream<FaceObservation> get observations => _observations.stream;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      await _controller.startImageStream(_onImage);
    } on CameraException catch (error) {
      _running = false;
      throw FaceTrackerException(error.description ?? error.code);
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    _recent.clear();
    if (_controller.value.isStreamingImages) {
      try {
        // Con tope: si `stopImageStream` no vuelve, quien espera aquí es el
        // envío de la verificación, y el usuario se queda en "Confirmando…"
        // para siempre. Pasado el tope el stream ya no entrega nada a este
        // tracker (`_running` es false) y se sigue.
        await _controller.stopImageStream().timeout(_stopTimeout);
      } on TimeoutException {
        debugPrint('Liveness: stopImageStream no respondió en $_stopTimeout');
      } on CameraException catch (_) {
        // La cámara ya se estaba cerrando: no hay nada que detener.
      }
    }
  }

  static const _stopTimeout = Duration(seconds: 2);

  @override
  Future<void> dispose() async {
    await stop();
    await _detector.close();
    await _observations.close();
  }

  @override
  Future<String?> keepFrame(int frameId) async {
    final raw = _recent[frameId];
    if (raw == null) return null;
    try {
      return await encodeFrameAsBase64Jpeg(raw);
    } catch (error) {
      // Un fotograma que no se pudo codificar no tumba el envío: el servidor
      // juzgará el segmento con los que sí llegaron.
      debugPrint('Liveness: no se pudo codificar el fotograma $frameId ($error)');
      return null;
    }
  }

  void _onImage(CameraImage image) {
    // Mientras ML Kit procesa un fotograma, los siguientes se descartan: así
    // la cadencia se ajusta sola a lo que aguante el teléfono.
    if (_busy || !_running) return;
    final raw = _copy(image);
    if (raw == null) return;

    _busy = true;
    final id = _nextId++;
    _recent[id] = raw;
    while (_recent.length > bufferSize) {
      _recent.remove(_recent.keys.first);
    }
    _analyze(id, raw).whenComplete(() => _busy = false);
  }

  Future<void> _analyze(int id, RawFrame raw) async {
    final input = InputImage.fromBytes(
      bytes: raw.bytes,
      metadata: InputImageMetadata(
        size: Size(raw.width.toDouble(), raw.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(raw.rotationDegrees) ??
            InputImageRotation.rotation0deg,
        format: raw.format == RawFrameFormat.nv21
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: raw.bytesPerRow,
      ),
    );
    try {
      final faces = await _detector.processImage(input);
      if (_running && !_observations.isClosed) {
        _observations.add(observe(
          id,
          faces,
          uprightSize(raw),
          mirrored: streamMirrored(isIOS: Platform.isIOS),
        ));
      }
    } catch (error) {
      // Un fotograma que ML Kit no pudo leer no corta el flujo: llega el
      // siguiente en milisegundos.
      debugPrint('ML Kit: fotograma descartado ($error)');
    }
  }

  /// Copia el fotograma a un buffer propio (el del plugin se recicla).
  RawFrame? _copy(CameraImage image) {
    final rotation = frameRotation(
      isIOS: Platform.isIOS,
      sensorOrientation: _controller.description.sensorOrientation,
    );
    final mirrored = streamMirrored(isIOS: Platform.isIOS);
    final group = image.format.group;

    if (group == ImageFormatGroup.bgra8888 && image.planes.length == 1) {
      final plane = image.planes.first;
      return RawFrame(
        bytes: Uint8List.fromList(plane.bytes),
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
        format: RawFrameFormat.bgra8888,
        rotationDegrees: rotation,
        mirrored: mirrored,
      );
    }
    if (group == ImageFormatGroup.nv21 && image.planes.length == 1) {
      final plane = image.planes.first;
      return RawFrame(
        bytes: Uint8List.fromList(plane.bytes),
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
        format: RawFrameFormat.nv21,
        rotationDegrees: rotation,
        mirrored: mirrored,
      );
    }
    if (image.planes.length == 3) {
      // YUV_420_888 en tres planos: algunos teléfonos ignoran el pedido de
      // NV21. Se arma a mano para no dejar al usuario sin verificación.
      return RawFrame(
        bytes: _yuv420ToNv21(image),
        width: image.width,
        height: image.height,
        bytesPerRow: image.width,
        format: RawFrameFormat.nv21,
        rotationDegrees: rotation,
        mirrored: mirrored,
      );
    }
    return null;
  }

  static Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final out = Uint8List(width * height * 3 ~/ 2);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    var o = 0;
    for (var row = 0; row < height; row++) {
      out.setRange(o, o + width, yPlane.bytes, row * yPlane.bytesPerRow);
      o += width;
    }
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < height ~/ 2; row++) {
      for (var col = 0; col < width ~/ 2; col++) {
        final i = row * uPlane.bytesPerRow + col * uvPixelStride;
        out[o++] = vPlane.bytes[i];
        out[o++] = uPlane.bytes[i];
      }
    }
    return out;
  }

  /// Giro horario que deja vertical un fotograma del stream.
  ///
  /// - Android: los fotogramas llegan como los da el sensor ("acostados");
  ///   con la app fija en vertical, el giro es la orientación del sensor
  ///   (270° en casi todas las frontales).
  /// - iOS: el stream ya llega DERECHO. Girarlo por la orientación del sensor
  ///   lo acostaba: visto en un iPhone (2026-10-08), el servidor medía giros
  ///   de cabeza de -52 (lo normal es entre -1 y 1, señal de una cara de lado)
  ///   y la comparación con el DNI daba distancias de ~1.0. ML Kit en iOS
  ///   ignora la rotación que se le pasa y aun así detectaba la cara: por eso
  ///   los gestos pasaban y solo fallaba el servidor.
  /// Si el stream de la cámara frontal llega en espejo: en iOS sí, en Android
  /// no. Verificado en un iPhone (2026-10-08): sin tenerlo en cuenta, el
  /// teléfono veía los giros al revés y el servidor también, que midió
  /// "derecha" con signo positivo en 4 de 4 intentos. Se usa para el giro que
  /// ve ML Kit y para quitar el espejo a los fotogramas que se envían.
  @visibleForTesting
  static bool streamMirrored({required bool isIOS}) => isIOS;

  @visibleForTesting
  static int frameRotation({
    required bool isIOS,
    required int sensorOrientation,
  }) =>
      isIOS ? 0 : sensorOrientation;

  /// Tamaño de la imagen ya girada a vertical: es el espacio de coordenadas
  /// en que ML Kit devuelve los rostros.
  @visibleForTesting
  static Size uprightSize(RawFrame raw) => raw.rotationDegrees % 180 == 0
      ? Size(raw.width.toDouble(), raw.height.toDouble())
      : Size(raw.height.toDouble(), raw.width.toDouble());

  /// Resume lo que vio ML Kit. Con varios rostros, las medidas son las del más
  /// grande, pero [FaceObservation.faceCount] deja ver que hay más de uno.
  ///
  /// [mirrored]: el stream llega en espejo (cámara frontal de iOS). Espejar
  /// intercambia el lado de la imagen en que cae cada mejilla, así que el
  /// giro cambia de signo; sin esto, en iOS "gira a tu derecha" solo pasaba
  /// girando a la izquierda.
  @visibleForTesting
  static FaceObservation observe(
    int frameId,
    List<Face> faces,
    Size size, {
    bool mirrored = false,
  }) {
    if (faces.isEmpty) return FaceObservation.empty(frameId);
    final face = faces.reduce((a, b) =>
        a.boundingBox.width >= b.boundingBox.width ? a : b);
    final box = face.boundingBox;
    return FaceObservation(
      frameId: frameId,
      faceCount: faces.length,
      centerX: box.center.dx / size.width,
      centerY: box.center.dy / size.height,
      widthRatio: box.width / size.width,
      yaw: mirrored ? -_yaw(face) : _yaw(face),
      pitchDegrees: face.headEulerAngleX ?? 0,
      leftEyeOpen: face.leftEyeOpenProbability,
      rightEyeOpen: face.rightEyeOpenProbability,
    );
  }

  /// Giro lateral: nariz respecto al centro de las mejillas, sobre el ancho
  /// entre mejillas. Positivo = el usuario gira a SU izquierda.
  ///
  /// El denominador es `rightCheek - leftCheek`, y el signo está VERIFICADO EN
  /// UN TELÉFONO (Android, cámara frontal, 2026-10-07): con
  /// `leftCheek - rightCheek` —leyendo los nombres de ML Kit como "la mejilla
  /// izquierda del usuario"— "gira a tu derecha" solo pasaba girando a la
  /// izquierda. En las coordenadas que devuelve ML Kit, `leftCheek` queda a la
  /// izquierda de la IMAGEN. No volver a "corregirlo" por la documentación sin
  /// probar en un dispositivo; lo fija `mlkit_face_tracker_test.dart`.
  static double _yaw(Face face) {
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final left = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final right = face.landmarks[FaceLandmarkType.rightCheek]?.position;
    if (nose == null || left == null || right == null) return 0;
    final width = (right.x - left.x).toDouble();
    if (width.abs() < 1) return 0;
    final mid = (left.x + right.x) / 2;
    return (nose.x - mid) / width;
  }
}
