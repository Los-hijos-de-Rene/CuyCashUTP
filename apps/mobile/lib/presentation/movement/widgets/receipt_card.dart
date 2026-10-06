import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/format/soles.dart';
import '../../../l10n/app_localizations.dart';

/// La constancia de una operación: la MISMA para un envío recién hecho y para
/// el detalle de un movimiento viejo. Lo que cada pantalla no sabe, lo omite
/// (`null`): el envío recién hecho no conoce el saldo posterior; el histórico
/// no sabe si fue una repetición idempotente.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    required this.headline,
    required this.monto,
    required this.fecha,
    required this.transactionId,
    required this.estado,
    this.contraparteLabel,
    this.contraparte,
    this.cuentaDestinoMasked,
    this.motivo,
    this.saldoPosterior,
    this.reutilizada = false,
    super.key,
  });

  final String headline;

  /// Siempre positivo: el titular ya dice si salió o entró.
  final Money monto;
  final DateTime fecha;
  final String transactionId;

  /// `pendiente` | `confirmada` | `revertida`. Un valor que la app no conoce
  /// se muestra tal cual en vez de inventarle un significado.
  final String estado;

  /// Rótulo de [contraparte] (`Enviado a`, `Recibido de`…).
  final String? contraparteLabel;
  final String? contraparte;
  final String? cuentaDestinoMasked;
  final String? motivo;
  final Money? saldoPosterior;

  /// El servidor devolvió la operación original en vez de crear otra.
  final bool reutilizada;

  /// Los pares rótulo/valor que la constancia muestra, en orden. Los usa
  /// también el texto para compartir, para que ambos digan lo mismo.
  List<(String, String)> lines(AppLocalizations l10n) => [
    if (contraparte != null)
      (contraparteLabel ?? l10n.movementDetailCounterparty, contraparte!),
    if (cuentaDestinoMasked != null)
      (l10n.movementDetailDestinationAccount, cuentaDestinoMasked!),
    if (motivo != null && motivo!.isNotEmpty)
      (l10n.movementDetailReason, motivo!),
    (l10n.movementDetailStatus, _estadoTexto(l10n)),
    (
      l10n.transferReceiptDate,
      DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal()),
    ),
    if (saldoPosterior != null)
      (l10n.movementDetailBalanceAfter, formatSoles(saldoPosterior!)),
    (l10n.transferReceiptId, transactionId),
  ];

  /// Resumen en texto plano para compartir.
  String shareText(AppLocalizations l10n) => [
    l10n.movementShareHeader,
    '$headline: ${formatSoles(monto)}',
    for (final (label, value) in lines(l10n)) '$label: $value',
  ].join('\n');

  String _estadoTexto(AppLocalizations l10n) => switch (estado) {
    'confirmada' => l10n.movementStatusConfirmed,
    'pendiente' => l10n.movementStatusPending,
    'revertida' => l10n.movementStatusReverted,
    final otro => otro,
  };

  (IconData, Color) get _icono => switch (estado) {
    'confirmada' => (Icons.check_circle, CuyCashColors.success),
    'pendiente' => (Icons.schedule, CuyCashColors.secondaryText),
    'revertida' => (Icons.replay, CuyCashColors.secondaryText),
    _ => (Icons.info_outline, CuyCashColors.secondaryText),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color) = _icono;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 56, color: color),
        const SizedBox(height: CuyCashSpacing.stackMd),
        Text(headline, style: CuyCashTypography.headlineSm),
        const SizedBox(height: CuyCashSpacing.stackXs),
        Text(formatSoles(monto), style: CuyCashTypography.headlineMd),
        const SizedBox(height: CuyCashSpacing.stackLg),
        SurfaceCard(
          child: Column(
            children: [
              for (final (label, value) in lines(l10n))
                _Line(label: label, value: value),
            ],
          ),
        ),
        if (reutilizada) ...[
          const SizedBox(height: CuyCashSpacing.stackMd),
          InfoStrip(
            icon: Icons.info_outline,
            text: l10n.transferReceiptReused,
          ),
        ],
      ],
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
