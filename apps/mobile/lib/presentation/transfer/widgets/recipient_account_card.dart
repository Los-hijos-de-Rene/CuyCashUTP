import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/transfer/domain/recipient_account.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/account_label.dart';

/// Una cuenta del destinatario. Tocarla elige esa cuenta; apagada (sin
/// [onTap]) dice por qué no puede recibir.
class RecipientAccountCard extends StatelessWidget {
  const RecipientAccountCard({
    required this.cuenta,
    required this.titulo,
    this.onTap,
    this.motivoDeshabilitada,
    super.key,
  });

  final RecipientAccount cuenta;

  /// El nombre de la cuenta si es propia; si no, la línea de tipo y moneda.
  final String titulo;
  final VoidCallback? onTap;
  final String? motivoDeshabilitada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linea = l10n.transferRecipientAccountLine(
      accountTypeShort(l10n, cuenta.tipo),
      cuenta.moneda.symbol,
      cuenta.numeroMasked,
    );
    final activa = onTap != null;
    final motivo = motivoDeshabilitada;
    return Semantics(
      button: activa,
      enabled: activa,
      label: !activa && motivo != null
          ? l10n.transferRecipientAccountDisabledSemantics(linea, motivo)
          : l10n.transferRecipientAccountSemantics(linea),
      excludeSemantics: true,
      child: Opacity(
        opacity: activa ? 1 : 0.5,
        child: SurfaceCard(
          onTap: onTap,
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined),
              const SizedBox(width: CuyCashSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: CuyCashTypography.titleMd),
                    if (titulo != linea)
                      Text(
                        linea,
                        style: CuyCashTypography.bodyMd.copyWith(
                          color: CuyCashColors.secondaryText,
                        ),
                      ),
                    if (motivoDeshabilitada case final m?)
                      Text(
                        m,
                        style: CuyCashTypography.bodyMd.copyWith(
                          color: CuyCashColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (activa) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
