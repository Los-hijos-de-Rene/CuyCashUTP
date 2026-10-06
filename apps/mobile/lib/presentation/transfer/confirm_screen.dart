import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money_format.dart';
import '../../core/security/secure_screen_scope.dart';
import '../../feature/transfer/domain/transfer_failure.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../pin/pin_entry_view.dart';
import 'bloc/transfer_bloc.dart';
import 'transfer_error_text.dart';

/// Paso 3 del envío: resumen y PIN.
///
/// **Al abrirse fija la clave de idempotencia** (`confirmationOpened`), no al
/// pulsar "Confirmar": un doble toque no puede producir dos claves.
///
/// **El botón se deshabilita en cuanto el envío arranca** (`submitting`) y,
/// aunque dos toques lleguen antes del siguiente fotograma, el bloc descarta
/// el segundo: el doble toque no llega al repositorio.
///
/// El PIN vive solo en el estado de ESTA pantalla (nunca en el bloc). Un PIN
/// errado se borra pero conserva monto y destinatario; un fallo cuyo resultado
/// es desconocido (red) lo conserva para reintentar con un toque y la MISMA
/// clave.
class ConfirmScreen extends StatefulWidget {
  const ConfirmScreen({super.key});

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  static const _pinLength = 6;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    context.read<TransferBloc>().add(const TransferEvent.confirmationOpened());
  }

  void _onDigit(TransferState state, int digit) {
    if (state.status == TransferStatus.submitting ||
        _pin.length >= _pinLength) {
      return;
    }
    setState(() => _pin += '$digit');
  }

  void _onBackspace(TransferState state) {
    if (state.status == TransferStatus.submitting || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// Salir con el resultado desconocido es la única vía sin fricción hacia un
  /// segundo cobro: se avisa antes. (La clave queda guardada, así que reentrar
  /// con la misma intención la recupera; pero el usuario debe mirar sus
  /// movimientos primero.)
  Future<void> _leave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.transferLeaveTitle),
        content: Text(l10n.transferLeaveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.transferLeaveConfirm),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) context.go(AppRoutes.home);
  }

  void _onResult(BuildContext context, TransferState state) {
    if (state.status == TransferStatus.done) {
      // Reemplaza la confirmación: volver atrás no debe poder reenviar.
      context.pushReplacement(AppRoutes.enviarConstancia);
      return;
    }
    final failure = state.failure;
    if (failure != null && !failure.outcomeUnknown) {
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<TransferBloc, TransferState>(
      listenWhen: (previous, current) =>
          previous.status == TransferStatus.submitting &&
          current.status != TransferStatus.submitting,
      listener: _onResult,
      builder: (context, state) {
        final submitting = state.status == TransferStatus.submitting;
        final failure = state.failure;
        final failed = failure != null && !submitting;
        // Resultado desconocido: no se sale de aquí salvo al inicio. Volver a
        // editar el monto abriría una intención nueva con otra clave mientras
        // el envío anterior pudo haberse ejecutado.
        final sealed = state.outcomeUnknown;
        // 409: reintentar repite la clave y devuelve 409 siempre. Lo único útil
        // es empezar de nuevo.
        final dead = failed && failure is IdempotencyKeyReused;
        return PopScope(
          // Con el envío en vuelo no se sale: el resultado debe verse.
          canPop: !submitting && !sealed,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !submitting && !sealed,
              title: Text(l10n.transferConfirmTitle),
            ),
            body: SecureScreenScope(
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: PinEntryView(
                        headline: l10n.transferConfirmHeadline,
                        subtitle: l10n.transferConfirmSubtitle,
                        pin: _pin,
                        onDigit: (d) => _onDigit(state, d),
                        onBackspace: () => _onBackspace(state),
                        // Sin la clave guardada, "no se cobrará dos veces" no
                        // se puede prometer si salimos de aquí: se avisa fuerte.
                        errorText: failed
                            ? (state.keyUnsaved && failure.outcomeUnknown
                                  ? l10n.transferKeyUnsavedWarning
                                  : transferSubmitErrorText(
                                      l10n,
                                      failure,
                                      state.monto?.currency ??
                                          state.cuenta?.moneda ??
                                          Currency.pen,
                                    ))
                            : null,
                        hasError: failed && failure is WrongPin,
                        extra: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sealed && failure == null) ...[
                              InfoStrip(
                                icon: Icons.info_outline,
                                text: l10n.transferRecoveredNotice,
                              ),
                              const SizedBox(height: CuyCashSpacing.stackSm),
                            ],
                            if (state.pendingElsewhere && !sealed) ...[
                              InfoStrip(
                                icon: Icons.info_outline,
                                text: l10n.transferPendingElsewhereNotice,
                              ),
                              const SizedBox(height: CuyCashSpacing.stackSm),
                            ],
                            _Summary(state: state),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        CuyCashSpacing.marginMobile,
                        CuyCashSpacing.stackSm,
                        CuyCashSpacing.marginMobile,
                        CuyCashSpacing.stackMd,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dead)
                            PrimaryButton(
                              label: l10n.transferBackHomeCta,
                              onPressed: () => context.go(AppRoutes.home),
                            )
                          else ...[
                            PrimaryButton(
                              label: sealed
                                  ? l10n.transferRetryCta
                                  : l10n.transferConfirmCta,
                              loading: submitting,
                              onPressed: _pin.length == _pinLength
                                  ? () => context.read<TransferBloc>().add(
                                      TransferEvent.submitted(pin: _pin),
                                    )
                                  : null,
                            ),
                            if (sealed && !submitting) ...[
                              const SizedBox(height: CuyCashSpacing.stackSm),
                              SecondaryButton(
                                label: l10n.transferBackHomeCta,
                                onPressed: () => _leave(context),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monto = state.monto;
    final motivo = state.motivo;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (monto != null)
            Text(formatMoney(monto), style: CuyCashTypography.headlineMd),
          const SizedBox(height: CuyCashSpacing.stackSm),
          if (state.destinatario case final d?)
            _Row(
              label: l10n.transferSummaryTo,
              value: '${d.nombreEnmascarado} · ${d.cuenta.numeroMasked}',
            ),
          if (state.cuenta case final c?)
            _Row(label: l10n.transferSummaryFrom, value: c.numeroMasked),
          if (motivo != null)
            _Row(label: l10n.transferSummaryMotivo, value: motivo),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: CuyCashSpacing.stackXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CuyCashTypography.bodyMd),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: CuyCashTypography.labelMd,
            ),
          ),
        ],
      ),
    );
  }
}
