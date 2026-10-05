import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/topup/bloc/topup_bloc.dart';
import 'package:cuycash/presentation/topup/topup_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../transfer/fake_transfer_repositories.dart';

const _cuenta = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: 'ahorro',
  moneda: 'PEN',
  estado: 'activa',
  saldoDisponible: Money.fromCentimos(125040),
  saldoContable: Money.fromCentimos(125040),
);
const _monto = Money.fromCentimos(10000);

void main() {
  late FakeTransferRepository repo;
  late TopUpBloc bloc;
  bool? resultado;

  Future<void> preparar(
    FutureResult<TransferFailure, TransferReceipt> Function(int)? alRecargar, {
    bool discoSano = true,
  }) async {
    repo = FakeTransferRepository(alRecargar: alRecargar);
    bloc = TopUpBloc(
      TransferActions(repo),
      pending: pendientesDePrueba(
        store: discoSano ? MemoryPendingTransferStore() : StoreQueNoEscribe(),
      ),
      userId: 'u1',
    )..add(const TopUpEvent.opened(cuentaId: 'acc-demo-1'));
    await bloc.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);
    resultado = null;
  }

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  resultado = await context.push<bool>('/recargar'),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        GoRoute(
          path: '/recargar',
          builder: (_, _) => BlocProvider.value(
            value: bloc,
            child: const TopUpScreen(cuenta: _cuenta),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  }

  Future<void> escribirMonto(WidgetTester tester, String monto) async {
    await tester.enterText(find.byType(TextField), monto);
    await tester.pump();
  }

  Future<void> escribirPin(WidgetTester tester, [String pin = '000000']) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  Finder boton([String label = 'Confirmar recarga']) =>
      find.widgetWithText(ElevatedButton, label);

  testWidgets('el botón espera monto válido Y los 6 dígitos del PIN', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);

    await escribirPin(tester);
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNull);

    await escribirMonto(tester, '100');
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNotNull);
  });

  testWidgets('un monto sobre el máximo se explica y no deja confirmar', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);
    await escribirPin(tester);

    await escribirMonto(tester, '2000.01');

    expect(find.text('El máximo por recarga es S/ 2,000.00.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNull);
  });

  testWidgets('el separador de miles se rechaza diciendo por qué', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);

    await escribirMonto(tester, '1,234');

    expect(
      find.text('Escribe el monto sin comas de miles. Ejemplo: 1250.50'),
      findsOneWidget,
    );
  });

  testWidgets(
    'DOS toques seguidos en "Confirmar recarga" con repo lento = UNA llamada',
    (tester) async {
      final enVuelo = Completer<Result<TransferFailure, TransferReceipt>>();
      addTearDown(() {
        // Si el test falla, tearDown -> bloc.close() esperaría a este
        // Completer para siempre (10 min de timeout): se libera.
        if (!enVuelo.isCompleted) {
          enVuelo.complete(left(const GlobalFailure.noConnection()));
        }
      });
      await preparar((_) => enVuelo.future);
      await pump(tester);
      await escribirMonto(tester, '100');
      await escribirPin(tester);

      await tester.tap(boton());
      await tester.tap(boton());
      await tester.pump();
      await tester.pump();

      expect(repo.recargas, 1);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      enVuelo.complete(right(FakeTransferRepository.constanciaDe(_monto)));
      await tester.pumpAndSettle();
      expect(repo.recargas, 1);
    },
  );

  testWidgets('una recarga exitosa muestra la constancia y vuelve con true', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);
    await escribirMonto(tester, '100');
    await escribirPin(tester);

    await tester.tap(boton());
    await tester.pumpAndSettle();

    expect(find.text('¡Recarga realizada!'), findsOneWidget);
    expect(find.text('S/ 100.00'), findsOneWidget);

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);
    expect(find.text('ABRIR'), findsOneWidget);
  });

  testWidgets('el gesto de atrás en la constancia también refresca el inicio', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);
    await escribirMonto(tester, '100');
    await escribirPin(tester);
    await tester.tap(boton());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
  });

  testWidgets(
    'un fallo de red sella la intención: monto bloqueado, reintento con la '
    'MISMA clave, y salir pide confirmación',
    (tester) async {
      await preparar(
        (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      await pump(tester);
      await escribirMonto(tester, '100');
      await escribirPin(tester);
      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No pudimos confirmar tu recarga'),
        findsOneWidget,
      );
      // El monto ya no se edita ni hay flecha de atrás.
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(find.byType(BackButton), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Recargar saldo'), findsOneWidget);

      // Salir avisa, y cancelar se queda.
      await tester.tap(find.text('Volver al inicio'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin confirmar?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Recargar saldo'), findsOneWidget);

      await tester.tap(boton('Reintentar recarga'));
      await tester.pumpAndSettle();

      expect(repo.clavesRecarga, hasLength(2));
      expect(repo.clavesRecarga[1], repo.clavesRecarga[0]);
      expect(find.text('¡Recarga realizada!'), findsOneWidget);
    },
  );

  testWidgets('salir con el resultado desconocido devuelve true tras avisar', (
    tester,
  ) async {
    await preparar(
      (_) async =>
          FakeTransferRepository.falla(const TransferFailure.network()),
    );
    await pump(tester);
    await escribirMonto(tester, '100');
    await escribirPin(tester);
    await tester.tap(boton());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
  });

  testWidgets(
    'sin la clave guardada el aviso es el fuerte, no la promesa de no cobrar '
    'dos veces',
    (tester) async {
      await preparar(
        (_) async =>
            FakeTransferRepository.falla(const TransferFailure.network()),
        discoSano: false,
      );
      await pump(tester);
      await escribirMonto(tester, '100');
      await escribirPin(tester);
      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No pudimos recordar este intento'),
        findsOneWidget,
      );
      expect(find.textContaining('no se cobrará dos veces'), findsNothing);
    },
  );

  testWidgets('un PIN errado borra el PIN y conserva el monto', (tester) async {
    await preparar(
      (_) async =>
          FakeTransferRepository.falla(const TransferFailure.wrongPin(2)),
    );
    await pump(tester);
    await escribirMonto(tester, '100');
    await escribirPin(tester, '111111');
    await tester.tap(boton());
    await tester.pumpAndSettle();

    expect(find.text('PIN incorrecto. Te quedan 2 intentos.'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(bloc.state.monto, _monto);
  });
}
