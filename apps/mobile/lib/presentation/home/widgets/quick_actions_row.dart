import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Las cuatro acciones de dinero. Ninguna tiene feature detrás todavía: el
/// callback existe para que la pantalla decida qué decir mientras tanto.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({required this.onAction, super.key});

  final void Function(String label) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <(IconData, String)>[
      (Icons.north_east, l10n.homeActionSend),
      (Icons.qr_code_scanner, l10n.homeActionCharge),
      (Icons.add_circle_outline, l10n.homeActionTopUp),
      (Icons.south_east, l10n.homeActionWithdraw),
    ];
    return Row(
      children: [
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: SurfaceCard(
              onTap: () => onAction(action.$2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(action.$1,
                      size: 24, color: CuyCashColors.primaryContainer),
                  const SizedBox(height: CuyCashSpacing.stackXs + 2),
                  Text(
                    action.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CuyCashTypography.labelSm
                        .copyWith(color: CuyCashColors.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
