import '../auth/bloc/auth_bloc.dart';
import 'app_routes.dart';

/// Pantallas de gate (no requieren sesión). Función pura, testeable.
const _gateLocations = {
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.registro,
  AppRoutes.quickAccess,
  AppRoutes.blocked,
  // Recuperación y verificación de dispositivo: ocurren ANTES de tener sesión.
  AppRoutes.recuperar,
  AppRoutes.recuperarCodigo,
  AppRoutes.recuperarPin,
  AppRoutes.recuperarListo,
  AppRoutes.recuperarCancelado,
  AppRoutes.ingresarDispositivo,
  AppRoutes.ingresarCancelado,
};

/// Gate del router según auth.
/// - bloqueado por inactividad → /acceso-rapido (salvo acceso rápido y bloqueo)
/// - no autenticado fuera de gate → /onboarding
/// - autenticado en pantalla de gate → /home
/// - resto → sin redirect
String? appRedirect(
  AuthState authState,
  String location, {
  bool sessionLocked = false,
}) {
  // El bloqueo por inactividad manda sobre el estado de auth: la sesión sigue
  // viva, pero la interfaz no se muestra hasta que el PIN o la huella la
  // liberen. Se dejan pasar las pantallas de gate (acceso rápido, bloqueo,
  // splash/onboarding/login) para no entrar en un ciclo si el acceso rápido
  // deriva a /bloqueado o si el teléfono no tiene usuario recordado.
  if (sessionLocked) {
    return _gateLocations.contains(location) ? null : AppRoutes.quickAccess;
  }

  switch (authState) {
    case AuthUnauthenticated():
      return _gateLocations.contains(location) ? null : AppRoutes.onboarding;
    case AuthAuthenticated():
      return _gateLocations.contains(location) ? AppRoutes.home : null;
  }
}
