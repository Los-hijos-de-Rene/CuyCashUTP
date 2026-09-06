import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Botón primario (Eucalipto, alto 52). Muestra spinner si [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CuyCashColors.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
