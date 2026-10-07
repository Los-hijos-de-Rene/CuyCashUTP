import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../l10n/app_localizations.dart';
import 'receipt_card.dart';

/// El "papel" de la constancia: la misma pieza en pantalla y en la imagen que
/// se comparte, para que se vean iguales. Con [forImage] lleva ancho fijo y
/// la cabecera de marca; en pantalla ocupa el ancho disponible.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({required this.card, this.forImage = false, super.key});

  static const width = 360.0;
  static const logoAsset = 'assets/cuycash.png';

  final ReceiptCard card;
  final bool forImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color) = card.statusStyle;
    final lines = card.lines(l10n);
    final paper = ColoredBox(
      color: CuyCashColors.surfaceContainerLow,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Opacity(
                  opacity: 0.08,
                  // El PNG del logo trae fondo claro: multiplicar lo funde
                  // con el papel.
                  child: Image.asset(
                    logoAsset,
                    width: 420,
                    colorBlendMode: BlendMode.multiply,
                    color: CuyCashColors.surfaceContainerLow,
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (forImage)
                ColoredBox(
                  color: CuyCashColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CuyCashSpacing.marginMobile,
                      vertical: CuyCashSpacing.stackLg,
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: ColoredBox(
                            color: Colors.white,
                            child: Image.asset(
                              logoAsset,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: CuyCashSpacing.stackMd),
                        Expanded(
                          child: Text(
                            l10n.movementShareHeader,
                            style: CuyCashTypography.titleMd.copyWith(
                              color: CuyCashColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: CuyCashSpacing.stackSm),
                    Icon(icon, size: 56, color: color),
                    const SizedBox(height: CuyCashSpacing.stackSm),
                    Text(
                      card.headline,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.headlineSm,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackXs),
                    Text(
                      formatMoney(card.monto),
                      style: CuyCashTypography.headlineMd,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackLg),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CuyCashColors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CuyCashSpacing.stackMd,
                          vertical: CuyCashSpacing.stackSm,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < lines.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  color: CuyCashColors.outlineVariant,
                                ),
                              _ImageLine(
                                label: lines[i].$1,
                                value: lines[i].$2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (card.reutilizada && !forImage) ...[
                      const SizedBox(height: CuyCashSpacing.stackMd),
                      InfoStrip(
                        icon: Icons.info_outline,
                        text: l10n.transferReceiptReused,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (forImage) return SizedBox(width: width, child: paper);
    return ClipRRect(borderRadius: BorderRadius.circular(20), child: paper);
  }
}

class _ImageLine extends StatelessWidget {
  const _ImageLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CuyCashSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CuyCashTypography.bodyMd.copyWith(
              color: CuyCashColors.secondaryText,
            ),
          ),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: CuyCashTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
