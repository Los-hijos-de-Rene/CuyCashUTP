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
