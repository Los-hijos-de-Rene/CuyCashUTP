import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Botón ghost (solo texto Eucalipto, sin fondo).
class GhostButton extends StatelessWidget {
  const GhostButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: CuyCashColors.primary),
      child: Text(label),
    );
  }
}
