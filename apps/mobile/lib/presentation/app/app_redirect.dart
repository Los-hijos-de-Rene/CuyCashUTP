import '../auth/bloc/auth_bloc.dart';
import 'app_routes.dart';

/// Pantallas de gate (no requieren sesión). Función pura, testeable.
const _gateLocations = {
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.registro,
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
