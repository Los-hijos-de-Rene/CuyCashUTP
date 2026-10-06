import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format/money_format.dart';
import '../../feature/beneficiary/domain/beneficiary_limits.dart';
import '../../feature/transfer/domain/transfer_limits.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/transfer_bloc.dart';
import 'money_input_formatter.dart';

/// Paso 2 del envío: cuánto. El campo solo deja teclear lo que `Money.parse`
/// sabe leer; si algo se rechaza, lo dice.
class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  static const _quickAmounts = [20, 50, 100, 200];

  final _amount = TextEditingController();
  final _motivo = TextEditingController();
  final _apodo = TextEditingController();

  /// Aviso del último rechazo del formateador; `null` si no hay.
  String? _rejectedMessage;

  @override
  void initState() {
    super.initState();
    // Al volver desde la confirmación se recupera lo que ya estaba elegido.
    final bloc = context.read<TransferBloc>();
    final monto = bloc.state.monto;
    if (monto != null) _amount.text = _toInput(monto);
    _motivo.text = bloc.state.motivo ?? '';
    _apodo.text = bloc.state.apodoFrecuente;
  }

  @override
  void dispose() {
    _amount.dispose();
    _motivo.dispose();
    _apodo.dispose();
    super.dispose();
  }

  static String _toInput(Money m) {
    final soles = m.centimos ~/ 100;
    final cents = m.centimos % 100;
    return cents == 0 ? '$soles' : '$soles.${cents.toString().padLeft(2, '0')}';
  }

  /// Un separador al final (`5.`) es una edición a medias, no un error.
  bool get _incomplete {
    final t = _amount.text;
    return t.endsWith('.') || t.endsWith(',');
  }

  /// `null` si el texto no es un monto legible.
  Money? _parsed(Currency moneda) => Money.parse(_amount.text, moneda);

  String? _error(AppLocalizations l10n, Money disponible, Currency moneda) {
    if (_amount.text.isEmpty || _incomplete) return null;
    final monto = _parsed(moneda);
    if (monto == null) return l10n.transferAmountInvalid;
    if (monto < TransferLimits.montoMinimo(moneda)) {
      return l10n.transferAmountZero(formatMoney(Money.zero(moneda)));
    }
    if (monto > TransferLimits.montoMaximo(moneda)) {
      return l10n.transferAmountOverMax(
        formatMoney(TransferLimits.montoMaximo(moneda)),
      );
    }
    if (monto > disponible) {
      return l10n.transferAmountOverBalance(formatMoney(disponible));
    }
    return null;
  }

  void _continue(Currency moneda) {
    final monto = _parsed(moneda);
    if (monto == null) return;
    context.read<TransferBloc>().add(
      TransferEvent.amountEntered(monto: monto, motivo: _motivo.text),
    );
    context.push(AppRoutes.enviarConfirmar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TransferBloc>().state;
    final moneda = state.cuenta?.moneda ?? Currency.pen;
    final disponible = state.cuenta?.saldoDisponible ?? Money.zero(moneda);
    final destinatario = state.destinatario;
    // El rechazo del formateador tiene su propio aviso; si no, el de validación.
    final error = _rejectedMessage ?? _error(l10n, disponible, moneda);
    final valid =
        _rejectedMessage == null &&
        _parsed(moneda) != null &&
        !_incomplete &&
        _error(l10n, disponible, moneda) == null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferAmountTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.transferAmountHeadline,
                style: CuyCashTypography.headlineSm,
              ),
              if (destinatario != null) ...[
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(
                  l10n.transferAmountTo(destinatario.nombreEnmascarado),
                  style: CuyCashTypography.bodyLg.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: CuyCashSpacing.stackLg),
              CuyCashTextField(
                label: l10n.transferAmountLabel,
                hint: l10n.transferAmountHint,
                controller: _amount,
                autofocus: true,
                errorText: error,
                helperText: l10n.transferAvailable(formatMoney(disponible)),
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
                onChanged: (_) => setState(() => _rejectedMessage = null),
              ),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Wrap(
                spacing: CuyCashSpacing.stackSm,
                children: [
                  for (final unidades in _quickAmounts)
                    ActionChip(
                      label: Text(formatMoney(Money(unidades * 100, moneda))),
                      onPressed: () => setState(() {
                        _rejectedMessage = null;
                        _amount.text = '$unidades';
                      }),
                    ),
                ],
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              CuyCashTextField(
                label: l10n.transferMotivoLabel,
                hint: l10n.transferMotivoHint,
                controller: _motivo,
                maxLength: TransferLimits.motivoMaxLength,
              ),
              if (context.read<TransferBloc>().puedeGuardarFrecuentes) ...[
                const SizedBox(height: CuyCashSpacing.stackMd),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.transferSaveFrequentTitle,
                    style: CuyCashTypography.bodyLg,
                  ),
                  subtitle: Text(
                    l10n.transferSaveFrequentHint,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                  value: state.guardarFrecuente,
                  onChanged: (value) => context.read<TransferBloc>().add(
                    TransferEvent.saveFrequentToggled(value),
                  ),
                ),
                if (state.guardarFrecuente)
                  CuyCashTextField(
                    label: l10n.transferFrequentNicknameLabel,
                    hint: destinatario?.nombreEnmascarado,
                    controller: _apodo,
                    maxLength: BeneficiaryLimits.apodoMaxLength,
                    onChanged: (v) => context.read<TransferBloc>().add(
                      TransferEvent.frequentNicknameChanged(v),
                    ),
                  ),
              ],
              const SizedBox(height: CuyCashSpacing.stackLg),
              PrimaryButton(
                label: l10n.transferContinue,
                onPressed: valid ? () => _continue(moneda) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
