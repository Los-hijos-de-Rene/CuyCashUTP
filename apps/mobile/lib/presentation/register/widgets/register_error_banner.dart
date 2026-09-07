import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Banner de error del formulario (carmín suave).
class RegisterErrorBanner extends StatelessWidget {
  const RegisterErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuyCashColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: CuyCashColors.error),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
            child: Text(message,
                style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
