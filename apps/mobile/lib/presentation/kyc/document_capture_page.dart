import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/env/app_flavor.dart';
import '../../feature/kyc/infrastructure/document_cropper.dart';
import '../../feature/kyc/infrastructure/simulated_face_tracker.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/camera_scope.dart';
import 'widgets/cover_camera_preview.dart';
import 'widgets/document_frame_overlay.dart';

/// Captura de una cara del DNI con la cámara trasera, con un marco de la
/// proporción de la tarjeta. La foto se recorta a ese marco antes de salir:
/// al servidor llega el documento, no la mesa.
///
/// Devuelve los bytes del JPEG por `Navigator.pop`, o null si el usuario se
/// arrepiente. La imagen NO se guarda en disco: viaja en memoria hasta que se
/// manda a verificar y ahí se suelta.
class DocumentCapturePage extends StatelessWidget {
  const DocumentCapturePage({required this.title, super.key});

  /// Qué cara se está capturando, para que la barra lo diga.
  final String title;

  static Future<Uint8List?> open(BuildContext context, String title) =>
      Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => DocumentCapturePage(title: title)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.immersiveDark,
      appBar: AppBar(
        backgroundColor: CuyCashColors.immersiveDark,
        foregroundColor: CuyCashColors.immersiveOnDark,
        title: Text(title, style: CuyCashTypography.titleMd.copyWith(
            color: CuyCashColors.immersiveOnDark, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CameraScope(
          lens: CameraLensDirection.back,
          // Alta a propósito: el servidor exige al menos 600×400 del
          // documento, y en media (720×480) la foto vertical no llegaba ni a
          // 600 de ancho, así que el DNI siempre salía "inválido".
          resolution: ResolutionPreset.veryHigh,
          builder: (context, controller) => _Capture(
            controller: controller,
            frameHint: l10n.documentTip3,
            hint: l10n.documentSubtitle,
            label: l10n.takePhoto,
          ),
          // En `mock` se puede seguir sin cámara: el paso 3 necesita SÍ o SÍ
          // una imagen de documento contra la que comparar el rostro.
          unavailableBuilder:
              context.read<AppFlavor>() == AppFlavor.mock ? _sample : null,
        ),
      ),
    );
  }
}

/// Salida del flavor `mock`: entrega una imagen de relleno como si se hubiera
/// fotografiado el documento.
Widget _sample(BuildContext context, CameraStatus status) {
  final l10n = AppLocalizations.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.cameraSimulated,
            textAlign: TextAlign.center,
            style: CuyCashTypography.bodyLg
                .copyWith(color: CuyCashColors.immersiveMuted),
          ),
          const SizedBox(height: CuyCashSpacing.stackLg),
          PrimaryButton(
            label: l10n.useSampleDocument,
            onPressed: () async {
              final bytes = await SimulatedFaceTracker.sampleDocument();
              if (context.mounted) Navigator.of(context).pop(bytes);
            },
          ),
        ],
      ),
    ),
  );
}

class _Capture extends StatefulWidget {
  const _Capture({
    required this.controller,
    required this.frameHint,
    required this.hint,
    required this.label,
  });

  final CameraController controller;
  final String frameHint;
  final String hint;
  final String label;

  @override
  State<_Capture> createState() => _CaptureState();
}

class _CaptureState extends State<_Capture> {
  bool _busy = false;

  /// Tamaño del recuadro de la vista previa: con él se traduce el marco de
  /// pantalla a la foto.
  Size? _viewport;

  Future<void> _take() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final shot = await widget.controller.takePicture();
      final photo = await shot.readAsBytes();
      // La foto del DNI es un dato personal: no se deja en la caché.
      await _deleteQuietly(shot.path);
      final bytes = await _cropToFrame(photo);
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } on CameraException catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _cropToFrame(Uint8List photo) async {
    final viewport = _viewport;
    final content = CoverCameraPreview.portraitSizeOf(widget.controller);
    if (viewport == null || content == null) return photo;
    return cropDocument(
      photo,
      normalizedCropFor(
        frame: documentFrameFor(viewport),
        viewport: viewport,
        content: content,
      ),
    );
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Si no se puede borrar, queda en la caché de la app, que el sistema
      // recoge; no se interrumpe la captura por eso.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _viewport = constraints.biggest;
              return Stack(
                fit: StackFit.expand,
                children: [
                  CoverCameraPreview(controller: widget.controller),
                  DocumentFrameOverlay(hint: widget.frameHint),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Column(
            children: [
              Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: CuyCashTypography.labelSm
                    .copyWith(color: CuyCashColors.immersiveMuted),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              PrimaryButton(
                label: widget.label,
                loading: _busy,
                onPressed: _take,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
