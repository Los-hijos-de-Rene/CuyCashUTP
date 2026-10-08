import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Vista previa que LLENA el recuadro, recortando lo que sobra.
///
/// `CameraPreview` impone su propia proporción; dentro de un recuadro de otra
/// proporción se deformaría la imagen. El sensor entrega horizontal y la app
/// va en vertical, por eso se intercambian ancho y alto.
///
/// Quien recorte la foto a lo que se ve (el marco del documento) debe deshacer
/// este mismo `BoxFit.cover`: ver `normalizedCropFor`.
class CoverCameraPreview extends StatelessWidget {
  const CoverCameraPreview({required this.controller, super.key});

  final CameraController controller;

  /// Tamaño de la vista previa en vertical, o null si aún no se conoce.
  static Size? portraitSizeOf(CameraController controller) {
    final size = controller.value.previewSize;
    return size == null ? null : Size(size.height, size.width);
  }

  @override
  Widget build(BuildContext context) {
    final size = portraitSizeOf(controller);
    if (size == null) return CameraPreview(controller);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
