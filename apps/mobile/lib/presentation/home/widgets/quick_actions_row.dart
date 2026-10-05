import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../home_action.dart';

/// Las cuatro acciones de dinero. Notifica con [HomeAction], no con el texto:
/// la pantalla decide qué hacer con cada una.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({required this.onAction, super.key});

  final void Function(HomeAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <(HomeAction, IconData, String)>[
      (HomeAction.send, Icons.north_east, l10n.homeActionSend),
      (HomeAction.charge, Icons.qr_code_scanner, l10n.homeActionCharge),
      (HomeAction.topUp, Icons.add_circle_outline, l10n.homeActionTopUp),
      (HomeAction.withdraw, Icons.south_east, l10n.homeActionWithdraw),
    ];
    return Row(
      children: [
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: SurfaceCard(
              onTap: () => onAction(action.$1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(
                    action.$2,
                    size: 24,
                    color: CuyCashColors.primaryContainer,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackXs + 2),
                  Text(
                    action.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CuyCashTypography.labelSm.copyWith(
                      color: CuyCashColors.onSurface,
                    ),
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
