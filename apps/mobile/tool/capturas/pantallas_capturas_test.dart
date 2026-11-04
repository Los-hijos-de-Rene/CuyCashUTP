// APF3 #99 · Generador de capturas PNG de las pantallas para la evidencia.
//
// NO forma parte de la suite de `flutter test`: vive en `tool/capturas/` para
// que el CI no lo ejecute. Se corre a mano desde `apps/mobile`:
//
//   flutter test tool/capturas --update-goldens
//
// Deja 8 pantallas × 2 tamaños (390×844 y 320×568) en
// `docs/apf3/evidencias/jheampierre/capturas/`. Cada pantalla reutiliza el
// setup exacto de su test de usabilidad (`test/usabilidad/`).
import 'dart:io';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/auth/login_screen.dart';
import 'package:cuycash/presentation/home/bloc/account_bloc.dart';
import 'package:cuycash/presentation/home/home_screen.dart';
import 'package:cuycash/presentation/movements/bloc/movements_bloc.dart';
import 'package:cuycash/presentation/movements/movements_screen.dart';
import 'package:cuycash/presentation/profile/profile_screen.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_data_step.dart';
import 'package:cuycash/presentation/transfer/amount_screen.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:cuycash/presentation/transfer/confirm_screen.dart';
import 'package:cuycash/presentation/transfer/receipt_screen.dart';
import 'package:cuycash/presentation/transfer/recipient_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../test/presentation/register/register_test_support.dart';
import '../../test/presentation/transfer/fake_transfer_repositories.dart';
import '../../test/usabilidad/_harness.dart';

const _tamanos = <Size>[pantallaNormal, pantallaPequena];

const _cuentaOrigen = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

const _monto = Money.soles(5000);

/// La familia real que usa el tema: al venir de un paquete, Flutter la registra
/// como `packages/<paquete>/<familia>`.
const _familiaTema = 'packages/design_system/Inter';

