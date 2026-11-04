// APF3 · Usabilidad del inicio con carrusel de cuentas (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:cuycash/presentation/home/home_screen.dart';
import 'package:cuycash/presentation/home/widgets/balance_card.dart';
import 'package:cuycash/presentation/home/widgets/home_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '_harness.dart';

const _ahorro = Account(
  id: 'a',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

void main() {
  late AuthBloc auth;
  late DeviceActions device;

  setUp(() async {
    auth = AuthBloc(
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

  tearDown(() => auth.close());

  Future<void> pump(
    WidgetTester tester, {
    required AccountBloc account,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: device,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider.value(value: account),
          ],
          child: appDePrueba(
            textScale: textScale,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  AccountBloc enEstado(AccountState estado) {
    final bloc = AccountBloc(AccountActions(MemoryAccountRepository()));
    // ignore: invalid_use_of_visible_for_testing_member
    bloc.emit(estado);
    addTearDown(bloc.close);
    return bloc;
  }

  group('UX-INICIO · accesibilidad', () {
    testWidgets('UX-INICIO-01 áreas táctiles y etiquetas accesibles', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(
        t,
        account: enEstado(
          const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
        ),
      );
      await verificarAccesibilidad(t);
    });
  });

  group('UX-INICIO · adaptabilidad', () {
    testWidgets('UX-INICIO-02 con texto al 200 % no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(
        t,
        textScale: 2,
        account: enEstado(
          const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
        ),
      );
      verificarSinDesbordes(t);
      expect(find.text('S/ 1,250.40'), findsOneWidget);
    });

    testWidgets('UX-INICIO-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(
        t,
        account: enEstado(
          const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
        ),
      );
      verificarSinDesbordes(t);
    });
  });

  group('UX-INICIO · retroalimentación', () {
    testWidgets('UX-INICIO-04 mientras carga se ve una silueta, no un vacío', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(
        t,
        account: enEstado(const AccountState(status: AccountStatus.loading)),
      );

      expect(find.byType(HomeSkeleton), findsOneWidget);
      expect(find.byType(BalanceCard), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('UX-INICIO · recuperación', () {
    testWidgets('UX-INICIO-05 el error de red dice qué hacer, sin códigos', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(
        t,
        account: enEstado(
          const AccountState(
            status: AccountStatus.error,
            failure: AccountFailure.network(),
          ),
        ),
      );

      const mensaje =
          'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.';
      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      verificarSinCodigosTecnicos(mensaje);
    });
  });
}
