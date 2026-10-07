import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Silueta del resultado de buscar un DNI o alias mientras llega: el nombre,
/// el alias y dos tarjetas de cuenta, en el mismo sitio donde aparecerán.
///
/// [semanticsLabel] reemplaza al del indicador circular de antes: el lector
/// de pantalla sigue anunciando que se está buscando.
class RecipientSkeleton extends StatelessWidget {
  const RecipientSkeleton({required this.semanticsLabel, super.key});

  final String semanticsLabel;

  static const _cuentas = 2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 150, height: 18),
            const SizedBox(height: CuyCashSpacing.stackXs + 2),
            const SkeletonBox(width: 90, height: 12),
            const SizedBox(height: CuyCashSpacing.stackXs),
            const SkeletonBox(width: 180, height: 12),
            const SizedBox(height: CuyCashSpacing.stackSm),
            for (var i = 0; i < _cuentas; i++) ...[
              const SurfaceCard(
                child: Row(
                  children: [
                    SkeletonBox(width: 24, height: 24, shape: BoxShape.circle),
                    SizedBox(width: CuyCashSpacing.stackMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 160),
                          SizedBox(height: CuyCashSpacing.stackXs + 2),
                          SkeletonBox(width: 100, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
            ],
          ],
        ),
      ),
    );
  }
}
