import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../feature/account/domain/account.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/account_label.dart';

/// Card de saldo sobre Eucalipto, con el ojo para ocultarlo. Con [onTap],
/// tocarla abre los movimientos de la cuenta (el lápiz y el ojo conservan su
/// propio toque).
///
/// Ocultar el saldo es local y efímero a propósito: es una comodidad de la
/// sesión, no una preferencia que deba sobrevivir al reinicio.
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    required this.cuenta,
    this.onRename,
    this.onTap,
    super.key,
  });

  final Account cuenta;

  /// `null` = la tarjeta no se toca (p. ej. ya estás en sus movimientos).
  final VoidCallback? onTap;

  /// `null` = sin lápiz para cambiar el nombre.
  final VoidCallback? onRename;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      decoration: BoxDecoration(
        color: CuyCashColors.primaryContainer,
        borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
        border: const Border(
          top: BorderSide(color: CuyCashColors.secondary, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  accountLabel(l10n, widget.cuenta),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.onPrimaryContainer,
                  ),
                ),
              ),
              if (widget.onRename != null)
                IconButton(
                  onPressed: widget.onRename,
                  tooltip: l10n.homeRenameTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: CuyCashColors.onPrimaryContainer,
                  ),
                ),
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                tooltip: _hidden ? l10n.homeShowBalance : l10n.homeHideBalance,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _hidden ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: CuyCashColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: CuyCashSpacing.stackXs),
          // Un saldo largo se encoge en vez de partirse: la tarjeta tiene alto fijo.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _hidden
                  ? l10n.homeBalanceHidden(widget.cuenta.moneda.symbol)
                  : formatMoney(widget.cuenta.saldoDisponible),
              maxLines: 1,
              style: CuyCashTypography.displayLg.copyWith(
                color: CuyCashColors.accentOnDark,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: CuyCashSpacing.stackSm),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: CuyCashColors.onPrimaryContainer,
              ),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Expanded(
                // Sin la moneda: ya va en el saldo.
                child: Text(
                  l10n.homeAccountNumber(widget.cuenta.numeroMasked),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.onPrimaryContainer,
                  ),
                ),
              ),
              // Pista de que la tarjeta lleva a algún lado.
              if (widget.onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: CuyCashColors.onPrimaryContainer,
                ),
            ],
          ),
        ],
      ),
    );
    final onTap = widget.onTap;
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: l10n.homeAccountOpenSemantics(accountLabel(l10n, widget.cuenta)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
