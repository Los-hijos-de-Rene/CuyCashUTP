import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';

/// Segmentos de progreso de un flujo corto: barras de 4px, el paso activo en
/// eucalipto. Sin números ni texto — con dos o tres pasos, la posición ya lo
/// dice todo.
class StepSegments extends StatelessWidget {
  const StepSegments({
    required this.total,
    required this.current,
    super.key,
  });

  final int total;

  /// Paso activo, empezando en 1. Los anteriores también quedan marcados.
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: CuyCashSpacing.marginMobile),
      child: Row(
        children: [
          for (var step = 1; step <= total; step++) ...[
            if (step > 1) const SizedBox(width: CuyCashSpacing.stackSm),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: step <= current
                      ? CuyCashColors.primaryContainer
                      : CuyCashColors.outlineVariant,
                  borderRadius: BorderRadius.circular(CuyCashRadii.full),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
