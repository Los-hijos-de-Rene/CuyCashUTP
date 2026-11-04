import 'package:flutter/foundation.dart';

/// Estado de bloqueo por inactividad.
///
/// **No cierra la sesión**: tapa la app con el acceso rápido hasta que el PIN o
/// la huella la liberen. El router escucha este objeto y, mientras esté
/// bloqueado, manda cualquier ruta a `/acceso-rapido` (salvo las de gate).
class SessionLock extends ChangeNotifier {
  bool _locked = false;

  bool get isLocked => _locked;

  /// Bloquea una sola vez; avisar dos veces no duplica la navegación.
  void lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  /// Libera el bloqueo (lo llama un login o acceso rápido exitoso).
  void unlock() {
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }
}
