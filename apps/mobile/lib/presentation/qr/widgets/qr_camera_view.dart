import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';

/// Cámara de escaneo de QR. Solo entrega el primer código válido: el resto de
/// fotogramas se ignoran para no disparar lecturas duplicadas.
class QrCameraView extends StatefulWidget {
  const QrCameraView({required this.onDetected, super.key});

  final ValueChanged<String> onDetected;

  @override
  State<QrCameraView> createState() => _QrCameraViewState();
}

class _QrCameraViewState extends State<QrCameraView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    widget.onDetected(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      errorBuilder: (context, error) => ColoredBox(
        color: CuyCashColors.surfaceContainerHigh,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            child: Text(
              l10n.qrCameraUnavailable,
              textAlign: TextAlign.center,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.secondaryText),
            ),
          ),
        ),
      ),
    );
  }
}
