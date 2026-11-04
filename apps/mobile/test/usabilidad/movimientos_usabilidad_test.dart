// APF3 · Usabilidad del historial de movimientos (ISO 25010).
// Spec: docs/apf3/spec-jheampierre-usabilidad-ui.md
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/presentation/home/widgets/movements_skeleton.dart';
import 'package:cuycash/presentation/movements/bloc/movements_bloc.dart';
import 'package:cuycash/presentation/movements/movements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/home/scripted_account_repository.dart';
import '_harness.dart';

void main() {
  late MovementsBloc todas;

  setUp(() async {
    todas = MovementsBloc(AccountActions(MemoryAccountRepository()))
      ..add(const MovementsEvent.started());
    await todas.stream.firstWhere((s) => s.status == MovementsStatus.ready);
  });

  tearDown(() => todas.close());

  Future<void> pump(
    WidgetTester tester, {
    MovementsBloc? bloc,
    bool conCuenta = false,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc ?? todas,
        child: appDePrueba(
          textScale: textScale,
          home: Builder(
            builder: (context) => MovementsScreen(
              cuenta: conCuenta ? MemoryLedger().cuentas.first : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UX-MOVIMIENTOS · accesibilidad', () {
    testWidgets('UX-MOV-01 áreas táctiles y etiquetas accesibles', (t) async {
      fijarPantalla(t);
      await pump(t);
      await verificarAccesibilidad(t);
    });
  });

  group('UX-MOVIMIENTOS · adaptabilidad', () {
    testWidgets('UX-MOV-02 con texto al 200 % no hay desbordes', (t) async {
      fijarPantalla(t);
      await pump(t, textScale: 2);
      verificarSinDesbordes(t);
      expect(find.text('Movimientos'), findsOneWidget);
    });

    testWidgets('UX-MOV-03 en un teléfono de 320×568 no hay desbordes', (
      t,
    ) async {
      fijarPantalla(t, size: pantallaPequena);
      await pump(t);
      verificarSinDesbordes(t);
    });
  });

  group('UX-MOVIMIENTOS · retroalimentación', () {
    testWidgets('UX-MOV-04 mientras carga se ve una silueta, no un vacío', (
      t,
    ) async {
      fijarPantalla(t);
      final lento = MovementsBloc(
        AccountActions(
          ScriptedAccountRepository(
            MemoryAccountRepository(),
            latencia: const Duration(seconds: 1),
          ),
        ),
      )..add(const MovementsEvent.started());
      addTearDown(lento.close);

      await t.pumpWidget(
        BlocProvider.value(
          value: lento,
          child: appDePrueba(home: const MovementsScreen()),
        ),
      );
      await t.pump();

      expect(find.byType(MovementsSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('UX-MOV-05 el historial de una cuenta muestra su saldo', (
      t,
    ) async {
      fijarPantalla(t);
      await pump(t, conCuenta: true);
      expect(find.textContaining('S/'), findsWidgets);
      verificarSinDesbordes(t);
    });
  });
}
