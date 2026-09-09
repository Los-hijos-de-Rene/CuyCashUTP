import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../session/remembered_user_builder.dart';
import 'demo_wallet.dart';
import 'widgets/balance_card.dart';
import 'widgets/home_header.dart';
import 'widgets/insight_card.dart';
import 'widgets/movements_card.dart';
import 'widgets/quick_actions_row.dart';

/// Inicio.
///
/// Saldo y movimientos son [DemoWallet]: cuentas y motor transaccional son del
/// Sprint 2. El único dato verdadero de esta pantalla es de quién es la sesión.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _notYet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: RememberedUserBuilder(
          builder: (context, user) => ListView(
            padding: const EdgeInsets.fromLTRB(
              CuyCashSpacing.marginMobile,
              CuyCashSpacing.stackSm,
              CuyCashSpacing.marginMobile,
              CuyCashSpacing.stackLg,
            ),
            children: [
              HomeHeader(
                user: user,
                onNotifications: () => _notYet(context),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              const _DemoBadge(),
              const SizedBox(height: CuyCashSpacing.stackSm),
              const BalanceCard(
                balance: DemoWallet.balance,
                walletLast4: DemoWallet.walletLast4,
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              QuickActionsRow(onAction: (_) => _notYet(context)),
              const SizedBox(height: CuyCashSpacing.stackMd),
              InsightCard(onTap: () => _notYet(context)),
              const SizedBox(height: CuyCashSpacing.stackLg),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.homeMovementsTitle,
                        style: CuyCashTypography.titleMd),
                  ),
                  GhostButton(
                    label: l10n.homeSeeAll,
                    onPressed: () => _notYet(context),
                  ),
                ],
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              const MovementsCard(movements: DemoWallet.movements),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sello visible: sin él, una maqueta con cifras redondas se lee como saldo
/// real. Se borra junto con [DemoWallet].
class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CuyCashColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(CuyCashRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science_outlined,
                size: 14, color: CuyCashColors.secondaryText),
            const SizedBox(width: CuyCashSpacing.stackXs + 2),
            Text(l10n.homeDemoBadge, style: CuyCashTypography.labelSm),
          ],
        ),
      ),
    );
  }
}
