import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/account/domain/account.dart';
import '../../feature/account/domain/account_failure.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../session/remembered_user_builder.dart';
import 'bloc/account_bloc.dart';
import 'home_action.dart';
import '../account/account_label.dart';
import 'widgets/account_carousel.dart';
import 'widgets/accounts_header.dart';
import 'widgets/home_header.dart';
import 'widgets/home_skeleton.dart';
import 'widgets/insight_card.dart';
import 'widgets/movements_card.dart';
import 'widgets/movements_skeleton.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/rename_account_sheet.dart';

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _showComingSoon(BuildContext context) =>
    _showMessage(context, AppLocalizations.of(context).comingSoon);

Future<void> _openAccount(BuildContext context) async {
  final bloc = context.read<AccountBloc>();
  final nueva = await context.push<Account>(
    AppRoutes.abrirCuenta,
    extra: bloc.state.cuentas,
  );
  if (nueva != null) bloc.add(AccountEvent.opened(nueva));
}

/// Muestra los ganchos que aún no tienen feature detrás (campana, WasiBot,
/// "Ver todo"). Apagado: se ocultan en vez de avisar "próximamente". Las
/// acciones rápidas se rigen por [HomeAction.ready].
const _showUnfinished = false;

/// Inicio: saldo y movimientos del libro mayor (los trae [AccountBloc]).
///
/// El resto de la pantalla (WasiBot, notificaciones, "Ver todo") sigue siendo
/// un gancho sin feature detrás y está oculto ([_showUnfinished]). Enviar y
/// recargar abren su flujo; cobrar y retirar están ocultos hasta que existan
/// sus pantallas, y si se muestran avisan "próximamente".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Distancia al final a la que se pide la siguiente página.
  static const _prefetchExtent = 240.0;

  void _onAction(BuildContext context, HomeAction action) {
    switch (action) {
      case HomeAction.send:
        final cuenta = context.read<AccountBloc>().state.cuenta;
        if (cuenta == null) {
          // Sin cuenta cargada no hay desde dónde enviar: se dice, no se calla.
          _showMessage(context, AppLocalizations.of(context).homeErrorGeneric);
        } else {
          // El flujo de envío se cierra con `go(home)` y no puede devolver un
          // resultado: `RefreshAfterSend` (en el router) refresca el saldo.
          context.push(AppRoutes.enviar, extra: cuenta);
        }
      case HomeAction.topUp:
        final bloc = context.read<AccountBloc>();
        final cuenta = bloc.state.cuenta;
        if (cuenta == null) {
          _showMessage(context, AppLocalizations.of(context).homeErrorGeneric);
        } else {
          // La recarga avisa con `true` si hubo algún intento: el saldo se
          // vuelve a pedir para que el nuevo se vea.
          context.push<bool>(AppRoutes.recargar, extra: cuenta).then((
            huboIntento,
          ) {
            if (huboIntento == true) {
              bloc.add(const AccountEvent.refreshed());
            }
          });
        }
      case HomeAction.charge:
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
                    onNotifications: _showUnfinished
                        ? () => _showComingSoon(context)
                        : null,
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
    return switch (state.status) {
      AccountStatus.loading => const HomeSkeleton(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.refreshFailed) ...[
          InfoStrip(icon: Icons.info_outline, text: l10n.homeRefreshFailed),
          const SizedBox(height: CuyCashSpacing.stackSm),
        ],
        if (state.cuentas.isNotEmpty) ...[
          AccountsHeader(
            onOpenAccount: state.puedeAbrirOtra
                ? () => _openAccount(context)
                : null,
          ),
          const SizedBox(height: CuyCashSpacing.stackSm),
          AccountCarousel(
            cuentas: state.cuentas,
            seleccionada: state.seleccionada,
            onSelected: (i) =>
                context.read<AccountBloc>().add(AccountEvent.selected(i)),
            onRename: (c) => RenameAccountSheet.show(context, c),
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
        ],
        QuickActionsRow(onAction: (a) => onAction(context, a)),
        if (_showUnfinished) ...[
          const SizedBox(height: CuyCashSpacing.stackMd),
          InsightCard(onTap: () => _showComingSoon(context)),
        ],
        const SizedBox(height: CuyCashSpacing.stackLg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeMovementsTitle,
                    style: CuyCashTypography.titleMd,
                  ),
                  // De qué cuenta son: la que se ve en el carrusel.
                  if (state.cuenta case final c?)
                    Text(
                      accountShort(l10n, c),
                      style: CuyCashTypography.bodyMd.copyWith(
                        color: CuyCashColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            if (_showUnfinished)
              GhostButton(
                label: l10n.homeSeeAll,
                onPressed: () => _showComingSoon(context),
              ),
          ],
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        // Al cambiar de cuenta la lista está vacía porque aún no llegó: se
        // muestra la silueta, no "aún no tienes movimientos".
        if (state.cargandoMovimientos)
          Semantics(
            label: l10n.homeLoading,
            liveRegion: true,
            child: const ExcludeSemantics(child: MovementsSkeleton()),
          )
        else
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
            onPressed: () =>
                context.read<AccountBloc>().add(const AccountEvent.started()),
          ),
        ],
      ),
    );
  }
}
