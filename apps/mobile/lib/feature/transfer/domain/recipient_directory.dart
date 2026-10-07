import 'recipient_account.dart';

/// Lo que devuelve buscar un DNI: la persona (nombre ENMASCARADO) y las
/// cuentas suyas que pueden recibir, en el orden del servidor.
class RecipientDirectory {
  const RecipientDirectory({
    required this.dni,
    required this.nombreEnmascarado,
    required this.cuentas,
  });

  final String dni;
  final String nombreEnmascarado;

  /// Nunca vacía en un éxito: sin cuentas activas el servidor responde 404.
  final List<RecipientAccount> cuentas;
}
