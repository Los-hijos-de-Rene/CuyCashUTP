import 'package:core_kernel/core_kernel.dart';

/// Límites de una transferencia. Espejo de `MONTO_MINIMO`/`MONTO_MAXIMO` de
/// `services/api/.../transfers.py` y del `motivo` (≤ 40): la UI los aplica
/// ANTES de enviar para no pagar un 422 que la app no sabe explicar.
abstract final class TransferLimits {
  /// Mismo rango en cualquier moneda (espejo de `MONTO_MINIMO`/`MONTO_MAXIMO`).
  static Money montoMinimo(Currency moneda) => Money(1, moneda);
  static Money montoMaximo(Currency moneda) => Money(200000, moneda);

  /// Máximo de caracteres del motivo. El cliente HTTP no lo recorta.
  static const motivoMaxLength = 40;

  /// Recorta [motivo] al máximo (por puntos de código, como cuenta el
  /// backend); `null` si queda vacío.
  static String? normalizarMotivo(String? motivo) {
    final limpio = (motivo ?? '').trim();
    if (limpio.isEmpty) return null;
    return String.fromCharCodes(limpio.runes.take(motivoMaxLength));
  }
}
