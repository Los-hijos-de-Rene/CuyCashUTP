import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Encabezado del carrusel: "Mis cuentas" y el botón para abrir otra.
///
/// Abrir cuenta vive aquí y no como una página del carrusel: así el carrusel
/// solo tiene cuentas, y lo que va debajo (enviar, recargar, movimientos)
/// siempre es de la tarjeta que se ve.
class AccountsHeader extends StatelessWidget {
  const AccountsHeader({
    required this.cuentas,
    required this.onOpenAccount,
    super.key,
  });

  /// Cuántas tiene: con una sola, el título va en singular.
  final int cuentas;

  /// `null` = ya tiene el máximo de cuentas: no se ofrece abrir otra.
  final VoidCallback? onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final abrir = onOpenAccount;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.homeAccountsTitle(cuentas),
            style: CuyCashTypography.titleMd,
          ),
        ),
        if (abrir != null)
          GhostButton(
            label: l10n.homeOpenAccountCta,
            icon: Icons.add,
            onPressed: abrir,
          ),
      ],
    );
  }
}
