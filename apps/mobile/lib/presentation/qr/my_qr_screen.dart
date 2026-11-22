import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../feature/account/domain/account.dart';
import '../../feature/qr/domain/qr_failure.dart';
import '../../feature/qr/domain/qr_static.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/my_qr_bloc.dart';
import 'qr_error_text.dart';
import 'widgets/qr_share.dart';

/// "Mi QR": el QR permanente de la cuenta. Quien lo escanea elige cuánto
/// pagar. Se comparte como imagen (nunca el token en texto) y se puede
/// cambiar: el anterior deja de aceptar pagos.
class MyQrScreen extends StatelessWidget {
  const MyQrScreen({required this.cuenta, super.key});

  final Account cuenta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrMyTitle)),
      body: BlocConsumer<MyQrBloc, MyQrState>(
        listenWhen: (antes, ahora) => ahora is MyQrReady &&
            (ahora.regenerado || ahora.failure != null),
        listener: (context, state) {
          final texto = switch (state) {
            MyQrReady(regenerado: true) => l10n.qrMyRegenerated,
            MyQrReady(failure: final f?) => qrErrorText(l10n, f),
            _ => null,
          };
          if (texto != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(texto)));
          }
        },
        builder: (context, state) => switch (state) {
          MyQrLoading() => const Center(child: CircularProgressIndicator()),
          MyQrReady(:final qr, :final regenerando) =>
            _MyQrReady(qr: qr, cuenta: cuenta, regenerando: regenerando),
          MyQrError(:final failure) => _MyQrError(failure: failure),
        },
      ),
    );
  }
}

class _MyQrReady extends StatefulWidget {
  const _MyQrReady({
    required this.qr,
    required this.cuenta,
    required this.regenerando,
  });

  final QrStatic qr;
  final Account cuenta;
  final bool regenerando;

  @override
  State<_MyQrReady> createState() => _MyQrReadyState();
}

class _MyQrReadyState extends State<_MyQrReady> {
  final _tarjeta = GlobalKey();
  bool _compartiendo = false;

  Future<void> _compartir() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _compartiendo = true);
    final ok = await compartirTarjetaQr(
      tarjeta: _tarjeta,
      texto: l10n.qrMyShareText,
      archivo: 'mi-qr-cuycash.png',
      origen: origenDeCompartir(context),
    );
    if (!mounted) return;
    setState(() => _compartiendo = false);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.qrChargeShareError)));
    }
  }

  Future<void> _confirmarCambio() async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<MyQrBloc>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.qrMyRegenerateTitle),
        content: Text(l10n.qrMyRegenerateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.qrMyRegenerateCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.qrMyRegenerateConfirm),
          ),
        ],
      ),
    );
    if (confirmado ?? false) bloc.add(const MyQrRegenerateRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ocupado = _compartiendo || widget.regenerando;
    return ListView(
      padding: const EdgeInsets.all(CuyCashSpacing.marginMobile),
      children: [
        Text(l10n.qrMyHeadline, style: CuyCashTypography.headlineSm),
        const SizedBox(height: CuyCashSpacing.stackXs),
        Text(
          l10n.qrMyBody,
          style: CuyCashTypography.bodyMd
              .copyWith(color: CuyCashColors.secondaryText),
        ),
        const SizedBox(height: CuyCashSpacing.stackLg),
        SurfaceCard(
          child: RepaintBoundary(
            key: _tarjeta,
            // Fondo opaco: sin él, la imagen compartida sale transparente y en
            // modo oscuro el QR no se lee.
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
                      data: widget.qr.payload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: CuyCashColors.surfaceContainerLowest,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackMd),
                    Text(
                      l10n.qrMyCardHint,
                      textAlign: TextAlign.center,
                      style: CuyCashTypography.bodyLg,
                    ),
                    const SizedBox(height: CuyCashSpacing.stackXs),
                    Text(
                      l10n.qrMyCardAccount(
                        widget.cuenta.numeroMasked,
                        widget.qr.moneda.symbol,
                      ),
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
          label: l10n.qrMyShare,
          loading: _compartiendo,
          onPressed: ocupado ? null : _compartir,
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        SecondaryButton(
          label: l10n.qrMyRegenerate,
          onPressed: ocupado ? null : _confirmarCambio,
        ),
      ],
    );
  }
}

class _MyQrError extends StatelessWidget {
  const _MyQrError({required this.failure});

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
                context.read<MyQrBloc>().add(const MyQrRequested()),
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
