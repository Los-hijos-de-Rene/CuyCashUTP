import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/app/router.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// El último paso del alta: "Ir a mi cuenta" en la pantalla de éxito.
///
/// No tenía test. Si no lleva al inicio, el usuario recién registrado se queda
/// mirando una pantalla muerta justo después de confiarle sus datos a la app.
void main() {
  late AuthBloc auth;
  late MemoryAuthRepository repo;

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // El bloc se crea DENTRO del cuerpo del test a propósito: en `setUp` su
    // suscripción al stream quedaría en otra zona y `pumpAndSettle` no la
    // drenaría, de modo que el test fallaría por el arnés y no por la app.
    repo = MemoryAuthRepository();
    auth = AuthBloc(
      AuthActions(repo),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    addTearDown(auth.close);
    final deps = await buildMockDependencies();
    final router = createAppRouter(deps, auth);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: DeviceActions(MemoryDeviceStore()),
        child: BlocProvider.value(
          value: auth,
          child: MaterialApp.router(
            routerConfig: router,
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    router.go(AppRoutes.registro);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('activar la sesión creada lleva del registro al inicio', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.registro,
    );

    // Es exactamente lo que hace "Ir a mi cuenta": activar la sesión creada.
    await repo.activate(
      const AuthSession(
        userId: 'u-1',
        identifier: '71234567',
        alias: '@jair',
        fullName: 'Jair Conislla',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.home,
      reason: 'activar la sesión debe sacar al usuario de la pantalla de gate',
    );
  });
}
