import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/account/domain/account_failure.dart';
import '../../l10n/app_localizations.dart';
import '../session/remembered_user_builder.dart';
import 'bloc/account_bloc.dart';
import 'home_action.dart';
import 'widgets/balance_card.dart';
import 'widgets/home_header.dart';
import 'widgets/insight_card.dart';
import 'widgets/movements_card.dart';
import 'widgets/quick_actions_row.dart';

void _showComingSoon(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
}

/// Inicio: saldo y movimientos del libro mayor (los trae [AccountBloc]).
///
/// El resto de la pantalla (WasiBot, notificaciones) sigue siendo un gancho sin
/// feature detrás. Enviar y recargar también avisan "próximamente" hasta que
/// existan sus pantallas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Distancia al final a la que se pide la siguiente página.
  static const _prefetchExtent = 240.0;

  void _onAction(BuildContext context, HomeAction action) {
    switch (action) {
      case HomeAction.send:
      case HomeAction.charge:
      case HomeAction.topUp:
      case HomeAction.withdraw:
        _showComingSoon(context);
    }
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    bloc.add(const AccountEvent.refreshed());
    await bloc.stream.firstWhere((s) => !s.refreshing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < _prefetchExtent) {
                context.read<AccountBloc>().add(
                  const AccountEvent.moreRequested(),
                );
              }
              return false;
            },
            child: RememberedUserBuilder(
              builder: (context, user) => ListView(
                // Con poco contenido el pull-to-refresh igual debe poder usarse.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackSm,
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackLg,
                ),
                children: [
                  HomeHeader(
                    user: user,
                    onNotifications: () => _showComingSoon(context),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  BlocBuilder<AccountBloc, AccountState>(
                    builder: (context, state) =>
                        _AccountBody(state: state, onAction: _onAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Todo lo que depende de la cuenta, según el estado de la carga.
class _AccountBody extends StatelessWidget {
  const _AccountBody({required this.state, required this.onAction});

  final AccountState state;
  final void Function(BuildContext context, HomeAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (state.status) {
      AccountStatus.loading => Padding(
        padding: const EdgeInsets.symmetric(vertical: CuyCashSpacing.stackLg),
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: l10n.homeLoading),
        ),
      ),
      AccountStatus.error => _ErrorView(failure: state.failure),
      AccountStatus.ready => _ReadyView(state: state, onAction: onAction),
    };
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.state, required this.onAction});

  final AccountState state;
  final void Function(BuildContext context, HomeAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cuenta = state.cuenta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.refreshFailed) ...[
          InfoStrip(icon: Icons.info_outline, text: l10n.homeRefreshFailed),
          const SizedBox(height: CuyCashSpacing.stackSm),
        ],
        if (cuenta != null) ...[
          BalanceCard(
            balance: cuenta.saldoDisponible,
            walletMasked: cuenta.numeroMasked,
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
        ],
        QuickActionsRow(onAction: (a) => onAction(context, a)),
        const SizedBox(height: CuyCashSpacing.stackMd),
        InsightCard(onTap: () => _showComingSoon(context)),
        const SizedBox(height: CuyCashSpacing.stackLg),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeMovementsTitle,
                style: CuyCashTypography.titleMd,
              ),
            ),
            GhostButton(
              label: l10n.homeSeeAll,
              onPressed: () => _showComingSoon(context),
            ),
          ],
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        MovementsCard(movements: state.movimientos),
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: CuyCashSpacing.stackMd),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure});

  final AccountFailure? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (failure) {
      NetworkFailure() => l10n.homeErrorNetwork,
      null ||
      AccountNotFound() ||
      Unauthenticated() ||
      UnexpectedFailure() => l10n.homeErrorGeneric,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CuyCashSpacing.stackLg),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: CuyCashTypography.bodyMd,
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
          SecondaryButton(
            label: l10n.homeRetry,
            onPressed: () =>
                context.read<AccountBloc>().add(const AccountEvent.started()),
          ),
        ],
      ),
    );
  }
}
