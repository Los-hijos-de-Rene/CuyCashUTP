import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Tono del `InfoStrip`: `neutral` informa, `success` tranquiliza.
enum InfoStripTone { neutral, success }

/// Franja informativa (icono + texto) sobre fondo suave. Se usa para los avisos
/// que acompañan al OTP y a las pantallas de flujo cancelado.
class InfoStrip extends StatelessWidget {
  const InfoStrip({
    required this.icon,
    required this.text,
    this.tone = InfoStripTone.neutral,
    super.key,
  });

  final IconData icon;
  final String text;
  final InfoStripTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      InfoStripTone.neutral => CuyCashColors.surfaceContainerHigh,
      InfoStripTone.success => CuyCashColors.successSoft,
    };
    final iconColor = switch (tone) {
      InfoStripTone.neutral => CuyCashColors.secondaryText,
      InfoStripTone.success => CuyCashColors.success,
    };
    final textStyle = switch (tone) {
      InfoStripTone.neutral => CuyCashTypography.bodyMd
          .copyWith(color: CuyCashColors.onSurface),
      InfoStripTone.success => CuyCashTypography.bodyMd.copyWith(
          color: CuyCashColors.onSurface, fontWeight: FontWeight.w500),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(child: Text(text, style: textStyle)),
        ],
      ),
    );
  }
}
