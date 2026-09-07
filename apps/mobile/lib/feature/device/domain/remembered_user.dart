/// Usuario recordado en este dispositivo (para el acceso rápido). Dato local
/// no secreto salvo el DNI; se guarda cifrado vía secure storage.
class RememberedUser {
  const RememberedUser({
    required this.dni,
    required this.fullName,
    required this.alias,
  });

  final String dni;
  final String fullName;
  final String alias;

  String get firstName {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? alias : trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return alias.replaceAll('@', '').toUpperCase().padRight(1).substring(0, 1);
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() =>
      {'dni': dni, 'fullName': fullName, 'alias': alias};

  factory RememberedUser.fromJson(Map<String, dynamic> json) => RememberedUser(
        dni: json['dni'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        alias: json['alias'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is RememberedUser &&
      other.dni == dni &&
      other.fullName == fullName &&
      other.alias == alias;

  @override
  int get hashCode => Object.hash(dni, fullName, alias);
}
