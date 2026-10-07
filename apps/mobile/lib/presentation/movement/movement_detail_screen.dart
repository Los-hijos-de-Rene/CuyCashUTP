import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/account/domain/account_failure.dart';
import '../../feature/account/domain/movement.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/movement_detail_bloc.dart';
import 'widgets/receipt_card.dart';
import 'widgets/share_receipt_button.dart';

/// Ficha de un movimiento del historial. El bloc viene del router, ya abierto
/// con el `transactionId`.
class MovementDetailScreen extends StatelessWidget {
  const MovementDetailScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.movementDetailTitle)),
      body: SafeArea(
        child: BlocBuilder<MovementDetailBloc, MovementDetailState>(
          builder: (context, state) => switch ((state.status, state.detalle)) {
            (MovementDetailStatus.loading, _) => Center(
              child: CircularProgressIndicator(semanticsLabel: l10n.homeLoading),
            ),
            (MovementDetailStatus.ready, final MovementDetail detalle) =>
              _Ready(detalle: detalle),
            (MovementDetailStatus.ready, null) ||
            (MovementDetailStatus.error, _) => _Error(
              failure: state.failure,
              onRetry: () => context.read<MovementDetailBloc>().add(
                MovementDetailEvent.opened(transactionId),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.detalle});

  final MovementDetail detalle;

  String _headline(AppLocalizations l10n) => switch ((
    detalle.tipo,
    detalle.direccion,
  )) {
    (MovementKind.recarga, _) => l10n.movementHeadlineTopUp,
    (MovementKind.transferencia, MovementDirection.debito) =>
      l10n.movementHeadlineSent,
    (MovementKind.transferencia, MovementDirection.credito) =>
      l10n.movementHeadlineReceived,
    (MovementKind.otro, _) => l10n.movementHeadlineOther,
  };

  String? _label(AppLocalizations l10n) => switch ((
    detalle.tipo,
    detalle.direccion,
  )) {
    (MovementKind.transferencia, MovementDirection.debito) =>
      l10n.transferReceiptTo,
    (MovementKind.transferencia, MovementDirection.credito) =>
      l10n.movementDetailReceivedFrom,
    (MovementKind.recarga, _) || (MovementKind.otro, _) => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = ReceiptCard(
      headline: _headline(l10n),
      monto: detalle.monto,
      fecha: detalle.fecha,
      transactionId: detalle.transactionId,
      estado: detalle.estado,
      contraparteLabel: _label(l10n),
      contraparte: detalle.contraparte,
      cuentaDestinoMasked: detalle.cuentaDestinoMasked,
      motivo: detalle.motivo,
      saldoPosterior: detalle.saldoPosterior,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card,
          const SizedBox(height: CuyCashSpacing.stackLg),
          ShareReceiptButton(text: card.shareText(l10n)),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.failure, required this.onRetry});

  final AccountFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (failure) {
      AccountNotFound() => l10n.movementDetailNotFound,
      NetworkFailure() => l10n.homeErrorNetwork,
      Unauthenticated() ||
      AccountLimitReached() ||
      SalaryAccountExists() ||
      InvalidAccountCurrency() ||
      InvalidAccountName() ||
      AccountWrongPin() ||
      AccountLocked() ||
      AccountKeyReused() ||
      UnexpectedFailure() ||
      null => l10n.movementDetailError,
    };
    return Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: CuyCashTypography.bodyLg,
          ),
          // Reintentar no cambia nada si el movimiento no existe.
          if (failure is! AccountNotFound) ...[
            const SizedBox(height: CuyCashSpacing.stackMd),
            SecondaryButton(label: l10n.homeRetry, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}
