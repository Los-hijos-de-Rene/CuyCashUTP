import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Botón ghost (solo texto Eucalipto, sin fondo). Con [icon] lo antepone al
/// texto.
class GhostButton extends StatelessWidget {
  const GhostButton({
    required this.label,
    this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Icono a la izquierda del texto. Opcional.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(foregroundColor: CuyCashColors.primary);
    if (icon == null) {
      return TextButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
