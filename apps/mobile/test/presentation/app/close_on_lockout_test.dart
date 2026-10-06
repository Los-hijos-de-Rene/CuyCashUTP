import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/app/close_on_lockout.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/lockout/blocked_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  BlockedArgs? recibidos;

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    recibidos = null;
    final router = GoRouter(
      initialLocation: AppRoutes.perfilPin,
      routes: [
        GoRoute(
          path: AppRoutes.perfilPin,
          builder: (_, _) => const Text('pin'),
        ),
        GoRoute(
          path: AppRoutes.blocked,
          builder: (_, state) {
            recibidos = state.extra as BlockedArgs?;
            return const Text('bloqueado');
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    return router;
  }

  AuthBloc crearAuth(AuthSession? initial) {
    final bloc = AuthBloc(
      AuthActions(MemoryAuthRepository(initial: initial)),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  final hasta = DateTime(2030);

  testWidgets('autenticado: cierra la sesión y va a /bloqueado con el DNI', (
    tester,
  ) async {
    final auth = crearAuth(
      const AuthSession(userId: 'u', identifier: '70123456'),
    );
    final router = await pumpRouter(tester);
    expect(auth.state, isA<AuthAuthenticated>());

    final fin = closeOnLockout(router, auth, hasta);
    await tester.pumpAndSettle();
    await fin.timeout(const Duration(seconds: 2));

    expect(auth.state, isA<AuthUnauthenticated>());
    expect(find.text('bloqueado'), findsOneWidget);
    expect(recibidos?.lockedUntil, hasta);
    expect(recibidos?.origin, BlockedOrigin.login);
    expect(recibidos?.resumeDni, '70123456');
  });

  testWidgets('ya sin sesión: no se cuelga y navega igual', (tester) async {
    final auth = crearAuth(null);
    final router = await pumpRouter(tester);
    expect(auth.state, isA<AuthUnauthenticated>());

    final fin = closeOnLockout(router, auth, hasta);
    await tester.pumpAndSettle();
    await fin.timeout(const Duration(seconds: 2));

    expect(find.text('bloqueado'), findsOneWidget);
    expect(recibidos?.resumeDni, isNull);
  });
}
