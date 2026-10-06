/// Datos del titular tal como los guarda el servidor (vienen del KYC). Solo
/// lectura: cambiarlos exigiría volver a verificar la identidad.
class PersonalData {
  const PersonalData({
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.emailMasked,
    required this.alias,
    required this.kycVerified,
    required this.clienteDesde,
  });

  final String dni;
  final String nombres;
  final String apellidos;

  /// Nunca el correo completo: el servidor ya lo manda enmascarado.
  final String emailMasked;
  final String alias;
  final bool kycVerified;

  /// En UTC; se pasa a hora local solo al mostrar.
  final DateTime clienteDesde;

  PersonalData copyWith({String? alias, bool? kycVerified}) => PersonalData(
        dni: dni,
        nombres: nombres,
        apellidos: apellidos,
        emailMasked: emailMasked,
        alias: alias ?? this.alias,
        kycVerified: kycVerified ?? this.kycVerified,
        clienteDesde: clienteDesde,
      );
}
