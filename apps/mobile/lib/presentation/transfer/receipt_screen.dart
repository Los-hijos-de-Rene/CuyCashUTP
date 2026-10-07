import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_label.dart';
import '../app/app_routes.dart';
import '../movement/widgets/receipt_card.dart';
import '../movement/widgets/share_receipt_button.dart';
import 'bloc/transfer_bloc.dart';

/// Constancia del envío. El nombre del destinatario sale del `Recipient` ya
/// resuelto: la constancia del backend no lo trae.
///
/// Atrás lleva al inicio, no a la confirmación: volver ahí invitaría a
/// reenviar un envío que ya se hizo.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TransferBloc>().state;
    final constancia = state.constancia;
    final destinatario = state.destinatario;
    final card = constancia == null
        ? null
        : ReceiptCard(
            headline: l10n.transferReceiptHeadline,
            monto: constancia.monto,
            fecha: constancia.fecha,
            transactionId: constancia.transactionId,
            // Una constancia existe solo si el servidor confirmó.
            estado: 'confirmada',
            contraparteLabel: l10n.transferReceiptTo,
            contraparte: destinatario?.nombreEnmascarado,
            cuentaDestinoMasked: switch (destinatario) {
              final d? => recipientAccountShort(l10n, d.cuenta),
              null => null,
            },
            cuentaOrigen: switch (state.cuenta) {
              final c? => '${accountLabel(l10n, c)} · ${c.numeroMasked}',
              null => null,
            },
            motivo: state.motivo,
            reutilizada: constancia.reutilizada,
          );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
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
                if (card != null)
                  Expanded(child: SingleChildScrollView(child: card)),
                if (card == null) const Spacer(),
                if (state.frecuenteNoGuardado) ...[
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  InfoStrip(
                    icon: Icons.info_outline,
                    text: l10n.transferFrequentNotSaved,
                  ),
                ],
                if (card != null) ...[
                  const SizedBox(height: CuyCashSpacing.stackMd),
                  ShareReceiptButton(text: card.shareText(l10n)),
                ],
                const SizedBox(height: CuyCashSpacing.stackSm),
                PrimaryButton(
                  label: l10n.transferReceiptHome,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
