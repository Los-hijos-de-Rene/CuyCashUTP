import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/account/domain/account.dart';
import '../../feature/account/domain/account_failure.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_label.dart';
import '../home/widgets/balance_card.dart';
import '../home/widgets/movements_card.dart';
import '../home/widgets/movements_skeleton.dart';
import 'bloc/movements_bloc.dart';

/// El historial completo, con scroll infinito y pull-to-refresh.
///
/// Con [cuenta] es el de esa cuenta (al tocar su tarjeta en el inicio) y la
/// tarjeta va arriba; sin ella, el de todas (el "Ver más" del inicio), donde
/// cada fila dice de qué cuenta es. Las esperas se ven con la misma silueta
/// que el inicio.
class MovementsScreen extends StatelessWidget {
  const MovementsScreen({this.cuenta, super.key});

  final Account? cuenta;

  /// Distancia al final a la que se pide la siguiente página.
  static const _prefetchExtent = 240.0;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<MovementsBloc>();
    bloc.add(const MovementsEvent.refreshed());
    await bloc.stream.firstWhere((s) => !s.refreshing);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cuenta = this.cuenta;
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      appBar: AppBar(
        title: Text(
          cuenta == null ? l10n.movementsTitle : accountLabel(l10n, cuenta),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < _prefetchExtent) {
                context.read<MovementsBloc>().add(
                  const MovementsEvent.moreRequested(),
                );
              }
              return false;
            },
            child: BlocBuilder<MovementsBloc, MovementsState>(
              builder: (context, state) => ListView(
                // Con poco contenido el pull-to-refresh igual debe poder usarse.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackSm,
                  CuyCashSpacing.marginMobile,
                  CuyCashSpacing.stackLg,
                ),
                children: [
                  if (cuenta != null) ...[
                    BalanceCard(cuenta: cuenta),
                    const SizedBox(height: CuyCashSpacing.stackLg),
                    Text(l10n.movementsTitle, style: CuyCashTypography.titleMd),
                    const SizedBox(height: CuyCashSpacing.stackSm),
                  ],
                  ..._body(context, l10n, state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l10n,
    MovementsState state,
  ) => switch (state.status) {
    MovementsStatus.loading => [
      Semantics(
        label: l10n.homeLoading,
        liveRegion: true,
        child: const ExcludeSemantics(child: MovementsSkeleton(rows: 6)),
      ),
    ],
    MovementsStatus.error => [_ErrorView(failure: state.failure)],
    MovementsStatus.ready => [
      if (state.refreshFailed) ...[
        InfoStrip(icon: Icons.info_outline, text: l10n.homeRefreshFailed),
        const SizedBox(height: CuyCashSpacing.stackSm),
      ],
      MovementsCard(movements: state.movimientos),
      if (state.loadingMore) ...[
        const SizedBox(height: CuyCashSpacing.stackSm),
        Semantics(
          label: l10n.homeLoading,
          child: const ExcludeSemantics(child: MovementsSkeleton(rows: 2)),
        ),
      ],
      if (state.loadMoreFailed) ...[
        const SizedBox(height: CuyCashSpacing.stackSm),
        InfoStrip(icon: Icons.info_outline, text: l10n.movementsLoadMoreFailed),
      ],
    ],
  };
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
      AccountLimitReached() ||
      SalaryAccountExists() ||
      InvalidAccountCurrency() ||
      InvalidAccountName() ||
      AccountWrongPin() ||
      AccountLocked() ||
      AccountKeyReused() ||
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
            onPressed: () => context.read<MovementsBloc>().add(
              const MovementsEvent.started(),
            ),
          ),
        ],
      ),
    );
  }
}
