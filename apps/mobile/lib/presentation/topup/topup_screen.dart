import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money_format.dart';
import '../../core/security/secure_screen_scope.dart';
import '../../feature/account/domain/account.dart';
import '../../feature/transfer/domain/transfer_failure.dart';
import '../../feature/transfer/domain/transfer_limits.dart';
import '../../l10n/app_localizations.dart';
import '../transfer/money_input_formatter.dart';
import 'bloc/topup_bloc.dart';
import 'topup_error_text.dart';

/// Depósito simulado en un solo paso: el monto y "Depositar". No pide PIN:
/// meter dinero a la cuenta propia no necesita la autorización del titular.
///
/// La clave de idempotencia nace al abrir (en el [TopUpBloc] que la ruta
/// provee) y solo cambia si cambia el monto.
///
/// Cierra con `pop(true)` cuando hubo algún intento de depósito (acreditado o
/// con resultado desconocido): quien la abrió refresca la cuenta.
///
/// **Con el resultado desconocido la intención queda sellada**: el monto ya no
/// se edita ni se sale con atrás; solo quedan "Reintentar" (misma clave) o
/// salir con aviso. El botón se deshabilita al primer toque y el bloc descarta
/// un segundo evento aunque llegue antes del siguiente fotograma.
class TopUpScreen extends StatefulWidget {
  const TopUpScreen({required this.cuenta, super.key});

  final Account cuenta;

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  static const _quickAmounts = [20, 50, 100, 500];

  final _amount = TextEditingController();

  /// Aviso del último rechazo del formateador; `null` si no hay.
  String? _rejectedMessage;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  bool get _incomplete {
    final t = _amount.text;
    return t.endsWith('.') || t.endsWith(',');
  }

  Money? get _parsed => Money.parse(_amount.text, widget.cuenta.moneda);

  String? _amountError(AppLocalizations l10n) {
    if (_amount.text.isEmpty || _incomplete) return null;
    final monto = _parsed;
    if (monto == null) return l10n.transferAmountInvalid;
    if (monto < TransferLimits.montoMinimo(widget.cuenta.moneda)) {
      return l10n.transferAmountZero(
        formatMoney(Money.zero(widget.cuenta.moneda)),
      );
    }
    if (monto > TransferLimits.montoMaximo(widget.cuenta.moneda)) {
      return l10n.topUpAmountOverMax(
        formatMoney(TransferLimits.montoMaximo(widget.cuenta.moneda)),
      );
    }
    return null;
  }

