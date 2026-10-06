/// Un frecuente: alguien a quien el titular ya validó y guardó.
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.dni,
    required this.apodo,
    this.nombreEnmascarado,
  });

  final String id;
  final String dni;
  final String apodo;

  /// `null` si esa persona ya no figura como cliente (el backend hace un
  /// `outer join`).
  final String? nombreEnmascarado;
}
