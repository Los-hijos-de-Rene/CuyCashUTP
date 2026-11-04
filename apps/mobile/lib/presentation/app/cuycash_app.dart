import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/session_config.dart';
import '../../core/injection/app_dependencies.dart';
import '../../feature/dev_tools/application/dev_tools_actions.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../dev_tools/dev_tools_overlay.dart';
import '../session/inactivity_watcher.dart';
import '../session/session_lock.dart';
import 'app_routes.dart';
import 'router.dart';

/// MaterialApp.router con theme + l10n. Crea el router una sola vez con el
/// AuthBloc del árbol.
class CuyCashApp extends StatefulWidget {
  const CuyCashApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<CuyCashApp> createState() => _CuyCashAppState();
}

class _CuyCashAppState extends State<CuyCashApp> {
  late final SessionLock _sessionLock = context.read<SessionLock>();
  late final router = createAppRouter(
    widget.dependencies,
    context.read<AuthBloc>(),
    sessionLock: _sessionLock,
  );

  /// Tras vaciar la base local desde el menú de desarrollo: lo que el teléfono
  /// guarda de la cuenta ya no existe en el servidor. Sin esto, la app abría
  /// el acceso rápido de un DNI borrado y el servidor respondía 401.
  Future<void> _afterDevReset() async {
    final store = widget.dependencies.deviceStore;
    await store.clearUser();
    await store.clearBiometricCredential();
    await store.clearLockout();
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthEvent.signedOut());
    router.go(AppRoutes.splash);
  }

  /// Se agotó el tiempo sin uso: se tapa la app con el acceso rápido. La
  /// sesión no se cierra; el PIN o la huella la liberan.
  void _lockSession() {
    if (_sessionLock.isLocked) return;
    _sessionLock.lock();
    router.go(AppRoutes.quickAccess);
  }

  @override
  Widget build(BuildContext context) {
    final devTools = widget.dependencies.devToolsRepository;
    final app = MaterialApp.router(
      title: 'CuyCash',
      debugShowCheckedModeBanner: false,
      theme: CuyCashTheme.light(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Solo en `local` con DEV_TOOLS_KEY: en el resto `devTools` es null y
      // la app no lleva ni el botón.
      builder: devTools == null
          ? null
          : (context, child) => DevToolsOverlay(
                actions: DevToolsActions(devTools),
                navigatorKey: router.routerDelegate.navigatorKey,
                onReset: _afterDevReset,
                child: child ?? const SizedBox.shrink(),
              ),
    );

    // El vigilante solo corre con sesión abierta y sin bloqueo: en login,
    // acceso rápido o registro no debe disparar nada.
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state is AuthAuthenticated,
      builder: (context, authenticated) => ListenableBuilder(
        listenable: _sessionLock,
        builder: (context, _) => InactivityWatcher(
          enabled: authenticated && !_sessionLock.isLocked,
          timeout: SessionConfig.inactivityTimeout,
          onTimeout: _lockSession,
          child: app,
        ),
      ),
    );
  }
}
