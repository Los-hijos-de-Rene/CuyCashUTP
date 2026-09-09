import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Avatar circular con iniciales.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.initials,
    this.size = 72,
    this.background = CuyCashColors.surfaceContainerHighest,
    this.foreground = CuyCashColors.primaryContainer,
    super.key,
  });

  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Text(
        initials,
        // La tipografía sigue al diámetro: el mismo widget sirve para el
        // avatar grande del acceso rápido y para el chico de la barra.
        style: CuyCashTypography.headlineSm
            .copyWith(color: foreground, fontSize: size / 3),
      ),
    );
  }
}
