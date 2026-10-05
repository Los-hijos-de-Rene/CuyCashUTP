import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:cuycash/presentation/transfer/confirm_screen.dart';
import 'package:cuycash/presentation/transfer/receipt_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'fake_transfer_repositories.dart';

const _cuenta = Account(
  id: 'acc-demo-1',
  numero: '19100000004521',
  tipo: 'ahorro',
  moneda: 'PEN',
  estado: 'activa',
  saldoDisponible: Money.fromCentimos(125040),
  saldoContable: Money.fromCentimos(125040),
);
const _monto = Money.fromCentimos(5000);

Future<TransferBloc> _blocEnConfirmacion(FakeTransferRepository repo) async {
  final b = TransferBloc(
    TransferActions(repo),
    pending: pendientesDePrueba(),
    userId: 'u1',
  );
  b.add(const TransferEvent.started(_cuenta));
  b.add(const TransferEvent.recipientRequested('87654321'));
  await b.stream.firstWhere((s) => s.status == TransferStatus.ready);
  b.add(const TransferEvent.amountEntered(monto: _monto, motivo: 'Almuerzo'));
  return b;
}

void main() {
  late FakeTransferRepository repo;
  late TransferBloc bloc;
  Completer<Result<TransferFailure, TransferReceipt>>? enVuelo;

  // El bloc se crea fuera de testWidgets (su suscripción corre en el reloj
  // real), igual que en los tests del inicio.
  Future<void> preparar(
    FutureResult<TransferFailure, TransferReceipt> Function(int)? alEnviar,
  ) async {
    repo = FakeTransferRepository(alEnviar: alEnviar);
    bloc = await _blocEnConfirmacion(repo);
  }

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp.router(
          routerConfig: router,
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> escribirPin(WidgetTester tester, [String pin = '000000']) async {
    for (final d in pin.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  Finder boton() =>
      find.widgetWithText(ElevatedButton, 'Confirmar transferencia');

  testWidgets('el botón empieza deshabilitado hasta tener los 6 dígitos', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);

    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNull);
    await escribirPin(tester, '00000');
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNull);
    await escribirPin(tester, '0');
    expect(tester.widget<ElevatedButton>(boton()).onPressed, isNotNull);
  });

  testWidgets(
    'DOS toques seguidos en "Confirmar transferencia" con un repositorio '
    'lento producen UNA sola llamada',
    (tester) async {
      enVuelo = Completer();
      await preparar((_) => enVuelo!.future);
      await pump(tester);
      await escribirPin(tester);

      // Dos toques SIN renderizar entre ellos: el peor caso, en el que el
      // botón aún no tuvo oportunidad de deshabilitarse.
      await tester.tap(boton());
      await tester.tap(boton());
      await tester.pump();
      await tester.pump();

      expect(repo.llamadas, 1);

      // Y tras el primer toque el botón queda deshabilitado, con indicador.
      final elevated = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevated.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Un tercer toque, ya con el botón apagado, tampoco llega.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();
      expect(repo.llamadas, 1);

      enVuelo!.complete(right(FakeTransferRepository.constanciaDe(_monto)));
      await tester.pumpAndSettle();
      expect(repo.llamadas, 1);
    },
  );

  testWidgets('con el envío en vuelo el teclado no edita el PIN', (
    tester,
  ) async {
    enVuelo = Completer();
    await preparar((_) => enVuelo!.future);
    await pump(tester);
    await escribirPin(tester);
    await tester.tap(boton());
    await tester.pump();

    await tester.tap(
      find.byIcon(Icons.backspace_outlined),
      warnIfMissed: false,
    );
    await tester.pump();

    enVuelo!.complete(right(FakeTransferRepository.constanciaDe(_monto)));
    await tester.pumpAndSettle();
    expect(repo.pines, ['000000']);
  });

  testWidgets('un envío exitoso lleva a la constancia con el nombre resuelto', (
    tester,
  ) async {
    await preparar(null);
    await pump(tester);
    await escribirPin(tester);

    await tester.tap(boton());
    await tester.pumpAndSettle();

    expect(find.text('¡Envío realizado!'), findsOneWidget);
    expect(find.textContaining('J*** M*** R***'), findsOneWidget);
    // El monto sale una vez, con su formato, sin signo.
    expect(find.text('S/ 50.00'), findsOneWidget);
  });

  testWidgets(
    'un fallo de red permite reintentar con la MISMA clave, sin reescribir el PIN',
    (tester) async {
      await preparar(
        (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : right(FakeTransferRepository.constanciaDe(_monto)),
      );
      await pump(tester);
      await escribirPin(tester);

      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No pudimos confirmar tu envío'),
        findsOneWidget,
      );
      final reintentar = find.widgetWithText(
        ElevatedButton,
        'Reintentar envío',
      );
      expect(tester.widget<ElevatedButton>(reintentar).onPressed, isNotNull);

      await tester.tap(reintentar);
      await tester.pumpAndSettle();

      expect(repo.claves, hasLength(2));
      expect(repo.claves[1], repo.claves[0]);
      expect(repo.pines, ['000000', '000000']);
      expect(find.text('¡Envío realizado!'), findsOneWidget);
    },
  );

  testWidgets(
    'un PIN errado muestra los intentos que quedan, borra el PIN y conserva '
    'monto y destinatario',
    (tester) async {
      await preparar(
        (_) async =>
            FakeTransferRepository.falla(const TransferFailure.wrongPin(2)),
      );
      await pump(tester);
      await escribirPin(tester, '111111');

      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(
        find.text('PIN incorrecto. Te quedan 2 intentos.'),
        findsOneWidget,
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      // Sigue en la confirmación, con el resumen intacto.
      expect(find.text('S/ 50.00'), findsOneWidget);
      expect(find.textContaining('J*** M*** R***'), findsOneWidget);
      expect(bloc.state.monto, _monto);
    },
  );

  testWidgets('con saldo insuficiente dice qué pasó, no un error genérico', (
    tester,
  ) async {
    await preparar(
      (_) async => FakeTransferRepository.falla(
        const TransferFailure.insufficientFunds(),
      ),
    );
    await pump(tester);
    await escribirPin(tester);

    await tester.tap(boton());
    await tester.pumpAndSettle();

    expect(find.text('No te alcanza el saldo disponible.'), findsOneWidget);
  });

  testWidgets(
    'tras un fallo de red la confirmación queda sellada: no se puede salir '
    'hacia el monto, solo reintentar o volver al inicio',
    (tester) async {
      await preparar(
        (_) async =>
            FakeTransferRepository.falla(const TransferFailure.network()),
      );
      await pump(tester);
      await escribirPin(tester);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Reintentar envío'), findsOneWidget);
      expect(find.text('Volver al inicio'), findsOneWidget);

      // Aunque algo intentara editar el monto, el bloc lo ignora.
      bloc.add(
        const TransferEvent.amountEntered(monto: Money.fromCentimos(4000)),
      );
      await tester.pump();
      expect(bloc.state.monto, _monto);

      await tester.tap(find.text('Volver al inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('INICIO'), findsOneWidget);
    },
  );

  testWidgets(
    'idempotencyKeyReused (409): no se ofrece repetir, sino volver al inicio',
    (tester) async {
      await preparar(
        (_) async => FakeTransferRepository.falla(
          const TransferFailure.idempotencyKeyReused(),
        ),
      );
      await pump(tester);
      await escribirPin(tester);

      await tester.tap(boton());
      await tester.pumpAndSettle();

      expect(find.textContaining('empieza uno nuevo'), findsOneWidget);
      expect(boton(), findsNothing);
      expect(find.text('Reintentar envío'), findsNothing);

      await tester.tap(find.text('Volver al inicio'));
      await tester.pumpAndSettle();
      expect(find.text('INICIO'), findsOneWidget);
      expect(repo.llamadas, 1);
    },
  );

  testWidgets(
    'sellada y con un PIN errado en el reintento, el botón sigue diciendo '
    '"Reintentar envío"',
    (tester) async {
      await preparar(
        (n) async => n == 1
            ? FakeTransferRepository.falla(const TransferFailure.network())
            : FakeTransferRepository.falla(const TransferFailure.wrongPin(2)),
      );
      await pump(tester);
      await escribirPin(tester);
      await tester.tap(boton());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reintentar envío'));
      await tester.pumpAndSettle();

      expect(
        find.text('PIN incorrecto. Te quedan 2 intentos.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar envío'), findsOneWidget);
      expect(boton(), findsNothing);
    },
  );

  testWidgets(
    '"Volver al inicio" con la intención sellada avisa antes de salir',
    (tester) async {
      await preparar(
        (_) async =>
            FakeTransferRepository.falla(const TransferFailure.network()),
      );
      await pump(tester);
      await escribirPin(tester);
      await tester.tap(boton());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Volver al inicio'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin confirmar?'), findsOneWidget);
      expect(
        find.textContaining('Revísalo en tus movimientos'),
        findsOneWidget,
      );

      // Cancelar se queda donde está.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('INICIO'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Volver al inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('INICIO'), findsOneWidget);
    },
  );
}
