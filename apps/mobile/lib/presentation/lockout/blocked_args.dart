import '../app/app_routes.dart';

/// De dónde vino el bloqueo. La pantalla es una sola, pero lo que se bloqueó
/// es distinto y el regreso también:
///
/// - [quickAccess] — se bloqueó ESTE teléfono; se vuelve al acceso rápido.
/// - [login] — se bloqueó el DNI en cualquier teléfono; se vuelve al login.
enum BlockedOrigin {
  quickAccess(AppRoutes.quickAccess),
  login(AppRoutes.login);

  const BlockedOrigin(this.entryRoute);

  /// Punto de entrada al que regresar cuando el contador llega a 00:00.
  final String entryRoute;
}

/// Argumentos con los que se navega a `/bloqueado`.
class BlockedArgs {
  const BlockedArgs({
    required this.origin,
    required this.lockedUntil,
    this.resumeDni,
  });

  final BlockedOrigin origin;
  final DateTime lockedUntil;

  /// DNI con el que se venía intentando. Al vencer el bloqueo se devuelve al
  /// login para retomar en el PIN: esperar el castigo y encima reescribir el
  /// documento castigaría dos veces el mismo error.
  final String? resumeDni;
}
