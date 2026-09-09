import 'package:camera/camera.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Estado en que puede estar la cámara antes de poder usarla.
enum CameraStatus { initializing, ready, denied, unavailable }

/// Monta un `CameraController` y lo mantiene vivo mientras la pantalla exista.
///
/// Centraliza tres cosas que se hacen mal con facilidad: liberar el controller
/// al salir (si no, la cámara queda tomada y la siguiente pantalla no abre),
/// distinguir "el usuario negó el permiso" de "no hay cámara", y no mostrar el
/// preview hasta que esté inicializado.
///
/// La resolución se mantiene baja a propósito: cada tarea del liveness sube
/// entre 8 y 10 fotogramas, y la verificación final los manda todos juntos.
class CameraScope extends StatefulWidget {
  const CameraScope({
    required this.lens,
    required this.builder,
    this.resolution = ResolutionPreset.medium,
    super.key,
  });

  final CameraLensDirection lens;

  /// Recibe el controller ya inicializado.
  final Widget Function(BuildContext context, CameraController controller)
      builder;

  final ResolutionPreset resolution;

  @override
  State<CameraScope> createState() => _CameraScopeState();
}

class _CameraScopeState extends State<CameraScope> {
  CameraController? _controller;
  CameraStatus _status = CameraStatus.initializing;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == widget.lens,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        widget.resolution,
        enableAudio: false,
      );
      await controller.initialize();
      // El flash dispararía a la cara en cada uno de los ~40 fotogramas.
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _status = CameraStatus.ready;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _status = switch (error.code) {
            'CameraAccessDenied' ||
            'CameraAccessDeniedWithoutPrompt' ||
            'CameraAccessRestricted' =>
              CameraStatus.denied,
            _ => CameraStatus.unavailable,
          });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = CameraStatus.unavailable);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    return switch (_status) {
      CameraStatus.ready when controller != null =>
        widget.builder(context, controller),
      CameraStatus.initializing || CameraStatus.ready => const Center(
          child: CircularProgressIndicator(
              color: CuyCashColors.immersiveOnDark),
        ),
      CameraStatus.denied => _Message(text: l10n.cameraDenied),
      CameraStatus.unavailable => _Message(text: l10n.cameraUnavailable),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: CuyCashTypography.bodyLg
              .copyWith(color: CuyCashColors.immersiveOnDark),
        ),
      ),
    );
  }
}
