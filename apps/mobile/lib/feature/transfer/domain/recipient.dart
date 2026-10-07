import 'recipient_account.dart';

/// El destino ELEGIDO de un envío: la persona y una de sus cuentas.
///
/// El nombre llega ENMASCARADO (`C*** A*** N***`): confirma lo justo para que
/// quien ya conoce a la persona la reconozca. El teléfono no debe intentar
/// reconstruirlo.
class Recipient {
  const Recipient({
    required this.nombreEnmascarado,
    required this.cuenta,
  });

  final String nombreEnmascarado;
  final RecipientAccount cuenta;
}
