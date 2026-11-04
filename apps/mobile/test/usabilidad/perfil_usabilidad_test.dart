// APF3 · Usabilidad del perfil (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/profile/profile_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '_harness.dart';

void main() {
  late AuthBloc bloc;
  late DeviceActions device;

  setUp(() async {
    bloc = AuthBloc(
      AuthActions(
        MemoryAuthRepository(
          initial: const AuthSession(userId: 'u', identifier: '12345678'),
        ),
      ),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Jheampierre Ruiz Salas',
        alias: '@jheampierre',
      ),
    );
  });

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/perfil/datos',
          builder: (_, _) => const Scaffold(body: Text('DATOS')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: device,
        child: BlocProvider.value(
          value: bloc,
          child: appRouterDePrueba(router: router, textScale: textScale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UX-PERFIL · accesibilidad', () {
    testWidgets('UX-PERFIL-01 áreas táctiles y etiquetas accesibles', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-PERFIL · adaptabilidad', () {
    testWidgets('UX-PERFIL-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
      expect(find.text('12345678'), findsOneWidget);
    });

    testWidgets('UX-PERFIL-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-PERFIL · protección contra errores', () {
    testWidgets('UX-PERFIL-04 cerrar sesión pide confirmación antes de actuar', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      await t.scrollUntilVisible(find.byType(SecondaryButton), 300);
      await t.pumpAndSettle();
      await t.tap(find.byType(SecondaryButton));
      await t.pumpAndSettle();

      // La acción destructiva no se ejecuta con un solo toque.
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('UX-PERFIL-05 el perfil muestra el alias y permite editarlo', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t);

      expect(find.textContaining('@jheampierre'), findsWidgets);
      expect(find.text('Editar mi alias'), findsOneWidget);
    });
  });
}
