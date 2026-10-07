import 'package:core_kernel/core_kernel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money_format.dart';
import '../../../l10n/app_localizations.dart';
import 'receipt_paper.dart';

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
    this.cuentaOrigen,
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

  /// La cuenta desde la que salió el dinero, ya con su rótulo.
  final String? cuentaOrigen;
  final String? motivo;
  final Money? saldoPosterior;

  /// El servidor devolvió la operación original en vez de crear otra.
  final bool reutilizada;

  /// Los pares rótulo/valor que la constancia muestra, en orden. Los usa
  /// también el texto para compartir, para que ambos digan lo mismo.
  List<(String, String)> lines(AppLocalizations l10n) => [
    if (contraparte case final c?)
      (contraparteLabel ?? l10n.movementDetailCounterparty, c),
    if (cuentaDestinoMasked case final cuenta?)
      (l10n.movementDetailDestinationAccount, cuenta),
    if (cuentaOrigen case final origen?)
      (l10n.movementDetailSourceAccount, origen),
    if (motivo case final m? when m.isNotEmpty) (l10n.movementDetailReason, m),
    (l10n.movementDetailStatus, _estadoTexto(l10n)),
    (
      l10n.transferReceiptDate,
      DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal()),
    ),
    if (saldoPosterior case final saldo?)
      (l10n.movementDetailBalanceAfter, formatMoney(saldo)),
    (l10n.transferReceiptId, transactionId),
  ];

  /// Resumen en texto plano para compartir.
  String shareText(AppLocalizations l10n) => [
    l10n.movementShareHeader,
    '$headline: ${formatMoney(monto)}',
    for (final (label, value) in lines(l10n)) '$label: $value',
  ].join('\n');

  String _estadoTexto(AppLocalizations l10n) => switch (estado) {
    'confirmada' => l10n.movementStatusConfirmed,
    'pendiente' => l10n.movementStatusPending,
    'revertida' => l10n.movementStatusReverted,
    final otro => otro,
  };

  (IconData, Color) get statusStyle => switch (estado) {
    'confirmada' => (Icons.check_circle, CuyCashColors.success),
    'pendiente' => (Icons.schedule, CuyCashColors.secondaryText),
    'revertida' => (Icons.replay, CuyCashColors.secondaryText),
    _ => (Icons.info_outline, CuyCashColors.secondaryText),
  };

  @override
  Widget build(BuildContext context) => ReceiptPaper(card: this);
}
