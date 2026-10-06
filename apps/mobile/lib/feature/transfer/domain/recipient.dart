/// Un destinatario resuelto por DNI, tal como lo informa el servidor.
///
/// El nombre llega ENMASCARADO (`C*** A*** N***`): confirma lo justo para que
/// quien ya conoce a la persona la reconozca. El teléfono no debe intentar
/// reconstruirlo.
class Recipient {
  const Recipient({
    required this.dni,
    required this.nombreEnmascarado,
    required this.cuentaDestinoMasked,
  });

  final String dni;
  final String nombreEnmascarado;

  /// `••••NNNN`: los últimos cuatro dígitos de la cuenta que recibirá.
  final String cuentaDestinoMasked;
}
