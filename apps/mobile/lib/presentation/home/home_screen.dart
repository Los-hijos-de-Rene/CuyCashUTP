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
import 'home_menu_option.dart';
import 'widgets/account_carousel.dart';
import 'widgets/home_header.dart';
import 'widgets/home_menu_button.dart';
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

void _openMovements(BuildContext context, [Account? cuenta]) =>
    context.push(AppRoutes.movimientos, extra: cuenta);

/// Muestra los ganchos que aún no tienen feature detrás (campana, WasiBot).
/// Apagado: se ocultan en vez de avisar "próximamente". Las acciones rápidas
/// se rigen por [HomeAction.ready].
const _showUnfinished = false;

/// Inicio: un resumen. Las cuentas en el carrusel (tocar una abre sus
/// movimientos), las acciones rápidas sobre la visible y los últimos
/// movimientos de TODAS las cuentas, con "Ver más" al historial completo.
/// Abrir cuenta está en el menú ⋮ y en la última tarjeta del carrusel.
///
/// WasiBot y notificaciones siguen siendo ganchos sin feature detrás y están
/// ocultos ([_showUnfinished]). Cobrar y retirar están ocultos hasta que
/// existan sus pantallas, y si se muestran avisan "próximamente".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _onMenu(BuildContext context, HomeMenuOption option) {
    switch (option) {
      case HomeMenuOption.openAccount:
        _openAccount(context);
    }
  }

  void _onAction(BuildContext context, HomeAction action) {
    switch (action) {
      case HomeAction.send:
        final cuenta = context.read<AccountBloc>().state.cuenta;
        if (cuenta == null) {
          // Sin cuenta cargada no hay desde dónde transferir: se dice.
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
                  // Sin cuentas cargadas no hay a qué agregar otra.
                  menu: BlocBuilder<AccountBloc, AccountState>(
                    buildWhen: (a, b) =>
                        a.status != b.status ||
                        a.puedeAbrirOtra != b.puedeAbrirOtra,
                    builder: (context, state) =>
                        state.status == AccountStatus.ready
                        ? HomeMenuButton(
                            puedeAbrirCuenta: state.puedeAbrirOtra,
                            onSelected: (o) => _onMenu(context, o),
                          )
                        : const SizedBox.shrink(),
                  ),
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
          AccountCarousel(
            cuentas: state.cuentas,
            seleccionada: state.seleccionada,
            onSelected: (i) =>
                context.read<AccountBloc>().add(AccountEvent.selected(i)),
            onRename: (c) => RenameAccountSheet.show(context, c),
            onOpen: (c) => _openMovements(context, c),
            onOpenNew: state.puedeAbrirOtra
                ? () => _openAccount(context)
                : null,
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
                  // Son de todas: cada fila dice de cuál.
                  Text(
                    l10n.homeMovementsAllAccounts,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (state.hayMasMovimientos)
              GhostButton(
                label: l10n.homeSeeMore,
                onPressed: () => _openMovements(context),
              ),
          ],
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        // Mientras refresca se ve la silueta, no la lista vieja ni "aún no
        // tienes movimientos".
        if (state.refreshing && state.recientes.isEmpty)
          Semantics(
            label: l10n.homeLoading,
            liveRegion: true,
            child: const ExcludeSemantics(
              child: MovementsSkeleton(rows: AccountBloc.recientesEnInicio),
            ),
          )
        else
          MovementsCard(movements: state.recientes),
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
