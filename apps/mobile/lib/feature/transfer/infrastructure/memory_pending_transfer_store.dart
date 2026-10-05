import '../domain/pending_transfer_store.dart';

/// Impl en memoria (flavor `mock` y tests). Aislada por usuario.
class MemoryPendingTransferStore implements PendingTransferStore {
  final _porUsuario = <String, Map<String, PendingTransfer>>{};

  @override
  Future<Map<String, PendingTransfer>> readAll(String userId) async =>
      Map.of(_porUsuario[userId] ?? const {});

  @override
  Future<void> writeAll(
    String userId,
    Map<String, PendingTransfer> entries,
  ) async {
    _porUsuario[userId] = Map.of(entries);
  }
}
