import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format/soles.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
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
                const Icon(
                  Icons.check_circle,
                  size: 56,
                  color: CuyCashColors.success,
                ),
                const SizedBox(height: CuyCashSpacing.stackMd),
                Text(
                  l10n.transferReceiptHeadline,
                  style: CuyCashTypography.headlineSm,
                ),
                if (constancia != null) ...[
                  const SizedBox(height: CuyCashSpacing.stackXs),
                  Text(
                    formatSoles(constancia.monto),
                    style: CuyCashTypography.headlineMd,
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  SurfaceCard(
                    child: Column(
                      children: [
                        if (destinatario != null)
                          _Line(
                            label: l10n.transferReceiptTo,
                            value:
                                '${destinatario.nombreEnmascarado} · '
                                '${destinatario.cuentaDestinoMasked}',
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
                      text: l10n.transferReceiptReused,
                    ),
                  ],
                ],
                const Spacer(),
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
