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
import 'package:cuycash/presentation/home/widgets/movements_skeleton.dart';
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
      expect(find.text('••••4521'), findsOneWidget);
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

    // `.first`: la tarjeta siguiente asoma por el borde y también se construye.
    await tester.tap(
      find.descendant(
        of: find.byType(BalanceCard),
        matching: find.byIcon(Icons.visibility),
      ).first,
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
    for (final label in ['Transferir', 'Depositar']) {
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
    // Solo hay 3 movimientos: no hay más que ver.
    expect(find.text('Ver más'), findsNothing);
    expect(find.byTooltip('Notificaciones'), findsNothing);
    // Lo que sí existe sigue ahí.
    expect(find.text('Transferir'), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    expect(find.text('Depositar'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
  });

  Widget wrapRouter(AccountBloc b, GoRouter router) {
    addTearDown(router.dispose);
    return RepositoryProvider<DeviceActions>.value(
      value: device,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider<AccountBloc>.value(value: b),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

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

  testWidgets(
    'refrescando sin movimientos muestra la silueta, sin "aún no tienes '
    'movimientos" ni spinner',
    (tester) async {
      final cargando = _BlocConEstado(
        const AccountState(
          status: AccountStatus.ready,
          refreshing: true,
          cuentas: [_ahorro],
        ),
      );
      addTearDown(cargando.close);
      await tester.pumpWidget(wrapWith(cargando));
      await tester.pump();

      expect(find.byType(MovementsSkeleton), findsOneWidget);
      expect(find.byType(MovementsCard), findsNothing);
      expect(find.text('Aún no tienes movimientos'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
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

    await tester.tap(find.text('Depositar'));
    await tester.pump();

    expect(
      find.text('No pudimos cargar tu cuenta.'),
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

      await tester.tap(find.text('Depositar'));
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

  testWidgets('el lápiz abre la hoja y guardar "Casa" renombra la tarjeta', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cambiar el nombre de la cuenta').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Casa');
    await tester.tap(find.text('Guardar'));
    // El bloc nació fuera de FakeAsync: su respuesta llega en el reloj real.
    await tester.runAsync(() => account.stream.firstWhere((s) => !s.renaming));
    await tester.pumpAndSettle();

    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Nombre de la cuenta'), findsNothing);
  });

  testWidgets(
    'los últimos movimientos son de todas las cuentas y cada uno dice de cuál',
    (tester) async {
      final b = _BlocConEstado(
        AccountState(
          status: AccountStatus.ready,
          cuentas: const [_ahorro],
          recientes: [
            _mov('tx-1', cuenta: _refAhorro, monto: const Money.soles(4500)),
            _mov('tx-2', cuenta: _refAhorro, destino: _refSueldo),
          ],
        ),
      );
      addTearDown(b.close);
      await tester.pumpWidget(wrapWith(b));
      await tester.pump();

      expect(find.text('Movimientos'), findsOneWidget);
      // Sin subtítulo: cada fila ya dice de qué cuenta es.
      expect(find.text('De todas tus cuentas'), findsNothing);
      // Ya no hay fila "Mis cuentas" con botón.
      expect(find.text('Mis cuentas'), findsNothing);
      expect(find.textContaining('Ahorros · ••••4521'), findsOneWidget);
      expect(find.text('- S/ 45.00'), findsOneWidget);
      // Entre propias: una fila neutra, sin signo.
      expect(find.text('Entre tus cuentas'), findsOneWidget);
      expect(find.textContaining('Ahorros → Planilla'), findsOneWidget);
      expect(find.text('S/ 30.00'), findsOneWidget);
      expect(find.text('- S/ 30.00'), findsNothing);
    },
  );

  testWidgets('el menú ⋮ ofrece abrir cuenta y la abre', (tester) async {
    final b = _BlocConEstado(
      const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
    );
    addTearDown(b.close);
    final router = _router();
    await tester.pumpWidget(wrapRouter(b, router));
    await tester.pump();

    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('ABRIR 1'), findsOneWidget);
  });

  testWidgets('con cupo, el carrusel termina en "Abrir otra cuenta"', (
    tester,
  ) async {
    final b = _BlocConEstado(
      const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
    );
    addTearDown(b.close);
    await tester.pumpWidget(wrapRouter(b, _router()));
    await tester.pump();

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir otra cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('ABRIR 1'), findsOneWidget);
  });

  testWidgets('con cinco cuentas no se ofrece abrir otra', (tester) async {
    Account cuenta(int i) => Account(
      id: 'c$i',
      numero: '1910000000000$i'.padRight(14, '0'),
      tipo: AccountType.ahorro,
      moneda: Currency.pen,
      estado: 'activa',
      saldoDisponible: const Money.soles(1000),
      saldoContable: const Money.soles(1000),
    );
    final b = _BlocConEstado(
      AccountState(
        status: AccountStatus.ready,
        cuentas: [for (var i = 0; i < 5; i++) cuenta(i)],
        seleccionada: 4,
      ),
    );
    addTearDown(b.close);
    await tester.pumpWidget(wrapWith(b));
    await tester.pump();

    // La última página es la cuenta, no la tarjeta de abrir.
    expect(find.text('Abrir otra cuenta'), findsNothing);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    final opcion = tester.widget<PopupMenuItem<Object?>>(
      find.ancestor(
        of: find.text('Abrir cuenta'),
        matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
      ),
    );
    expect(opcion.enabled, isFalse);
  });

  testWidgets('tocar una tarjeta abre los movimientos de esa cuenta', (
    tester,
  ) async {
    final b = _BlocConEstado(
      const AccountState(status: AccountStatus.ready, cuentas: [_ahorro]),
    );
    addTearDown(b.close);
    await tester.pumpWidget(wrapRouter(b, _router()));
    await tester.pump();

    await tester.tap(find.text('S/ 1,250.40'));
    await tester.pumpAndSettle();

    expect(find.text('MOVIMIENTOS a'), findsOneWidget);
  });

  testWidgets('"Ver más" aparece si hay más y abre el historial de todas', (
    tester,
  ) async {
    final b = _BlocConEstado(
      AccountState(
        status: AccountStatus.ready,
        cuentas: const [_ahorro],
        recientes: [_mov('tx-1', cuenta: _refAhorro)],
        hayMasMovimientos: true,
      ),
    );
    addTearDown(b.close);
    await tester.pumpWidget(wrapRouter(b, _router()));
    await tester.pump();

    await tester.tap(find.text('Ver más'));
    await tester.pumpAndSettle();

    expect(find.text('MOVIMIENTOS todas'), findsOneWidget);
  });

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
      find.text('No pudimos actualizar los datos.'),
      findsOneWidget,
    );
    expect(find.text('S/ 1,250.40'), findsOneWidget);
  });
}

const _ahorro = Account(
  id: 'a',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

const _refAhorro = MovementAccountRef(
  id: 'a',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  numeroMasked: '••••4521',
);

const _refSueldo = MovementAccountRef(
  id: 's',
  tipo: AccountType.sueldo,
  moneda: Currency.pen,
  numeroMasked: '••••8830',
  nombre: 'Planilla',
);

Movement _mov(
  String id, {
  required MovementAccountRef cuenta,
  MovementAccountRef? destino,
  Money monto = const Money.soles(3000),
}) => Movement(
  transactionId: id,
  tipo: MovementKind.transferencia,
  direccion: MovementDirection.debito,
  monto: monto,
  saldoPosterior: const Money.soles(122040),
  fecha: DateTime.utc(2026, 10, 6, 15),
  contraparte: 'c*** p***',
  cuenta: cuenta,
  cuentaDestino: destino,
);

/// Inicio con rutas de mentira para ver a dónde navega cada toque.
GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/movimientos',
      builder: (_, state) => Text(switch (state.extra) {
        final Account c => 'MOVIMIENTOS ${c.id}',
        _ => 'MOVIMIENTOS todas',
      }),
    ),
    GoRoute(
      path: '/cuentas/abrir',
      builder: (_, state) =>
          Text('ABRIR ${(state.extra as List<Account>).length}'),
    ),
  ],
);

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
  FutureResult<AccountFailure, MovementPage> todosLosMovimientos({
    String? cursor,
    int? limit,
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
