import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../core/format/money_format.dart';
import '../../../l10n/app_localizations.dart';

/// Card de saldo sobre Eucalipto, con el ojo para ocultarlo.
///
/// Ocultar el saldo es local y efímero a propósito: es una comodidad de la
/// sesión, no una preferencia que deba sobrevivir al reinicio.
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    required this.balance,
    required this.walletMasked,
    super.key,
  });

  final Money balance;

  /// Número de la cuenta ya enmascarado (`••••4521`).
  final String walletMasked;

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
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.onPrimaryContainer,
                  ),
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
            _hidden ? l10n.homeBalanceHidden : formatMoney(widget.balance),
            style: CuyCashTypography.displayLg.copyWith(
              color: CuyCashColors.accentOnDark,
              fontFeatures: const [FontFeature.tabularFigures()],
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
              Text(
                l10n.homeWalletMask(widget.walletMasked),
                style: CuyCashTypography.bodyMd.copyWith(
                  color: CuyCashColors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
