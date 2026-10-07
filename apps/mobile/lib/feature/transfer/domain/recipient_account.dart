import 'package:core_kernel/core_kernel.dart';

import '../../account/domain/account_type.dart';

/// Una cuenta que puede recibir, tal como la informa el directorio.
///
/// Del número solo llegan los últimos cuatro dígitos. [nombre] es el que el
/// titular le puso a su cuenta, y solo viene cuando la cuenta es del que
/// pregunta (pasar dinero entre cuentas propias).
class RecipientAccount {
  const RecipientAccount({
    required this.cuentaId,
    required this.tipo,
    required this.moneda,
    required this.numeroMasked,
    this.nombre,
  });

  /// Id opaco: es lo que viaja en `POST /v1/transfers`.
  final String cuentaId;
  final AccountType tipo;
  final Currency moneda;

  /// `••••NNNN`.
  final String numeroMasked;
  final String? nombre;
}

/// Lee la forma `{cuenta_id, tipo, moneda, numero_masked, nombre}` del
/// backend. Un tipo o una moneda desconocidos lanzan `FormatException`: quien
/// llama la convierte en fallo inesperado (nunca se adivina la moneda).
RecipientAccount recipientAccountFromJson(Map<String, dynamic> j) =>
    RecipientAccount(
      cuentaId: j['cuenta_id'] as String,
      tipo:
          AccountType.fromCode(j['tipo'] as String) ??
          (throw FormatException('Tipo desconocido: ${j['tipo']}')),
      moneda:
          Currency.fromCode(j['moneda'] as String) ??
          (throw FormatException('Moneda desconocida: ${j['moneda']}')),
      numeroMasked: j['numero_masked'] as String,
      nombre: j['nombre'] as String?,
    );
