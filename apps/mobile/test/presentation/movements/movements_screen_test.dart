import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/home/widgets/balance_card.dart';
import 'package:cuycash/presentation/home/widgets/movements_skeleton.dart';
import 'package:cuycash/presentation/movements/bloc/movements_bloc.dart';
import 'package:cuycash/presentation/movements/movements_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../home/scripted_account_repository.dart';

void main() {
  Widget app(MovementsBloc bloc, {bool conCuenta = false}) =>
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MovementsScreen(
              cuenta: conCuenta ? MemoryLedger().cuentas.first : null,
            ),
          ),
        ),
      );

  testWidgets('mientras carga muestra la silueta, no un spinner', (t) async {
    final repo = ScriptedAccountRepository(
      MemoryAccountRepository(),
      latencia: const Duration(seconds: 1),
    );
    final bloc = MovementsBloc(AccountActions(repo))
      ..add(const MovementsEvent.started());
    addTearDown(bloc.close);
    await t.pumpWidget(app(bloc));
    await t.pump();

    expect(find.byType(MovementsSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await t.pump(const Duration(seconds: 1));
  });

  // Los blocs que deben llegar a `ready` se crean y cargan FUERA de
  // testWidgets: dentro, su cola de eventos vive en el reloj falso.
  late MovementsBloc todas;
  late MovementsBloc deUnaCuenta;
  late ScriptedAccountRepository paginado;
  late MovementsBloc todasPaginado;

  Future<MovementsBloc> cargado(MovementsBloc b) async {
    b.add(const MovementsEvent.started());
    await b.stream.firstWhere((s) => s.status == MovementsStatus.ready);
    return b;
  }

  setUp(() async {
    todas = await cargado(
      MovementsBloc(AccountActions(MemoryAccountRepository())),
    );
    deUnaCuenta = await cargado(
      MovementsBloc(
        AccountActions(MemoryAccountRepository()),
        cuentaId: MemoryLedger.cuentaId,
      ),
    );
    paginado = ScriptedAccountRepository(MemoryAccountRepository(pageSize: 1));
    todasPaginado = await cargado(MovementsBloc(AccountActions(paginado)));
  });

  tearDown(() async {
    await todas.close();
    await deUnaCuenta.close();
    await todasPaginado.close();
  });

  testWidgets('el de todas: título "Movimientos" y cada fila con su cuenta', (
    t,
  ) async {
    await t.pumpWidget(app(todas));
    await t.pumpAndSettle();

    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.byType(BalanceCard), findsNothing);
    expect(find.textContaining('Ahorros · ••••4521'), findsNWidgets(3));
  });

  testWidgets(
    'el de una cuenta: su tarjeta arriba y filas sin repetir la cuenta',
    (t) async {
      await t.pumpWidget(app(deUnaCuenta, conCuenta: true));
      await t.pumpAndSettle();

      expect(find.byType(BalanceCard), findsOneWidget);
      expect(find.text('B*** D*** A***'), findsOneWidget);
      expect(find.textContaining('Ahorros · ••••4521'), findsNothing);
    },
  );

  testWidgets('cerca del final pide la página siguiente', (t) async {
    await t.pumpWidget(app(todasPaginado));
    await t.pump();
    final antes = paginado.paginas;
    // Con una sola fila la lista ya está "cerca del final": el primer scroll
    // pide más.
    await t.drag(find.byType(ListView), const Offset(0, -50));
    await t.pump();

    expect(paginado.paginas, greaterThan(antes));
    expect(todasPaginado.state.loadingMore, isTrue);
    // Deja que llegue la página para no cerrar el bloc con ella en vuelo.
    await t.runAsync(
      () => todasPaginado.stream.firstWhere((s) => !s.loadingMore),
    );
  });
}
