import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Casillas de un código OTP: a diferencia de `PinBoxes` (que oculta el dígito
/// tras un punto) aquí el dígito se ve, porque el código llega por correo y el
/// usuario necesita cotejarlo.
///
/// Es solo la capa visual: quien la use monta encima un único `TextField`
/// invisible, de modo que las seis casillas se comporten como un solo campo
/// (pegar llena todas, escribir avanza, retroceso vuelve).
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({
    required this.code,
    this.length = 6,
    this.hasError = false,
    super.key,
  });

  final String code;
  final int length;

  /// Pinta el borde en carmín (código incorrecto o vencido).
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final filled = index < code.length;
        final active = index == code.length;
        final Color borderColor;
        if (hasError) {
          borderColor = CuyCashColors.error;
        } else if (active) {
          borderColor = CuyCashColors.primaryContainer;
        } else {
          borderColor = CuyCashColors.outlineVariant;
        }
        return Container(
          width: 46,
          height: 56,
          decoration: BoxDecoration(
            color: CuyCashColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(CuyCashRadii.input),
            border: Border.all(
              color: borderColor,
              width: active || hasError ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: filled
              ? Text(
                  code[index],
                  style: CuyCashTypography.headlineSm.copyWith(
                    fontSize: 24,
                    color: CuyCashColors.onSurface,
                  ),
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}
