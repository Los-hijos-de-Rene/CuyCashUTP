import 'recipient_account.dart';

/// Lo que devuelve buscar un DNI o un alias: la persona (nombre ENMASCARADO y
/// su alias) y las cuentas suyas que pueden recibir, en el orden del servidor.
///
/// No trae el DNI: buscar por alias no lo revela, y al buscar por DNI el
/// usuario ya lo tenía.
class RecipientDirectory {
  const RecipientDirectory({
    required this.alias,
    required this.nombreEnmascarado,
    required this.cuentas,
  });

  final String alias;
  final String nombreEnmascarado;

  /// Nunca vacía en un éxito: sin cuentas activas el servidor responde 404.
  final List<RecipientAccount> cuentas;
}
