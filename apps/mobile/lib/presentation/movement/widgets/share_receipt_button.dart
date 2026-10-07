import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_localizations.dart';
import 'receipt_card.dart';
import 'receipt_image_capture.dart';

/// Comparte la constancia como IMAGEN. Si no se puede dibujar o la hoja de
/// imagen falla, cae al resumen en texto en vez de no compartir nada.
class ShareReceiptButton extends StatefulWidget {
  const ShareReceiptButton({required this.card, this.onShare, super.key});

  final ReceiptCard card;

  /// Para probar sin la hoja nativa: recibe el PNG y el texto de respaldo.
  final Future<void> Function(Uint8List png, String text)? onShare;

  @override
  State<ShareReceiptButton> createState() => _ShareReceiptButtonState();
}

class _ShareReceiptButtonState extends State<ShareReceiptButton> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final text = widget.card.shareText(l10n);
    setState(() => _busy = true);
    try {
      final png = await captureReceiptPng(context, widget.card);
      final custom = widget.onShare;
      if (custom != null) {
        await custom(png, text);
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png')],
            fileNameOverrides: ['constancia-cuycash.png'],
            sharePositionOrigin: origin,
          ),
        );
      }
    } catch (_) {
      try {
        await SharePlus.instance.share(
          ShareParams(text: text, sharePositionOrigin: origin),
        );
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.movementShareFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GhostButton(
      label: l10n.movementShare,
      icon: Icons.ios_share,
      onPressed: _busy ? null : _share,
    );
  }
}
