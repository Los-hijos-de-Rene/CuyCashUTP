import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_toggles.dart';
import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/account_module.dart';
import '../../core/injection/modules/beneficiary_module.dart';
import '../../core/injection/modules/device_module.dart';
import '../../core/injection/modules/kyc_module.dart';
import '../../core/injection/modules/otp_module.dart';
import '../../core/injection/modules/profile_module.dart';
import '../../core/injection/modules/register_module.dart';
import '../../core/injection/modules/security_module.dart';
import '../../core/injection/modules/transfer_module.dart';
import '../../feature/auth/application/auth_actions.dart';
import '../../feature/auth/domain/auth_session.dart';
import '../../feature/device/application/device_actions.dart';
import '../../feature/account/domain/account.dart';
import '../../feature/kyc/application/kyc_actions.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../home/bloc/account_bloc.dart';
import '../home/home_screen.dart';
import '../home/refresh_after_send.dart';
import '../movement/bloc/movement_detail_bloc.dart';
import '../movement/movement_detail_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../otp/bloc/otp_bloc.dart';
import '../otp/flujo_cancelado_screen.dart';
import '../otp/otp_config.dart';
import '../otp/otp_verification_screen.dart';
import '../recover/bloc/reset_pin_bloc.dart';
import '../recover/pin_actualizado_screen.dart';
import '../recover/recovery_handoff.dart';
import '../recover/recuperar_acceso_screen.dart';
import '../recover/restablecer_pin_screen.dart';
import '../profile/alias/bloc/edit_alias_bloc.dart';
import '../profile/biometric/bloc/biometric_settings_bloc.dart';
import '../profile/biometric/biometric_settings_screen.dart';
import '../profile/change_pin/bloc/change_pin_bloc.dart';
import '../profile/change_pin/change_pin_screen.dart';
import '../profile/alias/edit_alias_screen.dart';
import '../profile/devices/bloc/linked_devices_bloc.dart';
import '../profile/devices/linked_devices_screen.dart';
import '../profile/personal_data/bloc/personal_data_bloc.dart';
import '../profile/personal_data/personal_data_screen.dart';
import '../profile/profile_screen.dart';
import '../lockout/access_blocked_screen.dart';
import '../lockout/blocked_args.dart';
import '../quick_access/bloc/quick_access_bloc.dart';
import '../quick_access/quick_access_screen.dart';
import '../register/bloc/register_bloc.dart';
import '../register/register_flow_screen.dart';
import '../shell/app_shell.dart';
import '../splash/splash_screen.dart';
import '../transfer/amount_screen.dart';
import '../transfer/bloc/transfer_bloc.dart';
import '../transfer/confirm_screen.dart';
import '../account_open/bloc/open_account_bloc.dart';
import '../account_open/open_account_screen.dart';
import '../topup/bloc/topup_bloc.dart';
import '../topup/topup_screen.dart';
import '../transfer/receipt_screen.dart';
import '../transfer/recipient_screen.dart';
import '../transfer/widgets/frequent_section.dart';
import '../auth/login_screen.dart';
import 'app_redirect.dart';
import 'close_on_lockout.dart';
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
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
              onVerified: (ticket) => context.go(
                AppRoutes.recuperarPin,
                extra: RecoveryHandoff(email: email, otpTicket: ticket),
              ),
              onChangeEmail: () => context.go(AppRoutes.recuperar),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recuperarPin,
        builder: (context, state) {
          // Sin ticket no se entra: el paso solo existe tras verificar el
          // código.
          if (state.extra case final RecoveryHandoff handoff) {
            return BlocProvider(
              create: (_) => ResetPinBloc(
                actions: AuthActions(deps.authRepository),
                identifier: handoff.email,
                otpTicket: handoff.otpTicket,
              ),
              child: const RestablecerPinScreen(),
            );
          }
          return const RecuperarAccesoScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.recuperarListo,
        builder: (context, state) => const PinActualizadoScreen(),
      ),
      GoRoute(
        path: AppRoutes.recuperarCancelado,
        builder: (context, state) => const FlujoCanceladoScreen(
          variante: FlujoCanceladoVariante.recuperacion,
        ),
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
              onVerified: (ticket) =>
                  authBloc.add(AuthEvent.deviceVerified(session, ticket)),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ingresarCancelado,
        builder: (context, state) => const FlujoCanceladoScreen(
          variante: FlujoCanceladoVariante.ingreso,
        ),
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
                    value: AuthActions(deps.authRepository),
                  ),
                  RepositoryProvider<DeviceActions>.value(value: device),
                ],
                child: BlocProvider(
                  create: (_) => QuickAccessBloc(
                    auth: AuthActions(deps.authRepository),
                    device: device,
                    biometric: SecurityModule.biometricSignIn(deps),
                    user: user,
                  )..add(const QuickAccessEvent.started()),
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
      // Las cuatro pantallas del envío comparten UN TransferBloc: la clave de
      // idempotencia, el monto y el destinatario viven mientras dure el flujo
      // y mueren al salir de él.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => TransferBloc(
            TransferModule.create(deps),
            pending: TransferModule.pending(deps),
            // Sin acciones de frecuentes, el monto no ofrece guardarlo.
            beneficiaries: FeatureToggles.frecuentesEnEnvio
                ? BeneficiaryModule.create(deps)
                : null,
            // Las claves pendientes son de ESTE usuario y de nadie más.
            userId: switch (authBloc.state) {
              AuthAuthenticated(:final session) => session.userId,
              AuthUnauthenticated() => '',
            },
          ),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.enviar,
            builder: (context, state) {
              // La cuenta viaja como `extra` desde el inicio. Sin ella (deep
              // link) no hay desde dónde enviar.
              if (state.extra case final Account cuenta) {
                return RecipientScreen(
                  cuenta: cuenta,
                  // Sin builder, la pantalla no pinta la fila de frecuentes.
                  frecuentes: FeatureToggles.frecuentesEnEnvio
                      ? (onSelected) => FrequentSection(
                          actions: BeneficiaryModule.create(deps),
                          onSelected: onSelected,
                        )
                      : null,
                );
              }
              return const SplashScreen();
            },
            redirect: (context, state) =>
                state.extra is Account ? null : AppRoutes.home,
          ),
          GoRoute(
            path: AppRoutes.enviarMonto,
            builder: (context, state) => const AmountScreen(),
          ),
          GoRoute(
            path: AppRoutes.enviarConfirmar,
            builder: (context, state) => const ConfirmScreen(),
          ),
          GoRoute(
            path: AppRoutes.enviarConstancia,
            builder: (context, state) => const ReceiptScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.movimiento,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return BlocProvider(
            create: (_) =>
                MovementDetailBloc(AccountModule.create(deps))
                  ..add(MovementDetailEvent.opened(id)),
            child: MovementDetailScreen(transactionId: id),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.perfilDatos,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              PersonalDataBloc(ProfileModule.create(deps))
                ..add(const PersonalDataEvent.started()),
          child: const PersonalDataScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.perfilAlias,
        builder: (context, state) => BlocProvider(
          create: (_) => EditAliasBloc(
            profile: ProfileModule.create(deps),
            device: DeviceModule.create(deps),
            // El alias vigente llega del perfil; sin él se parte vacío.
            initial: state.extra as String? ?? '',
          ),
          child: const EditAliasScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.perfilDispositivos,
        builder: (context, state) => BlocProvider(
          create: (_) =>
              LinkedDevicesBloc(SecurityModule.create(deps))
                ..add(const LinkedDevicesEvent.started()),
          child: const LinkedDevicesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.perfilPin,
        builder: (context, state) => BlocProvider(
          create: (_) => ChangePinBloc(SecurityModule.create(deps)),
          child: ChangePinScreen(
            onLocked: (until) =>
                closeOnLockout(GoRouter.of(context), authBloc, until),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.perfilBiometria,
        builder: (context, state) => BlocProvider(
          create: (_) => BiometricSettingsBloc(
            enable: SecurityModule.enableBiometric(deps),
            disable: SecurityModule.disableBiometric(deps),
            device: DeviceModule.create(deps),
          )..add(const BiometricSettingsEvent.started()),
          child: BiometricSettingsScreen(
            onLocked: (until) =>
                closeOnLockout(GoRouter.of(context), authBloc, until),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.abrirCuenta,
        // Las cuentas actuales viajan como `extra` desde el inicio: sin ellas
        // (deep link) no se sabe si ya hay sueldo ni cuántas hay.
        redirect: (context, state) =>
            state.extra is List<Account> ? null : AppRoutes.home,
        builder: (context, state) => BlocProvider(
          create: (_) => OpenAccountBloc(
            AccountModule.create(deps),
            pending: TransferModule.pending(deps),
            userId: switch (authBloc.state) {
              AuthAuthenticated(:final session) => session.userId,
              AuthUnauthenticated() => '',
            },
            cuentas: state.extra as List<Account>,
          )..add(const OpenAccountEvent.opened()),
          child: const OpenAccountScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recargar,
        // La cuenta viaja como `extra` desde el inicio; sin ella (deep link)
        // no hay dónde recargar.
        redirect: (context, state) =>
            state.extra is Account ? null : AppRoutes.home,
        builder: (context, state) {
          final cuenta = state.extra as Account;
          return BlocProvider(
            // La clave de idempotencia nace al abrir (TopUpOpened).
            create: (_) => TopUpBloc(
              TransferModule.create(deps),
              pending: TransferModule.pending(deps),
              userId: switch (authBloc.state) {
                AuthAuthenticated(:final session) => session.userId,
                AuthUnauthenticated() => '',
              },
            )..add(TopUpEvent.opened(cuentaId: cuenta.id)),
            child: TopUpScreen(cuenta: cuenta),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      AccountBloc(AccountModule.create(deps))
                        ..add(const AccountEvent.started()),
                  child: const RefreshAfterSend(child: HomeScreen()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.perfil,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
