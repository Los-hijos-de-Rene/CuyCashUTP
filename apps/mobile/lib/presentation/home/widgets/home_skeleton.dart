import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../home_action.dart';
import 'movements_skeleton.dart';

/// Silueta del inicio mientras llega la cuenta: saldo, acciones y movimientos
/// en el mismo sitio que ocuparán, para que la pantalla no salte al cargar.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = HomeAction.values.where((a) => a.ready).length;
    return Semantics(
      label: l10n.homeLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 110),
                  SizedBox(height: CuyCashSpacing.stackSm + 4),
                  SkeletonBox(width: 190, height: 36, radius: 8),
                  SizedBox(height: CuyCashSpacing.stackSm + 4),
                  SkeletonBox(width: 130),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Row(
              children: [
                for (var i = 0; i < actions; i++) ...[
                  if (i > 0) const SizedBox(width: CuyCashSpacing.stackSm + 4),
                  const Expanded(
                    child: SurfaceCard(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          SkeletonBox(
                            width: 24,
                            height: 24,
                            shape: BoxShape.circle,
                          ),
                          SizedBox(height: CuyCashSpacing.stackXs + 2),
                          SkeletonBox(width: 48, height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            const SkeletonBox(width: 160, height: 18),
            const SizedBox(height: CuyCashSpacing.stackSm + 4),
            const MovementsSkeleton(),
          ],
        ),
      ),
    );
  }
}
