import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/money_format.dart';
import '../../feature/account/domain/account.dart';
import '../../feature/qr/domain/qr_payment_preview.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import '../pin/pin_entry_view.dart';
import 'bloc/qr_pay_bloc.dart';
import 'qr_error_text.dart';
import 'widgets/qr_camera_view.dart';

/// Paso de pago: cámara → vista previa (nombre + monto) → PIN → constancia.
class QrPayScreen extends StatelessWidget {
  const QrPayScreen({
    required this.cuentaOrigen,
    this.cameraBuilder,
    super.key,
  });

  final Account cuentaOrigen;

  /// Inyectable en pruebas para no abrir la cámara real.
  final Widget Function(ValueChanged<String> onDetected)? cameraBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<QrPayBloc>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrPayTitle)),
      body: switch (state.status) {
        QrPayStatus.scanning => _ScanBody(
            onDetected: (payload) =>
                context.read<QrPayBloc>().add(QrPayloadDetected(payload)),
            cameraBuilder: cameraBuilder,
          ),
        QrPayStatus.reading ||
        QrPayStatus.paying =>
          const Center(child: CircularProgressIndicator()),
        QrPayStatus.preview => _PreviewBody(preview: state.preview!),
        QrPayStatus.pin => _PinBody(state: state),
        QrPayStatus.done => _DoneBody(state: state),
        QrPayStatus.error => _ErrorBody(state: state),
      },
    );
  }
}

class _ScanBody extends StatefulWidget {
  const _ScanBody({required this.onDetected, this.cameraBuilder});

  final ValueChanged<String> onDetected;
  final Widget Function(ValueChanged<String> onDetected)? cameraBuilder;

  @override
  State<_ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends State<_ScanBody> {
  final _payload = TextEditingController();

  @override
  void dispose() {
    _payload.dispose();
    super.dispose();
  }

  void _leerPegado() {
    final value = _payload.text.trim();
    if (value.isEmpty) return;
    widget.onDetected(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = widget.cameraBuilder?.call(widget.onDetected) ??
        QrCameraView(onDetected: widget.onDetected);
    return Stack(
      fit: StackFit.expand,
      children: [
        camera,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
              child: SurfaceCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.qrPayScanHint,
                      style: CuyCashTypography.bodyLg,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackSm),
                    CuyCashTextField(
                      label: l10n.qrPayPasteLabel,
                      controller: _payload,
                      onSubmitted: (_) => _leerPegado(),
                    ),
                    const SizedBox(height: CuyCashSpacing.stackSm),
                    PrimaryButton(
                      label: l10n.qrPayRead,
                      onPressed: _leerPegado,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.preview});

  final QrPaymentPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vence = DateFormat('dd/MM HH:mm').format(preview.expira.toLocal());
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      children: [
        Text(l10n.qrPayPreviewHeadline, style: CuyCashTypography.headlineSm),
        const SizedBox(height: CuyCashSpacing.stackXs),
        Text(
          l10n.qrPayPreviewBody,
          style: CuyCashTypography.bodyMd
              .copyWith(color: CuyCashColors.secondaryText),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        SurfaceCard(
          child: Column(
            children: [
              _PreviewRow(label: l10n.qrPayTo, value: preview.nombreEnmascarado),
              const Divider(height: 24),
              _PreviewRow(
                label: l10n.qrPayAmount,
                value: formatMoney(preview.monto),
                emphasize: true,
              ),
              const Divider(height: 24),
              _PreviewRow(label: l10n.qrPayConcept, value: preview.concepto),
              const Divider(height: 24),
              _PreviewRow(label: l10n.qrPayExpires, value: vence),
            ],
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        PrimaryButton(
          label: l10n.qrPayContinue,
          onPressed: () =>
              context.read<QrPayBloc>().add(const QrPaySubmitted()),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        SecondaryButton(
          label: l10n.qrPayCancel,
          onPressed: () => context.read<QrPayBloc>().add(const QrPayReset()),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: CuyCashTypography.bodyMd
                .copyWith(color: CuyCashColors.secondaryText),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: emphasize
                ? CuyCashTypography.headlineSm
                : CuyCashTypography.bodyLg,
          ),
        ),
      ],
    );
  }
}

class _PinBody extends StatelessWidget {
  const _PinBody({required this.state});

  final QrPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = state.preview!;
    final failure = state.failure;
    return PinEntryView(
      headline: l10n.qrPayPinHeadline,
      subtitle: l10n.qrPayPinSubtitle(
        preview.nombreEnmascarado,
        formatMoney(preview.monto),
      ),
      pin: state.pin,
      hasError: failure != null,
      errorText: failure == null ? null : qrErrorText(l10n, failure),
      onDigit: (digit) =>
          context.read<QrPayBloc>().add(QrPayPinDigit(digit)),
      onBackspace: () =>
          context.read<QrPayBloc>().add(const QrPayPinBackspace()),
    );
  }
}

class _DoneBody extends StatelessWidget {
  const _DoneBody({required this.state});

  final QrPayState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final receipt = state.receipt!;
    final preview = state.preview!;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(receipt.fecha.toLocal());
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      children: [
        const SizedBox(height: CuyCashSpacing.stackLg),
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: CuyCashColors.success,
        ),
        const SizedBox(height: CuyCashSpacing.stackMd),
        Text(
          l10n.qrPayDoneHeadline,
          textAlign: TextAlign.center,
          style: CuyCashTypography.headlineSm,
        ),
        const SizedBox(height: CuyCashSpacing.stackXs),
        Text(
          l10n.qrPayDoneBody(
            formatMoney(receipt.monto),
            preview.nombreEnmascarado,
          ),
          textAlign: TextAlign.center,
          style: CuyCashTypography.bodyLg,
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        SurfaceCard(
          child: Column(
            children: [
              _PreviewRow(label: l10n.qrPayDate, value: fecha),
              const Divider(height: 24),
              _PreviewRow(
                label: l10n.qrPayOperation,
                value: receipt.transactionId,
              ),
            ],
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        PrimaryButton(
          label: l10n.qrPayDoneCta,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.state});

  final QrPayState state;

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
            qrErrorText(l10n, state.failure!),
            textAlign: TextAlign.center,
            style: CuyCashTypography.bodyLg,
          ),
          const Spacer(),
          PrimaryButton(
            label: l10n.qrRetry,
            onPressed: () =>
                context.read<QrPayBloc>().add(const QrPayReset()),
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