  /// El monto que el bloc debe conocer: `null` mientras el campo no sea válido.
  void _publishAmount(AppLocalizations l10n) {
    final monto = _parsed;
    final valido =
        _rejectedMessage == null &&
        monto != null &&
        !_incomplete &&
        _amountError(l10n) == null;
    context.read<TopUpBloc>().add(
      TopUpEvent.amountChanged(valido ? monto : null),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<TopUpBloc>().add(const TopUpEvent.submitted());
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.topUpLeaveTitle),
        content: Text(l10n.topUpLeaveBody),
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
    if (salir == true && context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<TopUpBloc, TopUpState>(
      builder: (context, state) {
        if (state.status == TopUpStatus.done) {
          return _DoneView(state: state, cuenta: widget.cuenta);
        }
        final bloqueado =
            state.status == TopUpStatus.submitting || state.outcomeUnknown;
        return PopScope(
          // Con la intención sellada o el depósito en vuelo no se va a
          // ninguna parte.
          canPop: !bloqueado,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !bloqueado,
              title: Text(l10n.topUpTitle),
            ),
            body: SecureScreenScope(
              child: SafeArea(
                child: _buildBody(context, state, l10n, bloqueado),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    TopUpState state,
    AppLocalizations l10n,
    bool bloqueado,
  ) {
    final submitting = state.status == TopUpStatus.submitting;
    final failure = state.failure;
    final failed = failure != null && !submitting;
    final sealed = state.outcomeUnknown;
    final dead = failed && failure is IdempotencyKeyReused;
    final error = _rejectedMessage ?? _amountError(l10n);
    // Sin la clave guardada, "no se cobrará dos veces" no se puede prometer:
    // el aviso es el fuerte.
    final failureText = failed
        ? (state.keyUnsaved && failure.outcomeUnknown
              ? l10n.transferKeyUnsavedWarning
              : topUpErrorText(l10n, failure, widget.cuenta.moneda))
        : null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El depósito simulado es temporal: se dice sin rodeos.
                InfoStrip(
                  icon: Icons.science_outlined,
                  text: l10n.topUpDemoNotice,
                ),
                const SizedBox(height: CuyCashSpacing.stackMd),
                Text(l10n.topUpHeadline, style: CuyCashTypography.headlineSm),
                const SizedBox(height: CuyCashSpacing.stackLg),
                if (sealed && failure == null) ...[
                  InfoStrip(
                    icon: Icons.info_outline,
                    text: l10n.topUpRecoveredNotice,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                ],
                if (state.pendingElsewhere && !sealed) ...[
                  InfoStrip(
                    icon: Icons.info_outline,
                    text: l10n.topUpPendingElsewhereNotice,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                ],
                CuyCashTextField(
                  label: l10n.transferAmountLabel,
                  hint: l10n.transferAmountHint,
                  controller: _amount,
                  enabled: !bloqueado,
                  autofocus: _amount.text.isEmpty,
                  errorText: error,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    MoneyInputFormatter(
                      onRejected: (texto) => setState(
                        () => _rejectedMessage =
                            MoneyInputFormatter.esSeparadorDeMiles(texto)
                            ? l10n.transferAmountNoThousands
                            : l10n.transferAmountInvalid,
                      ),
                    ),
                  ],
                  onChanged: (_) {
                    setState(() => _rejectedMessage = null);
                    _publishAmount(l10n);
                  },
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Wrap(
                  spacing: CuyCashSpacing.stackSm,
                  children: [
                    for (final unidades in _quickAmounts)
                      ActionChip(
                        label: Text(
                          formatMoney(
                            Money(unidades * 100, widget.cuenta.moneda),
                          ),
                        ),
                        onPressed: bloqueado
                            ? null
                            : () {
                                setState(() {
                                  _rejectedMessage = null;
                                  _amount.text = '$unidades';
                                });
                                _publishAmount(l10n);
                              },
                      ),
                  ],
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                _Line(
                  label: l10n.topUpSummaryTo,
                  value: widget.cuenta.numeroMasked,
                ),
                if (failureText != null) ...[
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  Text(
                    failureText,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: CuyCashSpacing.stackLg),
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
                  onPressed: () => context.pop(true),
                )
              else ...[
                PrimaryButton(
                  label: sealed ? l10n.topUpRetryCta : l10n.topUpCta,
                  loading: submitting,
                  onPressed:
                      state.monto != null &&
                          (sealed || error == null) &&
                          !submitting
                      ? _submit
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
    );
  }
}

/// Constancia: atrás y el botón llevan al inicio, que refresca el saldo.
class _DoneView extends StatelessWidget {
  const _DoneView({required this.state, required this.cuenta});

  final TopUpState state;
  final Account cuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final constancia = state.constancia;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.transferReceiptTitle),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 56,
                  color: CuyCashColors.success,
                ),
                const SizedBox(height: CuyCashSpacing.stackMd),
                Text(
                  l10n.topUpDoneHeadline,
                  style: CuyCashTypography.headlineSm,
                ),
                if (constancia != null) ...[
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    formatMoney(constancia.monto),
                    style: CuyCashTypography.headlineMd,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  SurfaceCard(
                    child: Column(
                      children: [
                        _Line(
                          label: l10n.topUpSummaryTo,
                          value: cuenta.numeroMasked,
                        ),
                        _Line(
                          label: l10n.transferReceiptDate,
                          value: DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(constancia.fecha.toLocal()),
                        ),
                        _Line(
                          label: l10n.transferReceiptId,
                          value: constancia.transactionId,
                        ),
                      ],
                    ),
                  ),
                  if (constancia.reutilizada) ...[
                    const SizedBox(height: CuyCashSpacing.stackMd),
                    InfoStrip(
                      icon: Icons.info_outline,
                      text: l10n.topUpDoneReused,
                    ),
                  ],
                ],
                const Spacer(),
                PrimaryButton(
                  label: l10n.transferReceiptHome,
                  onPressed: () => context.pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CuyCashSpacing.stackXs),
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
