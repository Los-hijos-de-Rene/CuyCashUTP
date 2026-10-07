import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Última página del carrusel mientras haya cupo: "＋ Abrir otra cuenta".
/// Mide lo mismo que una `BalanceCard`, con borde y sin relleno, para que se
/// lea como un hueco por llenar y no como una cuenta.
class OpenAccountCard extends StatelessWidget {
  const OpenAccountCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.homeOpenAccountCard,
      excludeSemantics: true,
      child: Material(
        color: CuyCashColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
          side: const BorderSide(
            color: CuyCashColors.outlineVariant,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: CuyCashColors.primaryContainer,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Text(
                  l10n.homeOpenAccountCard,
                  style: CuyCashTypography.titleMd,
                ),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(
                  l10n.homeOpenAccountCardHint,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
