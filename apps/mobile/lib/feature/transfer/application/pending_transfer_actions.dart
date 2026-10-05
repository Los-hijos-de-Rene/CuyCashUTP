import 'package:core_kernel/core_kernel.dart';

import '../domain/pending_transfer_store.dart';

/// Recuerda la clave de idempotencia de un envío que pudo haberse ejecutado,
/// ligada a su INTENCIÓN (cuenta + destinatario + monto + motivo), para que
/// reentrar al flujo con la misma intención recupere la misma clave en vez de
/// fabricar otra y cobrar dos veces.
///
/// Vencimiento [vigencia] (24 h): lo bastante largo para cubrir cerrar la app,
/// perder señal o volver al día siguiente a mirar si salió; lo bastante corto
/// para que una intención de hace días (otra cena, otro préstamo) no reviva y
/// el servidor responda con la operación vieja.
///
/// Se guarda JUSTO ANTES de enviar (no al generar la clave): solo existe
/// entrada para lo que de verdad pudo salir. Se borra al confirmarse, y ante
/// un fallo definitivo (el servidor dijo que no se movió nada).
class PendingTransferActions {
  const PendingTransferActions(
    this._store, {
    required DateTime Function() clock,
    this.vigencia = const Duration(hours: 24),
  }) : _clock = clock;

  final PendingTransferStore _store;
  final DateTime Function() _clock;
  final Duration vigencia;

  /// Huella estable de una intención.
  static String huella({
    required String cuentaId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
  }) => '$cuentaId|$destinatarioDni|${monto.centimos}|${motivo ?? ''}';

  Map<String, PendingTransfer> _vigentes(Map<String, PendingTransfer> todas) {
    final ahora = _clock().toUtc();
    return {
      for (final e in todas.entries)
        if (ahora.difference(e.value.createdAt.toUtc()) < vigencia)
          e.key: e.value,
    };
  }

  /// La clave pendiente de esta intención, o `null` si no hay o caducó.
  Future<String?> recover(String userId, String huella) async =>
      _vigentes(await _store.readAll(userId))[huella]?.idempotencyKey;

  /// ¿Hay CUALQUIER envío pendiente vigente de este usuario? Sirve para avisar
  /// cuando la intención nueva no coincide exacta con la pendiente (otro
  /// monto, otro motivo...) y por eso no se puede reconocer como repetida.
  Future<bool> hasPending(String userId) async =>
      _vigentes(await _store.readAll(userId)).isNotEmpty;

  /// Anota la clave de esta intención (y limpia las caducadas). `false` si NO
  /// quedó guardada: el envío debe seguir, pero el usuario sin red de
  /// seguridad tiene que saberlo.
  Future<bool> remember(String userId, String huella, String key) async {
    final todas = _vigentes(await _store.readAll(userId));
    // Si ya había una para esta intención se conserva con su fecha original:
    // reintentar no la rejuvenece.
    todas.putIfAbsent(
      huella,
      () => PendingTransfer(idempotencyKey: key, createdAt: _clock().toUtc()),
    );
    return _store.writeAll(userId, todas);
  }

  Future<void> forget(String userId, String huella) async {
    final todas = _vigentes(await _store.readAll(userId));
    todas.remove(huella);
    await _store.writeAll(userId, todas);
  }
}
