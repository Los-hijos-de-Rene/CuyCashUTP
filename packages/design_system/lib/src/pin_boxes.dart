import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';

/// Casillas visuales del PIN (una por dígito). Refleja cuántos dígitos hay:
/// dígito ingresado = punto lleno; siguiente casilla = borde activo.
class PinBoxes extends StatelessWidget {
  const PinBoxes({required this.pin, this.length = 6, super.key});

  final String pin;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final filled = index < pin.length;
        final active = index == pin.length;
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: CuyCashColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(CuyCashRadii.input),
            border: Border.all(
              color: active
                  ? CuyCashColors.primaryContainer
                  : CuyCashColors.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Center(
            child: filled
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: CuyCashColors.primaryContainer,
                        shape: BoxShape.circle))
                : const SizedBox.shrink(),
          ),
        );
      }),
    );
  }
}
