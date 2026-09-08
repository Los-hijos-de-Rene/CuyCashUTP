import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Marca la ventana como segura mientras hay un PIN en pantalla.
///
/// En Android activa `FLAG_SECURE`: bloquea capturas y deja la app en negro en
/// la vista de apps recientes, para que el PIN no quede en una miniatura del
/// sistema. Se activa y desactiva por pantalla (no global) porque la app tiene
/// vistas que el usuario sí querrá capturar o compartir, como su alias.
///
/// En iOS no existe un equivalente directo: la protección de la miniatura se
/// resuelve tapando la ventana al pasar a segundo plano, y queda pendiente.
abstract final class SecureScreen {
  static const _channel = MethodChannel('cuycash/secure_screen');

  static Future<void> enable() => _set(true);

  static Future<void> disable() => _set(false);

  static Future<void> _set(bool secure) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', secure);
    } on PlatformException catch (_) {
      // Sin canal nativo (tests, escritorio) la pantalla sigue funcionando:
      // la protección es una capa extra, no un requisito para operar.
    } on MissingPluginException catch (_) {}
  }
}
