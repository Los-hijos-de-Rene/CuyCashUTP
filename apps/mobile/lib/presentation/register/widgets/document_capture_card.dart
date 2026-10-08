import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/kyc/domain/document_check.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';

/// Card de captura de un lado del DNI.
///
/// Muestra la foto tomada, no solo un sello de "capturado": el servicio rechaza
/// documentos borrosos, cortados o con reflejos, y sin verla el usuario se
/// entera del problema recién cuando lo rechazan. Verla le permite repetirla
/// antes de gastar un intento.
///
/// Es su propio documento en sus propias manos, y el wizard corre con la
/// ventana marcada como segura, así que no aparece en capturas ni en la vista
/// de apps recientes.
class DocumentCaptureCard extends StatelessWidget {
  const DocumentCaptureCard({
    required this.title,
    required this.hint,
    required this.status,
    this.image,
    this.issue,
    required this.onCapture,
    required this.onRetake,
    super.key,
  });

  final String title;
  final String hint;
  final CaptureStatus status;

  /// Bytes de la foto tomada, si ya hay una.
  final Uint8List? image;

  /// Por qué el servicio rechazó la foto, si la rechazó.
  final DocumentIssue? issue;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unreadable = status == CaptureStatus.unreadable;
    final captured = status == CaptureStatus.captured;
    final checking = status == CaptureStatus.checking;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuyCashColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
        boxShadow: const [
          BoxShadow(color: CuyCashColors.ambientShadow, blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: CuyCashTypography.titleMd.copyWith(fontSize: 16)),
          Text(hint,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.secondaryText)),
          const SizedBox(height: CuyCashSpacing.stackMd),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainer,
                borderRadius: BorderRadius.circular(CuyCashRadii.sm),
                border: Border.all(
                  color: unreadable
                      ? CuyCashColors.error
                      : captured
                          ? CuyCashColors.primaryContainer
                          : CuyCashColors.outlineVariant,
                  width: unreadable || captured ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image case final image?)
                    Image.memory(
                      image,
                      fit: BoxFit.cover,
                      // La foto llega a resolución de cámara; decodificarla
                      // entera para una miniatura desperdicia memoria.
                      cacheWidth: 800,
                    ),
                  Align(
                    alignment: image == null
                        ? Alignment.center
                        : Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(CuyCashSpacing.stackSm),
                      child: checking
                          ? _Pill(
                              label: l10n.documentChecking,
                              color: CuyCashColors.secondaryText,
                              icon: Icons.hourglass_top)
                          : captured
                          ? _Pill(
                              label: l10n.captured,
                              color: CuyCashColors.primaryContainer,
                              icon: Icons.check_circle)
                          : unreadable
                              ? _Pill(
                                  label: l10n.notReadable,
                                  color: CuyCashColors.error,
                                  icon: Icons.error)
                              : const Icon(Icons.photo_camera_outlined,
                                  size: 28,
                                  color: CuyCashColors.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (unreadable) ...[
            const SizedBox(height: CuyCashSpacing.stackMd),
            Text(
                switch (issue) {
                  null => l10n.documentError,
                  final issue => documentIssueText(l10n, issue),
                },
                style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error, fontWeight: FontWeight.w600)),
            const SizedBox(height: CuyCashSpacing.stackSm),
            _tip(l10n.documentTip1),
            _tip(l10n.documentTip2),
            _tip(l10n.documentTip3),
          ],
          const SizedBox(height: CuyCashSpacing.stackMd),
          SecondaryButton(
            label: (captured || unreadable) ? l10n.retakePhoto : l10n.takePhoto,
            // Mientras se revisa no se retoma: la respuesta llegaría tarde para
            // una foto que ya no está.
            onPressed: checking
                ? null
                : (captured || unreadable)
                    ? onRetake
                    : onCapture,
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: SizedBox(
                  width: 6, height: 6,
                  child: DecoratedBox(decoration: BoxDecoration(
                      color: CuyCashColors.secondaryText, shape: BoxShape.circle))),
            ),
            Expanded(
              child: Text(text,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.secondaryText)),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CuyCashColors.onPrimary),
          const SizedBox(width: 6),
          Text(label,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.onPrimary)),
        ],
      ),
    );
  }
}

/// Qué decirle al usuario según por qué no sirvió la foto.
String documentIssueText(AppLocalizations l10n, DocumentIssue issue) =>
    switch (issue) {
      DocumentIssue.lowResolution => l10n.documentIssueLowResolution,
      DocumentIssue.blurry => l10n.documentIssueBlurry,
      DocumentIssue.tooDark => l10n.documentIssueTooDark,
      DocumentIssue.tooBright => l10n.documentIssueTooBright,
      DocumentIssue.noFace => l10n.documentIssueNoFace,
      DocumentIssue.backUnreadable => l10n.documentIssueBackUnreadable,
      DocumentIssue.dniMismatch => l10n.documentIssueDniMismatch,
    };
