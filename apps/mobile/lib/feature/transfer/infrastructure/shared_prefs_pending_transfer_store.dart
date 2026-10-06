import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pending_transfer_store.dart';

/// Persiste los envíos pendientes en `shared_preferences`, una clave por
/// usuario. Sobrevive a cerrar la app y a cerrar sesión; un usuario distinto
/// lee otra clave y no ve nada de lo ajeno.
class SharedPrefsPendingTransferStore implements PendingTransferStore {
  const SharedPrefsPendingTransferStore();

  static String _llave(String userId) => 'cuycash.pending_transfers.v1.$userId';

  @override
  Future<Map<String, PendingTransfer>> readAll(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crudo = prefs.getString(_llave(userId));
      if (crudo == null) return {};
      final json = jsonDecode(crudo) as Map<String, dynamic>;
      return {
        for (final e in json.entries)
          e.key: PendingTransfer(
            idempotencyKey: (e.value as Map)['key'] as String,
            createdAt: DateTime.parse((e.value as Map)['at'] as String),
          ),
      };
    } catch (_) {
      // Ilegible = como si no hubiera nada: no se inventa una clave vieja.
      return {};
    }
  }

  @override
  Future<bool> writeAll(
    String userId,
    Map<String, PendingTransfer> entries,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (entries.isEmpty) return await prefs.remove(_llave(userId));
      return await prefs.setString(
        _llave(userId),
        jsonEncode({
          for (final e in entries.entries)
            e.key: {
              'key': e.value.idempotencyKey,
              'at': e.value.createdAt.toUtc().toIso8601String(),
            },
        }),
      );
    } catch (_) {
      // Sin persistencia el envío sigue; quien llama se entera por el `false`.
      return false;
    }
  }
}
