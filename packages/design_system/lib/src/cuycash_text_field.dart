import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Input con label persistente arriba (DESIGN.md). Errores en carmín.
/// Soporta ícono leading, límite de caracteres y helper text.
class CuyCashTextField extends StatelessWidget {
  const CuyCashTextField({
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
    this.maxLength,
    this.helperText,
    this.autofocus = false,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final int? maxLength;
  final String? helperText;
  final bool autofocus;

  /// Acción de confirmación del teclado del sistema.
  final ValueChanged<String>? onSubmitted;

  /// Filtros propios del campo, además del `digitsOnly` que ya aplica el
  /// teclado numérico entero.
  final List<TextInputFormatter>? inputFormatters;

  /// `false` deja el campo de solo lectura (p. ej. una intención sellada).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CuyCashTypography.labelMd),
        const SizedBox(height: CuyCashSpacing.stackSm),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofocus: autofocus,
          maxLength: maxLength,
          inputFormatters: [
            if (keyboardType == TextInputType.number)
              FilteringTextInputFormatter.digitsOnly,
            ...?inputFormatters,
          ],
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: CuyCashColors.outline, size: 20),
          ),
        ),
      ],
    );
  }
}
