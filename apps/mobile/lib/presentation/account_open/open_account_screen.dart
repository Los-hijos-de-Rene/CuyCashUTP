import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/secure_screen_scope.dart';
import '../../feature/account/domain/account_failure.dart';
import '../../feature/account/domain/account_limits.dart';
import '../../feature/account/domain/account_type.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_label.dart';
import '../pin/pin_entry_view.dart';
import 'bloc/open_account_bloc.dart';
import 'open_account_error_text.dart';

/// Los dos pasos de la apertura, dentro de la misma ruta.
enum _Step { datos, pin }

/// Abrir otra cuenta en dos pasos: tipo, moneda y nombre; luego el PIN.
///
/// Los dos pasos comparten el [OpenAccountBloc] de la ruta: la clave de
/// idempotencia nace al abrir y no cambia por ir y volver entre pasos. Con la
/// cuenta abierta cierra con `pop(cuenta)`: el inicio la recibe.
///
/// **Con el resultado desconocido la intención queda sellada**: no se vuelve
/// a los datos ni se sale con atrás; solo quedan "Reintentar" (misma clave) o
/// salir con aviso.
class OpenAccountScreen extends StatefulWidget {
  const OpenAccountScreen({super.key});

  @override
  State<OpenAccountScreen> createState() => _OpenAccountScreenState();
}

class _OpenAccountScreenState extends State<OpenAccountScreen> {
  static const _pinLength = 6;

  final _nombre = TextEditingController();
  String _pin = '';
  _Step _step = _Step.datos;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  String _monedaNombre(AppLocalizations l10n, Currency m) => switch (m) {
    Currency.pen => l10n.currencyPenName,
    Currency.usd => l10n.currencyUsdName,
  };

  void _goToPin() {
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.pin);
  }

  void _backToDatos() => setState(() {
    _step = _Step.datos;
    _pin = '';
  });

  void _onDigit(OpenAccountState state, int digit) {
    if (state.status == OpenAccountStatus.submitting ||
        _pin.length >= _pinLength) {
      return;
    }
    setState(() => _pin += '$digit');
  }

  void _onBackspace(OpenAccountState state) {
    if (state.status == OpenAccountStatus.submitting || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.openAccountTitle),
        content: Text(l10n.openAccountErrorUnexpected),
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
    if (salir == true && context.mounted) context.pop();
  }

  void _onResult(BuildContext context, OpenAccountState state) {
    if (state.status == OpenAccountStatus.done) {
      final cuenta = state.cuenta;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop(cuenta);
      });
      return;
    }
    final failure = state.failure;
    if (failure != null && !failure.outcomeUnknown) setState(() => _pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<OpenAccountBloc, OpenAccountState>(
      listenWhen: (a, b) =>
          a.status == OpenAccountStatus.submitting &&
          b.status != OpenAccountStatus.submitting,
      listener: _onResult,
      builder: (context, state) {
        final bloqueado =
            state.status != OpenAccountStatus.editing || state.outcomeUnknown;
        final enPin = _step == _Step.pin;
        return PopScope(
          // Atrás en el PIN vuelve a los datos; con la intención sellada o la
          // apertura en vuelo no se va a ninguna parte.
          canPop: !enPin && !bloqueado,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && enPin && !bloqueado) _backToDatos();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: enPin && !bloqueado
                  ? BackButton(onPressed: _backToDatos)
                  : null,
              automaticallyImplyLeading: !bloqueado,
              title: Text(l10n.openAccountTitle),
            ),
            body: SecureScreenScope(
              child: SafeArea(
                child: enPin
                    ? _buildPinStep(context, state, l10n)
                    : _buildDatosStep(context, state, l10n),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatosStep(
    BuildContext context,
    OpenAccountState state,
    AppLocalizations l10n,
  ) {
    final bloc = context.read<OpenAccountBloc>();
    final nombreLargo =
        _nombre.text.trim().length > AccountLimits.nombreMaxLength;
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
                Text(
                  l10n.openAccountHeadline,
                  style: CuyCashTypography.headlineSm,
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                Text(
                  l10n.openAccountTypeLabel,
                  style: CuyCashTypography.labelMd,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Wrap(
                  spacing: CuyCashSpacing.stackSm,
                  children: [
                    for (final t in AccountType.values)
                      ChoiceChip(
                        label: Text(accountTypeShort(l10n, t)),
                        selected: state.tipo == t,
                        onSelected:
                            t == AccountType.sueldo && !state.sueldoDisponible
                            ? null
                            : (_) => bloc.add(OpenAccountEvent.tipoChanged(t)),
                      ),
                  ],
                ),
                if (!state.sueldoDisponible) ...[
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    l10n.openAccountSalaryTaken,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: CuyCashSpacing.stackLg),
                Text(
                  l10n.openAccountCurrencyLabel,
                  style: CuyCashTypography.labelMd,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                Wrap(
                  spacing: CuyCashSpacing.stackSm,
                  children: [
                    for (final m in Currency.values)
                      ChoiceChip(
                        label: Text(_monedaNombre(l10n, m)),
                        selected: state.moneda == m,
                        onSelected: state.monedaFija
                            ? null
                            : (_) =>
                                  bloc.add(OpenAccountEvent.monedaChanged(m)),
                      ),
                  ],
                ),
                if (state.monedaFija) ...[
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    l10n.openAccountSalaryOnlyPen,
                    style: CuyCashTypography.bodyMd.copyWith(
                      color: CuyCashColors.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: CuyCashSpacing.stackLg),
                CuyCashTextField(
                  label: l10n.openAccountNameLabel,
                  hint: l10n.openAccountNameHint,
                  controller: _nombre,
                  maxLength: AccountLimits.nombreMaxLength,
                  errorText: nombreLargo ? l10n.openAccountErrorName : null,
                  onChanged: (v) {
                    setState(() {});
                    bloc.add(OpenAccountEvent.nombreChanged(v));
                  },
                ),
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
          child: PrimaryButton(
            label: l10n.openAccountContinue,
            onPressed: nombreLargo || state.idempotencyKey.isEmpty
                ? null
                : _goToPin,
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep(
    BuildContext context,
    OpenAccountState state,
    AppLocalizations l10n,
  ) {
    final submitting = state.status == OpenAccountStatus.submitting;
    final failure = state.failure;
    final failed = failure != null && !submitting;
    final sealed = state.outcomeUnknown;
    final dead = failed && failure is AccountKeyReused;
    return Column(
      children: [
        Expanded(
          child: PinEntryView(
            headline: l10n.openAccountPinHeadline,
            subtitle: l10n.openAccountPinSubtitle(
              accountTypeLabel(l10n, state.tipo),
              _monedaNombre(l10n, state.moneda),
            ),
            pin: _pin,
            onDigit: (d) => _onDigit(state, d),
            onBackspace: () => _onBackspace(state),
            errorText: failed ? openAccountErrorText(l10n, failure) : null,
            hasError: failed && failure is AccountWrongPin,
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
                  onPressed: () => context.pop(),
                )
              else ...[
                PrimaryButton(
                  label: sealed
                      ? l10n.openAccountRetryCta
                      : l10n.openAccountCta,
                  loading: submitting,
                  onPressed: _pin.length == _pinLength
                      ? () => context.read<OpenAccountBloc>().add(
                          OpenAccountEvent.submitted(pin: _pin),
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
    );
  }
}
