/// Rutas de la app.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registro = '/registro';
  static const home = '/home';
  static const perfil = '/perfil';
  // Subpantallas del perfil. Se abren con `push` sobre la pestaña y fuera del
  // shell, para que tapen la barra inferior como el detalle de movimiento.
  static const perfilDatos = '/perfil/datos';
  static const perfilAlias = '/perfil/alias';
  static const perfilPin = '/perfil/pin';
  static const perfilBiometria = '/perfil/biometria';
  static const perfilDispositivos = '/perfil/dispositivos';
  static const quickAccess = '/acceso-rapido';
  static const blocked = '/bloqueado';

  // Envío de dinero (pila de cuatro pantallas sobre el inicio).
  static const enviar = '/enviar';
  static const enviarMonto = '/enviar/monto';
  static const enviarConfirmar = '/enviar/confirmar';
  static const enviarConstancia = '/enviar/constancia';

  // Detalle de un movimiento del historial.
  static const movimiento = '/movimientos/:id';
  static String movimientoDe(String transactionId) =>
      '/movimientos/${Uri.encodeComponent(transactionId)}';

  // Recarga de saldo (una sola pantalla: monto + PIN).
  static const recargar = '/recargar';

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
