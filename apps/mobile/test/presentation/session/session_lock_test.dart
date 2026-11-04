// HU03 CA4 · El bloqueo por inactividad manda sobre el gate de auth.
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/presentation/app/app_redirect.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/session/session_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const authed = AuthState.authenticated(
    AuthSession(userId: 'u', identifier: '12345678'),
  );

  test('bloqueado manda cualquier ruta al acceso rápido', () {
    expect(
      appRedirect(authed, AppRoutes.home, sessionLocked: true),
      AppRoutes.quickAccess,
    );
    expect(
      appRedirect(authed, AppRoutes.perfil, sessionLocked: true),
      AppRoutes.quickAccess,
    );
  });

  test('bloqueado deja pasar las pantallas de gate (sin ciclo)', () {
    expect(
      appRedirect(authed, AppRoutes.quickAccess, sessionLocked: true),
      isNull,
    );
    expect(
      appRedirect(authed, AppRoutes.blocked, sessionLocked: true),
      isNull,
    );
    expect(
      appRedirect(authed, AppRoutes.login, sessionLocked: true),
      isNull,
    );
    expect(
      appRedirect(authed, AppRoutes.onboarding, sessionLocked: true),
      isNull,
    );
  });

  testWidgets('el router navega al acceso rápido al bloquear y vuelve al '
      'liberar', (t) async {
    final lock = SessionLock();
    addTearDown(lock.dispose);
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: lock,
      redirect: (context, state) => appRedirect(
        authed,
        state.matchedLocation,
        sessionLocked: lock.isLocked,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Text('HOME'),
        ),
        GoRoute(
          path: AppRoutes.quickAccess,
          builder: (_, _) => const Text('ACCESO RAPIDO'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);

    lock.lock();
    await t.pumpAndSettle();
    expect(find.text('ACCESO RAPIDO'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);

    lock.unlock();
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  test('lock y unlock avisan una sola vez', () {
    final lock = SessionLock();
    addTearDown(lock.dispose);
    var avisos = 0;
    lock.addListener(() => avisos++);

    lock.lock();
    lock.lock();
    expect(lock.isLocked, isTrue);
    expect(avisos, 1);

    lock.unlock();
    lock.unlock();
    expect(lock.isLocked, isFalse);
    expect(avisos, 2);
  });
}
