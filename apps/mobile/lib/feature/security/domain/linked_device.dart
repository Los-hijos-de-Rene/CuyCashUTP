/// Un teléfono con acceso a la cuenta, tal como lo describe el servidor.
class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.nombre,
    required this.plataforma,
    required this.vinculadoEl,
    required this.ultimoUso,
    required this.esEste,
    required this.conHuella,
  });

  final String id;

  /// Modelo que el teléfono declaró; `null` si nunca lo dijo.
  final String? nombre;

  /// `android` / `ios`; `null` si no se sabe.
  final String? plataforma;
  final DateTime vinculadoEl;
  final DateTime ultimoUso;
  final bool esEste;
  final bool conHuella;

  LinkedDevice copyWith({bool? conHuella}) => LinkedDevice(
    id: id,
    nombre: nombre,
    plataforma: plataforma,
    vinculadoEl: vinculadoEl,
    ultimoUso: ultimoUso,
    esEste: esEste,
    conHuella: conHuella ?? this.conHuella,
  );
}
