import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Silueta de la tarjeta de movimientos: filas con la forma de un movimiento
/// mientras llega la lista. La usan el inicio y la pantalla de movimientos
/// (primera carga y página siguiente), para que todas las esperas se vean
/// igual.
class MovementsSkeleton extends StatelessWidget {
  const MovementsSkeleton({this.rows = 4, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const Divider(height: 1, color: CuyCashColors.divider),
            const _MovementRowSkeleton(),
          ],
        ],
      ),
    );
  }
}

class _MovementRowSkeleton extends StatelessWidget {
  const _MovementRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Row(
        children: [
          SkeletonBox(width: 40, height: 40, shape: BoxShape.circle),
          SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140),
                SizedBox(height: CuyCashSpacing.stackXs + 2),
                SkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
          SizedBox(width: CuyCashSpacing.stackSm),
          SkeletonBox(width: 64),
        ],
      ),
    );
  }
}
