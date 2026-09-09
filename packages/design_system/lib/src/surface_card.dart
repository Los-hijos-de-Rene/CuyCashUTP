import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';

/// Card blanca con borde suave y la sombra ambiental verde de la marca.
/// Es la superficie base de Inicio y Perfil: agrupa contenido sin usar
/// elevación de Material (el tema tiene `elevation: 0` a propósito).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(CuyCashSpacing.marginMobile),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Cuando no es null la card entera es pulsable (con ripple recortado al
  /// radio, de ahí el `Material` interno).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(CuyCashRadii.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CuyCashColors.surfaceContainerLowest,
        borderRadius: radius,
        border: Border.all(color: CuyCashColors.divider),
        boxShadow: const [
          BoxShadow(
            color: CuyCashColors.ambientShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
