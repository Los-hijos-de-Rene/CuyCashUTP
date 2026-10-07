import '../../transfer/domain/recipient_account.dart';

/// Un frecuente: una CUENTA que el titular ya validó y guardó con un apodo.
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.dni,
    required this.apodo,
    this.nombreEnmascarado,
    this.cuenta,
  });

  final String id;
  final String dni;
  final String apodo;

  /// `null` si esa persona ya no figura como cliente.
  final String? nombreEnmascarado;

  /// La cuenta guardada; `null` si dejó de poder recibir (bloqueada o
  /// cerrada). Sin ella, tocar el frecuente vuelve a buscar por DNI.
  final RecipientAccount? cuenta;
}
