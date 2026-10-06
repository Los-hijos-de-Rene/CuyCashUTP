import '../../lockout/domain/lockout_policy.dart';
import '../domain/linked_device.dart';

/// "Servidor" en memoria compartido por `MemoryAuthRepository` y
/// `MemorySecurityRepository` (como `MemoryLedger` para cuentas): cambiar el
/// PIN aquí cambia el PIN con el que entra el login, y una credencial
/// emitida aquí es la que acepta `signInWithBiometric`.
class MemorySecurityState {
  MemorySecurityState({
    required this.pin,
    required this.dni,
    required this.thisDeviceId,
    required List<LinkedDevice> devices,
  }) : devices = [...devices];

  static const otroDispositivoId = 'mem-otro';

  /// Los mismos intentos que la política de bloqueo de la app (R1).
  static const maxAttempts = LockoutPolicy.maxAttempts;

  factory MemorySecurityState.demo({
    required DateTime Function() clock,
    String pin = '000000',
  }) {
    final ahora = clock().toUtc();
    return MemorySecurityState(
      pin: pin,
      dni: '70123456',
      thisDeviceId: 'mem-este',
      devices: [
        LinkedDevice(
          id: 'mem-este',
          nombre: 'Este teléfono (demo)',
          plataforma: 'android',
          vinculadoEl: ahora.subtract(const Duration(days: 30)),
          ultimoUso: ahora,
          esEste: true,
          conHuella: false,
        ),
        LinkedDevice(
          id: otroDispositivoId,
          nombre: 'iPhone14,5',
          plataforma: 'ios',
          vinculadoEl: ahora.subtract(const Duration(days: 10)),
          ultimoUso: ahora.subtract(const Duration(days: 2)),
          esEste: false,
          conHuella: false,
        ),
      ],
    );
  }

  String pin;

  /// DNI del titular con sesión; `MemoryAuthRepository` lo actualiza al
  /// abrir sesión (default de la demo: 70123456).
  String dni;
  final String thisDeviceId;
  final List<LinkedDevice> devices;

  /// Secreto vigente → id del dispositivo que lo tiene.
  final Map<String, String> credentials = {};
  int attemptsLeft = maxAttempts;
  DateTime? lockedUntil;
}
