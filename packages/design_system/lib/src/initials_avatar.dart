import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Avatar circular con iniciales (para el acceso rápido).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.initials, this.size = 72, super.key});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CuyCashColors.surfaceContainerHighest,
      ),
      child: Text(initials,
          style: CuyCashTypography.headlineSm
              .copyWith(color: CuyCashColors.primaryContainer)),
    );
  }
}
