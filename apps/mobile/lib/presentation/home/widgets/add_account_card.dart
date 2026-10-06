import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Última página del carrusel: invita a abrir otra cuenta.
class AddAccountCard extends StatelessWidget {
  const AddAccountCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: CuyCashColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CuyCashSpacing.containerPadding,
            vertical: CuyCashSpacing.stackMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 28,
                color: CuyCashColors.primary,
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(l10n.homeOpenAccountTitle, style: CuyCashTypography.titleMd),
              const SizedBox(height: CuyCashSpacing.stackXs),
              Text(
                l10n.homeOpenAccountHint,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CuyCashTypography.bodyMd.copyWith(
                  color: CuyCashColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
