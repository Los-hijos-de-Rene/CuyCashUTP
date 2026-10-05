/// Un envío que llegó a salir hacia el servidor y cuyo resultado la app no
/// llegó a conocer. Guarda su clave de idempotencia para poder reintentarlo
/// con la MISMA aunque el flujo (o la app) se haya cerrado entretanto.
class PendingTransfer {
  const PendingTransfer({
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String idempotencyKey;

  /// Instante (UTC) en que el envío salió; sirve para caducarlo.
  final DateTime createdAt;
}

/// Persistencia de envíos pendientes, SEPARADA POR USUARIO: la clave de una
/// persona no puede reutilizarse en la sesión de otra.
///
/// La clave no es un secreto (es un identificador de operación), por eso no
/// hace falta el almacén seguro. Nunca lanza: ante un fallo de lectura devuelve
/// vacío y ante uno de escritura calla (la protección se pierde, el envío no
/// debe bloquearse por ello).
abstract interface class PendingTransferStore {
  /// Entradas del usuario, por huella de la intención.
  Future<Map<String, PendingTransfer>> readAll(String userId);

  /// Reemplaza TODAS las entradas del usuario.
  Future<void> writeAll(String userId, Map<String, PendingTransfer> entries);
}
