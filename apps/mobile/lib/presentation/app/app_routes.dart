/// Rutas de la app.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registro = '/registro';
  static const home = '/home';
  static const perfil = '/perfil';
  static const quickAccess = '/acceso-rapido';
  static const blocked = '/bloqueado';

  // Envío de dinero (pila de cuatro pantallas sobre el inicio).
  static const enviar = '/enviar';
  static const enviarMonto = '/enviar/monto';
  static const enviarConfirmar = '/enviar/confirmar';
  static const enviarConstancia = '/enviar/constancia';

  // Recuperación de PIN.
  static const recuperar = '/recuperar';
  static const recuperarCodigo = '/recuperar/codigo';
  static const recuperarPin = '/recuperar/pin';
  static const recuperarListo = '/recuperar/listo';
  static const recuperarCancelado = '/recuperar/cancelado';

  // Verificación de un teléfono nuevo al ingresar.
  static const ingresarDispositivo = '/ingresar/dispositivo';
  static const ingresarCancelado = '/ingresar/cancelado';
}
