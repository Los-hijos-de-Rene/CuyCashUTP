import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Indicador de PIN: `count` puntos; los primeros `filled` van rellenos.
class PinDots extends StatelessWidget {
  const PinDots({required this.filled, this.count = 6, super.key});

  final int filled;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isFilled = index < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? CuyCashColors.primaryContainer : null,
            border: isFilled
                ? null
                : Border.all(color: CuyCashColors.outlineVariant, width: 1.5),
          ),
        );
      }),
    );
  }
}
