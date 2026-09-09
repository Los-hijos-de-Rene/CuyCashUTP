import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/format/soles.dart';
import '../../../l10n/app_localizations.dart';

/// Card de saldo sobre Eucalipto, con el ojo para ocultarlo.
///
/// Ocultar el saldo es local y efímero a propósito: nada que persistir mientras
/// no exista la feature de cuentas.
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    required this.balance,
    required this.walletLast4,
    super.key,
  });

  final double balance;
  final String walletLast4;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
                  l10n.homeBalanceLabel,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.onPrimaryContainer),
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
          Text(
            _hidden ? l10n.homeBalanceHidden : formatSoles(widget.balance),
            style: CuyCashTypography.displayLg.copyWith(
              color: CuyCashColors.accentOnDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: CuyCashSpacing.stackSm),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: CuyCashColors.onPrimaryContainer),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Text(
                l10n.homeWalletMask(widget.walletLast4),
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.onPrimaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
