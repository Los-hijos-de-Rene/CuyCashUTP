import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';

/// Botón secundario (borde Eucalipto 1.5px, texto Eucalipto).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CuyCashColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: CuyCashColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.button),
        ),
      ),
      child: Text(label),
    );
  }
}
