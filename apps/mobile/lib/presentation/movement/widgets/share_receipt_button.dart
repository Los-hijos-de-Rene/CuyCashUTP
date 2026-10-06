import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';

/// Comparte el resumen de la constancia como TEXTO. Un render a imagen queda
/// fuera a propósito: el texto cabe en cualquier app y no depende de capturar
/// un widget.
class ShareReceiptButton extends StatelessWidget {
  const ShareReceiptButton({required this.text, this.onShare, super.key});

  final String text;

  /// Para probar sin la hoja nativa. Por defecto abre la de la plataforma.
  final Future<void> Function(String text)? onShare;

  static Future<void> _platformShare(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GhostButton(
      label: l10n.movementShare,
      icon: Icons.ios_share,
      onPressed: () => (onShare ?? _platformShare)(text),
    );
  }
}
