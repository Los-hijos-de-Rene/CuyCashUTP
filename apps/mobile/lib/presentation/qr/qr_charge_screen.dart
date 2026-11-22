import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/format/money_format.dart';
import '../../feature/account/domain/account.dart';
import '../../feature/qr/domain/qr_charge.dart';
import '../../feature/qr/domain/qr_failure.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/qr_charge_bloc.dart';
import 'qr_error_text.dart';
import 'widgets/qr_share.dart';

/// Paso de cobro: monto + concepto → QR firmado con caducidad.
class QrChargeScreen extends StatelessWidget {
  const QrChargeScreen({required this.cuenta, super.key});

  final Account cuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<QrChargeBloc>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrChargeTitle)),
      body: switch (state.status) {
        QrChargeStatus.idle ||
        QrChargeStatus.generating =>
          _ChargeForm(cuenta: cuenta, generating: state.status == QrChargeStatus.generating),
        QrChargeStatus.ready => _ChargeReady(charge: state.charge!),
        QrChargeStatus.error => _ChargeError(failure: state.failure!),
      },
    );
  }
}

class _ChargeForm extends StatefulWidget {
  const _ChargeForm({required this.cuenta, required this.generating});

  final Account cuenta;
  final bool generating;

  @override
  State<_ChargeForm> createState() => _ChargeFormState();
}

class _ChargeFormState extends State<_ChargeForm> {
  final _monto = TextEditingController();
  final _concepto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    _concepto.dispose();
    super.dispose();
  }

  void _generar() {
    final l10n = AppLocalizations.of(context);
    final monto = Money.parse(_monto.text, widget.cuenta.moneda);
    final concepto = _concepto.text.trim();
    if (monto == null || monto <= Money.zero(widget.cuenta.moneda)) {
      setState(() => _error = l10n.qrChargeAmountInvalid);
      return;
    }
    if (concepto.isEmpty) {
      setState(() => _error = l10n.qrChargeConceptRequired);
      return;
    }
    setState(() => _error = null);
    context.read<QrChargeBloc>().add(
      QrChargeRequested(
        cuentaId: widget.cuenta.id,
        monto: monto,
        concepto: concepto,
        idempotencyKey:
            'qr-emit-${widget.cuenta.id}-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      children: [
        Text(l10n.qrChargeHeadline, style: CuyCashTypography.headlineSm),
        const SizedBox(height: CuyCashSpacing.stackXs),
        Text(
          l10n.qrChargeBody,
          style: CuyCashTypography.bodyMd
              .copyWith(color: CuyCashColors.secondaryText),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        CuyCashTextField(
          label: l10n.qrChargeAmountLabel,
          controller: _monto,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixText: widget.cuenta.moneda.symbol,
          onSubmitted: (_) => _generar(),
        ),
        const SizedBox(height: CuyCashSpacing.stackMd),
        CuyCashTextField(
          label: l10n.qrChargeConceptLabel,
          hint: l10n.qrChargeConceptHint,
          controller: _concepto,
          // El backend acepta 40 (`QREmitirIn.concepto`): con 60, de 41 a 60
          // caracteres el cobro fallaba con 422.
          maxLength: QrCharge.conceptoMaximo,
          onSubmitted: (_) => _generar(),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: CuyCashSpacing.stackSm),
          Text(
            error,
            style: CuyCashTypography.bodyMd.copyWith(color: CuyCashColors.error),
          ),
        ],
        const SizedBox(height: CuyCashSpacing.stackLg),
        PrimaryButton(
          label: l10n.qrChargeGenerate,
          loading: widget.generating,
          onPressed: _generar,
        ),
      ],
    );
  }
}

class _ChargeReady extends StatefulWidget {
  const _ChargeReady({required this.charge});

  final QrCharge charge;

  @override
  State<_ChargeReady> createState() => _ChargeReadyState();
}

class _ChargeReadyState extends State<_ChargeReady> {
  /// La tarjeta que se comparte como imagen: QR + monto + concepto + vence.
  final _tarjeta = GlobalKey();
  bool _compartiendo = false;

  Future<void> _compartir() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _compartiendo = true);
    final ok = await compartirTarjetaQr(
      tarjeta: _tarjeta,
      texto: l10n.qrChargeShareText(
        formatMoney(widget.charge.monto),
        widget.charge.concepto,
      ),
      archivo: 'cobro-cuycash.png',
      origen: origenDeCompartir(context),
    );
    if (!mounted) return;
    setState(() => _compartiendo = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.qrChargeShareError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final charge = widget.charge;
    final vence = DateFormat('dd/MM HH:mm').format(charge.expira.toLocal());
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      children: [
        Text(l10n.qrChargeReady, style: CuyCashTypography.headlineSm),
        const SizedBox(height: CuyCashSpacing.stackSm),
        Text(
          l10n.qrChargeReadyBody,
          style: CuyCashTypography.bodyMd
              .copyWith(color: CuyCashColors.secondaryText),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        SurfaceCard(
          child: RepaintBoundary(
            key: _tarjeta,
            // Fondo opaco: sin él, la imagen compartida sale con el fondo
            // transparente y en modo oscuro el QR no se lee.
            child: ColoredBox(
              color: CuyCashColors.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(CuyCashSpacing.stackSm),
                child: Column(
                  children: [
                    Text(
                      l10n.qrChargeCardBrand,
                      style: CuyCashTypography.labelMd
                          .copyWith(color: CuyCashColors.secondaryText),
                    ),
                    const SizedBox(height: CuyCashSpacing.stackSm),
                    QrImageView(
                      data: charge.payload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: CuyCashColors.surfaceContainerLowest,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackMd),
                    Text(
                      formatMoney(charge.monto),
                      style: CuyCashTypography.headlineSm,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackXs),
                    Text(
                      charge.concepto,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.bodyLg,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackXs),
                    Text(
                      l10n.qrChargeExpires(vence),
                      style: CuyCashTypography.labelMd
                          .copyWith(color: CuyCashColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        PrimaryButton(
          label: l10n.qrChargeShare,
          loading: _compartiendo,
          onPressed: _compartiendo ? null : _compartir,
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        SecondaryButton(
          label: l10n.qrChargeDone,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}

class _ChargeError extends StatelessWidget {
  const _ChargeError({required this.failure});

  final QrFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.error_outline, size: 48, color: CuyCashColors.error),
          const SizedBox(height: CuyCashSpacing.stackMd),
          Text(
            qrErrorText(l10n, failure),
            textAlign: TextAlign.center,
            style: CuyCashTypography.bodyLg,
          ),
          const Spacer(),
          PrimaryButton(
            label: l10n.qrRetry,
            onPressed: () =>
                context.read<QrChargeBloc>().add(const QrChargeReset()),
          ),
          const SizedBox(height: CuyCashSpacing.stackSm),
          SecondaryButton(
            label: l10n.qrBackHome,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
