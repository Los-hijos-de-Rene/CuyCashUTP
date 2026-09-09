import 'package:flutter/foundation.dart';

/// Host del backend cuando no se configuró uno.
///
/// Cada entorno ve al PC anfitrión con una dirección distinta, y equivocarse
/// da un "connection refused" que no dice nada. Son quince líneas: no vale la
/// pena una dependencia para esto, y además la que hay en pub.dev no resuelve
/// el caso que más importa aquí —el teléfono físico—, porque la IP de la red
/// local no se puede adivinar.
abstract final class DevHost {
  /// Emulador de Android: `10.0.2.2` es el host visto desde la VM.
  /// Simulador de iOS y escritorio comparten la máquina, así que es local.
  static String get value {
    if (kIsWeb) return 'localhost';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => '10.0.2.2',
      _ => '127.0.0.1',
    };
  }

  /// URL por defecto para [port]. En un teléfono FÍSICO esto no sirve: hay que
  /// pasar la IP del PC por `--dart-define-from-file`.
  static String urlFor(int port) => 'http://$value:$port';
}
