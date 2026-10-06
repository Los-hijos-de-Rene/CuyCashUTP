import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
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

/// Cambiar el PIN por la tabla de rutas REAL con el flavor `mock`: el estado
/// de seguridad se comparte entre el perfil y el login.
void main() {
  testWidgets('cambiar el PIN desde /perfil/pin cambia el PIN del login', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final deps = await buildMockDependencies();
    final repo = deps.authRepository as MemoryAuthRepository;
    // Sesión abierta ANTES de crear el bloc, que parte de `currentSession`.
    await repo.signIn(identifier: '70123456', pin: '000000');
    final auth = AuthBloc(
      AuthActions(repo),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    addTearDown(auth.close);
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
    router.go(AppRoutes.perfilPin);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu PIN actual'), findsOneWidget);

    Future<void> teclear(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await teclear('000000');
    await teclear('502718');
    await teclear('502718');

    expect(find.text('Tu PIN cambió'), findsOneWidget);
    expect(repo.validPin, '502718');
  });
}
