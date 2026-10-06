import 'package:go_router/go_router.dart';

import '../auth/bloc/auth_bloc.dart';
import '../lockout/blocked_args.dart';
import 'app_routes.dart';

/// El servidor ya cerró la sesión al bloquear. Un autenticado en
/// `/bloqueado` sería devuelto al inicio por `appRedirect`, así que primero se
/// cierra la sesión local y DESPUÉS se navega.
///
/// Recibe el [router] ya resuelto: la pantalla que llamó puede desmontarse en
/// cuanto la sesión se cierre (el gate la manda a `/onboarding`).
Future<void> closeOnLockout(
  GoRouter router,
  AuthBloc authBloc,
  DateTime until,
) async {
  final dni = switch (authBloc.state) {
    AuthAuthenticated(:final session) => session.identifier,
    AuthUnauthenticated() => null,
  };
  // Si ya no hay sesión, esperar a `AuthUnauthenticated` no terminaría nunca.
  if (authBloc.state is! AuthUnauthenticated) {
    authBloc.add(const AuthEvent.signedOut());
    await authBloc.stream.firstWhere((s) => s is AuthUnauthenticated);
  }
  router.go(
    AppRoutes.blocked,
    extra: BlockedArgs(
      origin: BlockedOrigin.login,
      lockedUntil: until,
      resumeDni: dni,
    ),
  );
}
