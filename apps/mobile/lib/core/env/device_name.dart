import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

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
      return 'android|${a.manufacturer} ${a.model}'.trim();
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return 'ios|${i.utsname.machine}';
    }
    return null;
  } catch (_) {
    return null;
  }
}
