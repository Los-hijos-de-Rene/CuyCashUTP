import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/device_module.dart';
import '../../core/injection/modules/kyc_module.dart';
import '../../core/injection/modules/otp_module.dart';
import '../../core/injection/modules/register_module.dart';
import '../../feature/auth/application/auth_actions.dart';
import '../../feature/auth/domain/auth_session.dart';
import '../../feature/device/application/device_actions.dart';
import '../../feature/kyc/application/kyc_actions.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../otp/bloc/otp_bloc.dart';
import '../otp/flujo_cancelado_screen.dart';
import '../otp/otp_config.dart';
import '../otp/otp_verification_screen.dart';
import '../recover/bloc/reset_pin_bloc.dart';
import '../recover/pin_actualizado_screen.dart';
import '../recover/recuperar_acceso_screen.dart';
import '../recover/restablecer_pin_screen.dart';
import '../profile/profile_screen.dart';
import '../lockout/access_blocked_screen.dart';
import '../lockout/blocked_args.dart';
import '../quick_access/bloc/quick_access_bloc.dart';
import '../quick_access/quick_access_screen.dart';
import '../register/bloc/register_bloc.dart';
import '../register/register_flow_screen.dart';
import '../shell/app_shell.dart';
import '../splash/splash_screen.dart';
import '../auth/login_screen.dart';
import 'app_redirect.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

/// Router: gate de auth + shell de 2 tabs (Home, Perfil).
GoRouter createAppRouter(AppDependencies deps, AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      if (state.matchedLocation == AppRoutes.splash) return null;
      return appRedirect(authBloc.state, state.matchedLocation);
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
        path: AppRoutes.login,
        // El DNI viaja como `extra` al retomar tras un bloqueo vencido.
        builder: (context, state) =>
            LoginScreen(initialDni: state.extra as String?),
      ),
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => RepositoryProvider<KycActions>.value(
          // El paso 3 arma su propio bloc de liveness con estas acciones.
          value: KycModule.create(deps),
          child: BlocProvider<RegisterBloc>(
            create: (_) => RegisterModule.create(deps),
            child: const RegisterFlowScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.recuperar,
        builder: (context, state) => const RecuperarAccesoScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarCodigo,
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null) return const RecuperarAccesoScreen();
          final l10n = AppLocalizations.of(context);
          return BlocProvider(
            create: (_) => OtpBloc(
              actions: OtpModule.create(deps),
              identifier: email,
              clock: DateTime.now,
            )..add(const OtpEvent.started()),
            child: OtpVerificationScreen(
              config: OtpConfig.recuperacion(l10n, email),
              onVerified: (_) =>
                  context.go(AppRoutes.recuperarPin, extra: email),
              onChangeEmail: () => context.go(AppRoutes.recuperar),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recuperarPin,
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null) return const RecuperarAccesoScreen();
          return BlocProvider(
            create: (_) => ResetPinBloc(
              actions: AuthActions(deps.authRepository),
              identifier: email,
            ),
            child: const RestablecerPinScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recuperarListo,
        builder: (context, state) => const PinActualizadoScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarCancelado,
        builder: (context, state) => const FlujoCanceladoScreen(
            variante: FlujoCanceladoVariante.recuperacion),
      ),
      GoRoute(
        path: AppRoutes.ingresarDispositivo,
        builder: (context, state) {
          // La sesión llega validada pero SIN activar: solo se abre si el OTP
          // confirma que el teléfono es del titular.
          final session = state.extra as AuthSession?;
          if (session == null) return const LoginScreen();
          final l10n = AppLocalizations.of(context);
          return BlocProvider(
            create: (_) => OtpBloc(
              actions: OtpModule.create(deps),
              identifier: session.identifier,
              clock: DateTime.now,
            )..add(const OtpEvent.started()),
            child: OtpVerificationScreen(
              config: OtpConfig.dispositivo(l10n, session.identifier),
              onVerified: (_) =>
                  authBloc.add(AuthEvent.deviceVerified(session)),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ingresarCancelado,
        builder: (context, state) => const FlujoCanceladoScreen(
            variante: FlujoCanceladoVariante.ingreso),
      ),
      GoRoute(
        path: AppRoutes.quickAccess,
        builder: (context, state) {
          final device = DeviceModule.create(deps);
          return FutureBuilder(
            future: device.readUser(),
            builder: (context, snap) {
              final user = snap.data;
              if (user == null) return const SplashScreen();
              return MultiRepositoryProvider(
                providers: [
                  RepositoryProvider<AuthActions>.value(
                      value: AuthActions(deps.authRepository)),
                  RepositoryProvider<DeviceActions>.value(value: device),
                ],
                child: BlocProvider(
                  create: (_) => QuickAccessBloc(
                    auth: AuthActions(deps.authRepository),
                    device: device,
                    user: user,
                  ),
                  child: const QuickAccessScreen(),
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.blocked,
        builder: (context, state) {
          // El origen y el vencimiento llegan de quien bloqueó. Sin ellos
          // (recarga o deep link) se cae al bloqueo local del acceso rápido,
          // el único que este teléfono sabe reconstruir por sí solo.
          if (state.extra case final BlockedArgs args) {
            return AccessBlockedScreen(
              lockedUntil: args.lockedUntil,
              origin: args.origin,
              onExpired: (origin) =>
                  context.go(origin.entryRoute, extra: args.resumeDni),
              onRecoverPin: () => context.go(AppRoutes.recuperar),
            );
          }
          final device = DeviceModule.create(deps);
          return FutureBuilder(
            future: device.readLockout(),
            builder: (context, snap) {
              final until = snap.data?.lockedUntil;
              if (until == null) return const SplashScreen();
              return AccessBlockedScreen(
                lockedUntil: until,
                origin: BlockedOrigin.quickAccess,
                onExpired: (origin) => context.go(origin.entryRoute),
                onRecoverPin: () => context.go(AppRoutes.recuperar),
              );
            },
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.perfil,
                builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
