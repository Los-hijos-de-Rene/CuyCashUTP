import 'package:core_kernel/core_kernel.dart';

/// Herramientas de desarrollo LOCAL: reiniciar la base y sembrar usuarios de
/// prueba en el backend de `services/api` (rutas `/v1/dev/*`).
///
/// Solo existe en el flavor `local` y con `DEV_TOOLS_KEY` configurada; en
/// `production` y `mock` no se construye. El backend, además, solo expone esas
/// rutas con su propio cerrojo (base local + DEV_TOOLS).
abstract interface class DevToolsRepository {
  /// Vacía la base local y crea los usuarios de prueba.
  FutureResult<DevToolsFailure, DevSeed> resetAndSeed();

  /// Crea los usuarios de prueba que falten, sin borrar nada.
  FutureResult<DevToolsFailure, DevSeed> seed();

  /// Últimos códigos OTP que envió el servidor (notificador `log`).
  FutureResult<DevToolsFailure, List<DevOtp>> latestOtps();
}

/// Un usuario de prueba sembrado en el backend.
class DevTestUser {
  const DevTestUser({
    required this.dni,
    required this.name,
    required this.alias,
  });

  final String dni;
  final String name;
  final String alias;
}

/// Resultado de sembrar: los usuarios y el PIN que comparten.
class DevSeed {
  const DevSeed({required this.users, required this.pin});

  final List<DevTestUser> users;
  final String pin;
}

/// Un código OTP visto por el servidor.
class DevOtp {
  const DevOtp({
    required this.destination,
    required this.code,
    required this.purpose,
  });

  final String destination;
  final String code;
  final String purpose;
}

/// Por qué falló una herramienta de desarrollo.
sealed class DevToolsFailure {
  const DevToolsFailure();

  /// El backend no tiene las rutas (DEV_TOOLS apagado o base no local) o no
  /// se pudo contactar.
  const factory DevToolsFailure.unavailable() = DevToolsUnavailable;

  /// La clave de la app no es la del backend.
  const factory DevToolsFailure.wrongKey() = DevToolsWrongKey;
}

final class DevToolsUnavailable extends DevToolsFailure {
  const DevToolsUnavailable();
}

final class DevToolsWrongKey extends DevToolsFailure {
  const DevToolsWrongKey();
}
