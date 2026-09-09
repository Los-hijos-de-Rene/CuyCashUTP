import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Fila de opción del perfil (icono + texto + chevron).
class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CuyCashSpacing.marginMobile,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CuyCashColors.primaryContainer),
            const SizedBox(width: CuyCashSpacing.stackSm + 4),
            Expanded(
              child: Text(label,
                  style: CuyCashTypography.bodyLg
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: CuyCashColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
