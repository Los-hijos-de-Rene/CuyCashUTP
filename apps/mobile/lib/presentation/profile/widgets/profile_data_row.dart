import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Par etiqueta/valor de un dato de la cuenta (DNI, alias…).
class ProfileDataRow extends StatelessWidget {
  const ProfileDataRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CuyCashSpacing.marginMobile,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: CuyCashTypography.bodyMd)),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Text(
            value,
            style: CuyCashTypography.bodyLg.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
