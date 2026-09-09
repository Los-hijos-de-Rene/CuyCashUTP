import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'widgets/camera_scope.dart';

/// Captura de una cara del DNI con la cámara trasera.
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
          builder: (context, controller) => _Capture(
            controller: controller,
            hint: l10n.documentSubtitle,
            label: l10n.takePhoto,
          ),
        ),
      ),
    );
  }
}

class _Capture extends StatefulWidget {
  const _Capture({
    required this.controller,
    required this.hint,
    required this.label,
  });

  final CameraController controller;
  final String hint;
  final String label;

  @override
  State<_Capture> createState() => _CaptureState();
}

class _CaptureState extends State<_Capture> {
  bool _busy = false;

  Future<void> _take() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final shot = await widget.controller.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } on CameraException catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: CameraPreview(widget.controller)),
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
