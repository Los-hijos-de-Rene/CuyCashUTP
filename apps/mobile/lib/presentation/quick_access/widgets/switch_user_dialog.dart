import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Diálogo "¿Salir de esta cuenta?". Devuelve true si el usuario confirma.
Future<bool?> showSwitchUserDialog(BuildContext context, {required String name}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _SwitchUserDialog(name: name),
  );
}

class _SwitchUserDialog extends StatelessWidget {
  const _SwitchUserDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: CuyCashColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CuyCashColors.surfaceContainerHighest),
                child: const Icon(Icons.switch_account,
                    color: CuyCashColors.primaryContainer),
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Text(l10n.switchUserTitle,
                textAlign: TextAlign.center,
                style: CuyCashTypography.titleMd),
            const SizedBox(height: CuyCashSpacing.stackSm),
            Text(l10n.switchUserBody(name),
                textAlign: TextAlign.center,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(CuyCashRadii.input),
              ),
              child: Column(
                children: [
                  _consequence(Icons.fingerprint,
                      l10n.switchUserConsequenceBiometric),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  _consequence(Icons.shield_outlined,
                      l10n.switchUserConsequenceSession),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            PrimaryButton(
              label: l10n.switchUserConfirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: CuyCashSpacing.stackSm),
            GhostButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consequence(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CuyCashColors.secondaryText),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
              child: Text(text,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.onSurface))),
        ],
      );
}
