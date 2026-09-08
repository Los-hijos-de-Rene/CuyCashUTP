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
/// - no autenticado fuera de gate → /onboarding
/// - autenticado en pantalla de gate → /home
/// - resto → sin redirect
String? appRedirect(AuthState authState, String location) {
  switch (authState) {
    case AuthUnauthenticated():
      return _gateLocations.contains(location) ? null : AppRoutes.onboarding;
    case AuthAuthenticated():
      return _gateLocations.contains(location) ? AppRoutes.home : null;
  }
}
