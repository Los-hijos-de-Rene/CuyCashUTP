import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Barra de progreso de 4 segmentos (paso actual = índice 0..3, inclusive).
class RegisterProgressBar extends StatelessWidget {
  const RegisterProgressBar({required this.step, this.dark = false, super.key});

  final int step;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final active = dark ? CuyCashColors.immersiveOcre : CuyCashColors.primaryContainer;
    final inactive = dark ? CuyCashColors.immersivePanel : CuyCashColors.surfaceContainerHighest;
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: index <= step ? active : inactive,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
