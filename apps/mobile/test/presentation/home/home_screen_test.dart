import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:cuycash/presentation/home/home_action.dart';
import 'package:cuycash/presentation/home/home_screen.dart';
import 'package:cuycash/presentation/home/widgets/movements_card.dart';
import 'package:cuycash/presentation/home/widgets/quick_actions_row.dart';
import 'package:cuycash/presentation/home/widgets/balance_card.dart';
import 'package:cuycash/presentation/home/widgets/home_skeleton.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  // Igual que en el perfil: el bloc se crea fuera de testWidgets para que su
  // suscripción al broadcast del repo no quede pendiente dentro de FakeAsync.
  late AuthBloc bloc;
  late AccountBloc account;
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
    account = AccountBloc(AccountActions(MemoryAccountRepository()))
      ..add(const AccountEvent.started());
    // La carga corre en el reloj real: se espera aquí, fuera de FakeAsync.
    await account.stream.firstWhere((s) => s.status == AccountStatus.ready);
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Jheampierre Ruiz Salas',
        alias: '@jheampierre',
      ),
    );
  });

  tearDown(() async {
    await bloc.close();
    await account.close();
  });

  Widget wrap() => RepositoryProvider<DeviceActions>.value(
    value: device,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: account),
      ],
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );

  testWidgets('saluda por el nombre y ya no muestra el sello de demostración', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Jheampierre'), findsOneWidget);
    expect(find.text('Datos de demostración'), findsNothing);
  });

  testWidgets('mientras carga muestra la silueta y no el saldo', (
    tester,
  ) async {
    final lento = AccountBloc(AccountActions(MemoryAccountRepository()));
    addTearDown(lento.close);
    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: device,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: lento),
          ],
          child: MaterialApp(
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Cargando tu cuenta'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(BalanceCard), findsNothing);
  });

  testWidgets(
    'con la cuenta lista muestra el saldo del servidor y los movimientos',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('S/ 1,250.40'), findsOneWidget);
      expect(find.text('Billetera ••••4521'), findsOneWidget);
      expect(find.text('B*** D*** A***'), findsOneWidget);
      // El signo lo pone la UI sobre el valor absoluto.
      expect(find.text('- S/ 45.00'), findsOneWidget);
      expect(find.text('+ S/ 1,200.00'), findsOneWidget);
      expect(find.textContaining('- -'), findsNothing);
    },
  );

  testWidgets('el ojo oculta y vuelve a mostrar el saldo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BalanceCard),
        matching: find.byIcon(Icons.visibility),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsNothing);
    expect(find.text('S/ ••••••'), findsOneWidget);
  });

  testWidgets('sin movimientos dice que aún no hay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: MovementsCard(movements: [])),
      ),
    );

    expect(find.text('Aún no tienes movimientos'), findsOneWidget);
  });

  testWidgets('QuickActionsRow solo muestra las listas y emite su HomeAction', (
    tester,
  ) async {
    final emitted = <HomeAction>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: QuickActionsRow(onAction: emitted.add)),
      ),
    );

    expect(find.text('Cobrar'), findsNothing);
    expect(find.text('Retirar'), findsNothing);
    for (final label in ['Enviar', 'Recargar']) {
      await tester.tap(find.text(label));
    }

    expect(emitted, [HomeAction.send, HomeAction.topUp]);
  });

  testWidgets('lo que aún no tiene pantalla se oculta en vez de avisar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Cobrar'), findsNothing);
    expect(find.text('Retirar'), findsNothing);
    expect(find.text('WasiBot'), findsNothing);
    expect(find.text('Ver todo'), findsNothing);
    expect(find.byTooltip('Notificaciones'), findsNothing);
    // Lo que sí existe sigue ahí.
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Recargar'), findsOneWidget);
    expect(find.text('Últimos movimientos'), findsOneWidget);
  });

  Widget wrapWith(AccountBloc b) => RepositoryProvider<DeviceActions>.value(
    value: device,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: bloc),
        BlocProvider.value(value: b),
      ],
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  );

  testWidgets('"Recargar" sin la cuenta cargada lo dice en vez de callar', (
    tester,
  ) async {
    final sinCuenta = _BlocConEstado(
      const AccountState(status: AccountStatus.ready),
    );
    addTearDown(sinCuenta.close);
    await tester.pumpWidget(wrapWith(sinCuenta));
    await tester.pump();

    await tester.tap(find.text('Recargar'));
    await tester.pump();

    expect(
      find.text('No pudimos cargar tu cuenta. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Disponible en una próxima versión.'), findsNothing);
  });

  testWidgets(
    '"Recargar" con la cuenta cargada navega, y al volver con true refresca',
    (tester) async {
      final conCuenta = _BlocConEstado(
        const AccountState(
          status: AccountStatus.ready,
          cuentas: [
            Account(
              id: 'a',
              numero: '19100000004521',
              tipo: AccountType.ahorro,
              moneda: Currency.pen,
              estado: 'activa',
              saldoDisponible: Money.soles(125040),
              saldoContable: Money.soles(125040),
            ),
          ],
        ),
      );
      addTearDown(conCuenta.close);
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/recargar',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  Text('RECARGA ${(state.extra as Account).id}'),
                  TextButton(
                    onPressed: () => context.pop(true),
                    child: const Text('LISTO'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepositoryProvider<DeviceActions>.value(
          value: device,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: bloc),
              BlocProvider<AccountBloc>.value(value: conCuenta),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              theme: CuyCashTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Recargar'));
      await tester.pumpAndSettle();
      expect(find.text('RECARGA a'), findsOneWidget);
      expect(
        conCuenta.recibidos,
        isNot(contains(const AccountEvent.refreshed())),
      );

      await tester.tap(find.text('LISTO'));
      await tester.pumpAndSettle();

      expect(conCuenta.recibidos, contains(const AccountEvent.refreshed()));
    },
  );

  testWidgets(
    'un error de red muestra el mensaje y Reintentar dispara started',
    (tester) async {
      final fallido = _BlocConEstado(
        const AccountState(
          status: AccountStatus.error,
          failure: AccountFailure.network(),
        ),
      );
      addTearDown(fallido.close);
      await tester.pumpWidget(wrapWith(fallido));
      await tester.pump();

      expect(
        find.text(
          'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.byType(BalanceCard), findsNothing);

      await tester.tap(find.text('Reintentar'));

      expect(fallido.recibidos, [const AccountEvent.started()]);
    },
  );

  testWidgets('un refresco fallido avisa sin quitar el saldo', (tester) async {
    final b = _BlocConEstado(
      AccountState(
        status: AccountStatus.ready,
        refreshFailed: true,
        cuentas: const [
          Account(
            id: 'a',
            numero: '19100000004521',
            tipo: AccountType.ahorro,
            moneda: Currency.pen,
            estado: 'activa',
            saldoDisponible: Money.soles(125040),
            saldoContable: Money.soles(125040),
          ),
        ],
      ),
    );
    addTearDown(b.close);
    await tester.pumpWidget(wrapWith(b));
    await tester.pump();

    expect(
      find.text('No pudimos actualizar. Estás viendo datos anteriores.'),
      findsOneWidget,
    );
    expect(find.text('S/ 1,250.40'), findsOneWidget);
  });
}

/// Bloc que ya nace en un estado dado y anota los eventos que recibe, sin
/// tocar ningún repositorio.
class _BlocConEstado extends AccountBloc {
  _BlocConEstado(AccountState inicial) : super(AccountActions(_RepoCaido())) {
    // ignore: invalid_use_of_visible_for_testing_member
    emit(inicial);
  }

  final recibidos = <AccountEvent>[];

  @override
  void add(AccountEvent event) => recibidos.add(event);
}

/// Repo que siempre falla por red; solo existe para construir el bloc.
class _RepoCaido implements AccountRepository {
  static const _caida = GlobalFailure<AccountFailure>.server(
    AccountFailure.network(),
  );

  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async => left(_caida);

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async => left(_caida);

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(String id) async =>
      left(_caida);

  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) async => left(_caida);

  @override
  FutureResult<AccountFailure, Account> renombrar(
    String cuentaId,
    String? nombre,
  ) async => left(_caida);
}