/// Carga la fuente variable real de Inter para que el texto no salga como cajas
/// (en `flutter_test` el tipo de letra por defecto es Ahem).
Future<ByteData> _bytesDeInter() async {
  try {
    return await rootBundle.load(
      'packages/design_system/assets/fonts/Inter-Variable.ttf',
    );
  } on Object {
    // `flutter test` corre desde `apps/mobile`.
    final bytes = await File(
      '../../packages/design_system/assets/fonts/Inter-Variable.ttf',
    ).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

Future<void> _cargarFuente() async {
  final bytes = await _bytesDeInter();
  for (final familia in {'Inter', _familiaTema}) {
    final loader = FontLoader(familia)..addFont(Future.value(bytes));
    await loader.load();
  }

  // Sin esto los `Icon` de Material salen como cajas en la captura.
  final iconos = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await iconos.load();
}

/// Igual que el arnés de usabilidad, pero sin la cinta de "DEBUG": la evidencia
/// debe verse como la app real.
Widget _app({required Widget home}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// Variante con router, también sin la cinta de "DEBUG".
Widget _appRouter({required GoRouter router}) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  routerConfig: router,
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);

/// Captura el `MaterialApp` completo con el nombre pedido.
Future<void> _capturar(WidgetTester tester, String pantalla, Size tamano) {
  final ancho = tamano.width.toInt();
  final alto = tamano.height.toInt();
  return expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(
      '../../../../docs/apf3/evidencias/jheampierre/capturas/'
      '${pantalla}_${ancho}x$alto.png',
    ),
  );
}

void main() {
  setUpAll(_cargarFuente);

  Future<AuthBloc> crearAuth() async => AuthBloc(
    AuthActions(
      MemoryAuthRepository(
        initial: const AuthSession(userId: 'u', identifier: '12345678'),
      ),
    ),
    DeviceActions(MemoryDeviceStore()),
    IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
  );

  Future<DeviceActions> crearDevice() async {
    final device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Jheampierre Ruiz Salas',
        alias: '@jheampierre',
      ),
    );
    return device;
  }

  // ---------------------------------------------------------------------------
  // login · LoginScreen (setup de login_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpLogin(WidgetTester tester) async {
    final store = MemoryDeviceStore();
    await store.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Juan Pérez',
        alias: '@juan',
      ),
    );
    final bloc = AuthBloc(
      AuthActions(MemoryAuthRepository()),
      DeviceActions(store),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _app(home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura login ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpLogin(t);
        await _capturar(t, 'login', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // registro · RegisterDataStep dentro de Scaffold
  // (setup de registro_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpRegistro(WidgetTester tester) async {
    final bloc = RegisterBloc(
      AuthActions(MemoryAuthRepository()),
      biometric: biometricParaTests(),
      kyc: kycParaTests(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _app(home: const Scaffold(body: RegisterDataStep())),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura registro ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpRegistro(t);
        await _capturar(t, 'registro', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // inicio · HomeScreen (setup de inicio_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpInicio(WidgetTester tester) async {
    final auth = await crearAuth();
    addTearDown(auth.close);
    final device = await crearDevice();
    final account = AccountBloc(AccountActions(MemoryAccountRepository()));
    // ignore: invalid_use_of_visible_for_testing_member
    account.emit(
      const AccountState(status: AccountStatus.ready, cuentas: [_cuentaOrigen]),
    );
    addTearDown(account.close);

    await tester.pumpWidget(
      RepositoryProvider<DeviceActions>.value(
        value: device,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider.value(value: account),
          ],
          child: _app(home: const HomeScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura inicio ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpInicio(t);
        await _capturar(t, 'inicio', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // destinatario · RecipientScreen (setup de destinatario_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpDestinatario(WidgetTester tester) async {
    final bloc = TransferBloc(
      TransferActions(FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    addTearDown(bloc.close);
    final router = GoRouter(
      initialLocation: AppRoutes.enviar,
      routes: [
        GoRoute(
          path: AppRoutes.enviar,
          builder: (_, _) => const RecipientScreen(cuenta: _cuentaOrigen),
        ),
        GoRoute(
          path: AppRoutes.enviarMonto,
          builder: (_, _) => const Text('MONTO'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _appRouter(router: router),
      ),
    );
    await tester.pump();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura destinatario ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpDestinatario(t);
        await _capturar(t, 'destinatario', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // monto · AmountScreen (setup de monto_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpMonto(WidgetTester tester) async {
    final bloc = TransferBloc(
      TransferActions(FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    addTearDown(bloc.close);
    bloc.add(const TransferEvent.started(_cuentaOrigen));
    bloc.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
    await bloc.stream.firstWhere((s) => s.status == TransferStatus.ready);

    final router = GoRouter(
      initialLocation: AppRoutes.enviarMonto,
      routes: [
        GoRoute(
          path: AppRoutes.enviarMonto,
          builder: (_, _) => const AmountScreen(),
        ),
        GoRoute(
          path: AppRoutes.enviarConfirmar,
          builder: (_, _) => const Text('CONFIRMAR'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _appRouter(router: router),
      ),
    );
    await tester.pump();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura monto ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpMonto(t);
        await _capturar(t, 'monto', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // confirmar · ConfirmScreen (setup de confirmar_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpConfirmar(WidgetTester tester) async {
    final bloc = TransferBloc(
      TransferActions(FakeTransferRepository()),
      pending: pendientesDePrueba(),
      userId: 'u1',
    );
    addTearDown(bloc.close);
    bloc.add(const TransferEvent.started(_cuentaOrigen));
    bloc.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
    await bloc.stream.firstWhere((s) => s.status == TransferStatus.ready);
    bloc.add(
      const TransferEvent.amountEntered(monto: _monto, motivo: 'Almuerzo'),
    );
    bloc.add(const TransferEvent.confirmationOpened());
    await bloc.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);

    final router = GoRouter(
      initialLocation: AppRoutes.enviarConfirmar,
      routes: [
        GoRoute(
          path: AppRoutes.enviarConfirmar,
          builder: (_, _) => const ConfirmScreen(),
        ),
        GoRoute(
          path: AppRoutes.enviarConstancia,
          builder: (_, _) => const ReceiptScreen(),
        ),
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('INICIO')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _appRouter(router: router),
      ),
    );
    await tester.pump();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura confirmar ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpConfirmar(t);
        await _capturar(t, 'confirmar', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // movimientos · MovementsScreen (setup de movimientos_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpMovimientos(WidgetTester tester) async {
    final bloc = MovementsBloc(AccountActions(MemoryAccountRepository()))
      ..add(const MovementsEvent.started());
    await bloc.stream.firstWhere((s) => s.status == MovementsStatus.ready);
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: _app(
          home: MovementsScreen(cuenta: MemoryLedger().cuentas.first),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura movimientos ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpMovimientos(t);
        await _capturar(t, 'movimientos', tamano);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // perfil · ProfileScreen (setup de perfil_usabilidad_test.dart)
  // ---------------------------------------------------------------------------
  Future<void> pumpPerfil(WidgetTester tester) async {
    final auth = await crearAuth();
    addTearDown(auth.close);
    final device = await crearDevice();
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
          value: auth,
          child: _appRouter(router: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final tamano in _tamanos) {
    testWidgets(
      'captura perfil ${tamano.width.toInt()}x${tamano.height.toInt()}',
      (t) async {
        fijarPantalla(t, size: tamano);
        await pumpPerfil(t);
        await _capturar(t, 'perfil', tamano);
      },
    );
  }
}
