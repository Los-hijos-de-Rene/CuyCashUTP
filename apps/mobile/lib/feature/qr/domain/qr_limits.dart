import 'package:core_kernel/core_kernel.dart';

/// Límite diario de pagos con QR por titular y moneda. Espejo de
/// `LIMITE_DIARIO_QR` en `services/api/app/services/limite_diario.py`: si
/// cambia allá, cambia aquí. Lo hace cumplir el servidor; la app lo usa en el
/// doble en memoria y para avisar antes de pedir el PIN.
abstract final class QrLimits {
  static Money diario(Currency moneda) => switch (moneda) {
    Currency.pen => const Money(500000, Currency.pen),
    Currency.usd => const Money(150000, Currency.usd),
  };

  /// Largo máximo del mensaje del pagador (`QRPagarIn.mensaje`, VARCHAR(40)).
  static const mensajeMaximo = 40;
}
