import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Arma `<plataforma>|<modelo>` saneando el modelo, que viene crudo del SO:
/// un carácter no ASCII o de control haría que `dart:io` lance al enviar la
/// cabecera, y eso ocurriría en TODAS las peticiones (vive en `BaseOptions`).
/// Se quita todo lo que no sea ASCII imprimible y la `|` (separador), se
/// colapsan los espacios y se recorta. `null` si el modelo queda vacío.
String? formatDeviceName(String plataforma, String modelo) {
  final limpio = modelo
      .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
      .replaceAll('|', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (limpio.isEmpty) return null;
  return '$plataforma|$limpio';
}

/// Cómo se presenta este teléfono en "Dispositivos vinculados":
/// `android|Samsung SM-A546E` / `ios|iPhone14,5`. El formato
/// `<plataforma>|<modelo>` (ASCII, sin espacios alrededor de `|`) es el que
/// el backend sabe separar; un valor no ASCII sería inválido en una cabecera
/// HTTP.
///
/// `null` si no se puede leer: es un dato decorativo y su ausencia no debe
/// impedir arrancar la app.
Future<String?> describeThisDevice() async {
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return formatDeviceName('android', '${a.manufacturer} ${a.model}');
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return formatDeviceName('ios', i.utsname.machine);
    }
    return null;
  } catch (_) {
    return null;
  }
}
