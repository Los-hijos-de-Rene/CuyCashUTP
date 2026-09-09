import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/format/soles.dart';
import '../../../l10n/app_localizations.dart';
import '../demo_wallet.dart';

/// Lista de últimos movimientos (maqueta del Sprint 2).
class MovementsCard extends StatelessWidget {
  const MovementsCard({required this.movements, super.key});

  final List<DemoMovement> movements;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, movement) in movements.indexed) ...[
            if (index > 0)
              const Divider(height: 1, color: CuyCashColors.divider),
            _MovementRow(movement: movement, l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement, required this.l10n});

  final DemoMovement movement;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isIncome = movement.kind == MovementKind.income;
    final day = switch (movement.day) {
      MovementDay.today => l10n.homeToday,
      MovementDay.yesterday => l10n.homeYesterday,
    };
    final amount = formatSoles(movement.amount);
    return Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isIncome
                  ? CuyCashColors.successSoft
                  : CuyCashColors.surfaceContainerHigh,
            ),
            child: Icon(
              movement.icon,
              size: 20,
              color: isIncome
                  ? CuyCashColors.success
                  : CuyCashColors.secondaryText,
            ),
          ),
          const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(l10n.homeDateTime(day, movement.time),
                    style: CuyCashTypography.labelSm),
              ],
            ),
          ),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isIncome ? '+ $amount' : '- $amount',
                style: CuyCashTypography.bodyMd.copyWith(
                  color: isIncome
                      ? CuyCashColors.success
                      : CuyCashColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(l10n.homeMovementCompleted,
                  style: CuyCashTypography.labelSm),
            ],
          ),
        ],
      ),
    );
  }
}
