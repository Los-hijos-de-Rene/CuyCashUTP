import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../feature/account/domain/movement.dart';
import '../../../l10n/app_localizations.dart';
import '../movement_amount_label.dart';

/// Lista de últimos movimientos del libro mayor.
class MovementsCard extends StatelessWidget {
  const MovementsCard({required this.movements, super.key});

  final List<Movement> movements;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (movements.isEmpty) {
      return SurfaceCard(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Center(
          child: Text(
            l10n.homeMovementsEmpty,
            style: CuyCashTypography.bodyMd.copyWith(
              color: CuyCashColors.secondaryText,
            ),
          ),
        ),
      );
    }
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

  final Movement movement;
  final AppLocalizations l10n;

  /// `Hoy` / `Ayer` / `dd/MM/yyyy`, en hora local (la fecha llega en UTC).
  String _day(DateTime local, DateTime now) {
    final hoy = DateTime(now.year, now.month, now.day);
    final dia = DateTime(local.year, local.month, local.day);
    return switch (hoy.difference(dia).inDays) {
      0 => l10n.homeToday,
      1 => l10n.homeYesterday,
      _ => DateFormat('dd/MM/yyyy').format(local),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = movement.direccion == MovementDirection.credito;
    final local = movement.fecha.toLocal();
    final when = l10n.homeDateTime(
      _day(local, DateTime.now()),
      DateFormat('HH:mm').format(local),
    );
    final icon = switch (movement.tipo) {
      MovementKind.recarga => Icons.add_circle_outline,
      MovementKind.transferencia ||
      MovementKind.otro => isIncome ? Icons.south_west : Icons.north_east,
    };
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
              icon,
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
                  movement.contraparte ?? l10n.homeMovementFallbackTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(when, style: CuyCashTypography.labelSm),
              ],
            ),
          ),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                movementAmountLabel(movement),
                style: CuyCashTypography.bodyMd.copyWith(
                  color: isIncome
                      ? CuyCashColors.success
                      : CuyCashColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                l10n.homeMovementCompleted,
                style: CuyCashTypography.labelSm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
