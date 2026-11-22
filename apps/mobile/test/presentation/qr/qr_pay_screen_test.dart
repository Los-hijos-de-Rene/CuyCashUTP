import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/qr/application/qr_actions.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/qr/bloc/qr_pay_bloc.dart';
import 'package:cuycash/presentation/qr/qr_pay_screen.dart';
import 'package:cuycash/presentation/qr/widgets/qr_gallery_reader.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'qr_test_support.dart';

const _cuenta = Account(
  id: 'acc-demo-2',
  numero: '19100000008830',
  tipo: AccountType.sueldo,
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(350000),
  saldoContable: Money.soles(350000),
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    QrGalleryResult galeria = const QrGalleryCancelled(),
    FakeQrRepository? repo,
  }) async {
    final bloc = QrPayBloc(
      actions: QrActions(repo ?? FakeQrRepository()),
      cuentaOrigen: _cuenta,
      userId: 'u1',
      clock: () => DateTime.utc(2026, 11, 4, 12),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QrPayScreen(
            cuentaOrigen: _cuenta,
            cameraBuilder: (onDetected) => TextButton(
              onPressed: () => onDetected('cuycash://qr?demo=1'),
              child: const Text('SIMULAR ESCANEO'),
            ),
            galleryReader: () async => galeria,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el escaneo muestra nombre y monto antes de confirmar', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('SIMULAR ESCANEO'));
    await t.pumpAndSettle();

    expect(find.text('Revisa antes de pagar'), findsOneWidget);
    expect(find.text('J*** M*** R***'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsOneWidget);
    expect(find.text('Almuerzo'), findsOneWidget);
    expect(find.text('Pagar'), findsOneWidget);
  });

  testWidgets('pagar pide PIN y termina en la constancia', (t) async {
    await pump(t);
    await t.tap(find.text('SIMULAR ESCANEO'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pagar'));
    await t.pumpAndSettle();

    expect(find.text('Confirma con tu PIN'), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await t.tap(find.text('0'));
      await t.pump();
    }
    await t.pumpAndSettle();

    expect(find.text('¡Pago realizado!'), findsOneWidget);
    expect(find.textContaining('tx-qr-1'), findsOneWidget);
  });

  testWidgets('no hay campo para pegar el código: se sube una imagen', (
    t,
  ) async {
    await pump(t);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Subir imagen del QR'), findsOneWidget);
  });

  testWidgets('un QR leído de la galería va a la vista previa', (t) async {
    await pump(t, galeria: const QrGalleryFound('cuycash://qr?demo=1'));
    await t.tap(find.text('Subir imagen del QR'));
    await t.pumpAndSettle();

    expect(find.text('Revisa antes de pagar'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsOneWidget);
  });

  testWidgets('una imagen sin QR avisa y se queda escaneando', (t) async {
    await pump(t, galeria: const QrGalleryNotFound());
    await t.tap(find.text('Subir imagen del QR'));
    await t.pumpAndSettle();

    expect(
      find.text('No encontramos un QR en esa imagen. Prueba con otra.'),
      findsOneWidget,
    );
    expect(find.text('SIMULAR ESCANEO'), findsOneWidget);
  });

  testWidgets('cerrar la galería sin elegir no muestra error', (t) async {
    await pump(t);
    await t.tap(find.text('Subir imagen del QR'));
    await t.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('SIMULAR ESCANEO'), findsOneWidget);
  });

  group('"Mi QR" (monto libre)', () {
    Future<FakeQrRepository> escanearLibre(WidgetTester t) async {
      final repo = FakeQrRepository(
        alLeer: (_) async => right(previewLibreDePrueba),
      );
      await pump(t, repo: repo);
      await t.tap(find.text('SIMULAR ESCANEO'));
      await t.pumpAndSettle();
      return repo;
    }

    testWidgets('pide el monto y dice cuánto se puede pagar hoy', (t) async {
      await escanearLibre(t);
      expect(find.text('¿Cuánto vas a pagar?'), findsOneWidget);
      expect(find.text('L*** Q***'), findsOneWidget);
      expect(
        find.text('Hoy puedes pagar con QR hasta S/ 30.00.'),
        findsOneWidget,
      );
    });

    testWidgets('más de lo que queda hoy se avisa sin pedir el PIN', (t) async {
      await escanearLibre(t);
      await t.enterText(find.byType(TextField).first, '45');
      await t.tap(find.text('Pagar'));
      await t.pumpAndSettle();
      expect(
        find.text('Hoy solo puedes pagar con QR hasta S/ 30.00.'),
        findsOneWidget,
      );
      expect(find.text('¿Cuánto vas a pagar?'), findsOneWidget);
    });

    testWidgets('con monto válido pide el PIN y paga lo escrito', (t) async {
      final repo = await escanearLibre(t);
      await t.enterText(find.byType(TextField).first, '12.50');
      await t.enterText(find.byType(TextField).last, 'Menú');
      await t.tap(find.text('Pagar'));
      await t.pumpAndSettle();
      expect(find.textContaining('S/ 12.50'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await t.tap(find.text('0'));
        await t.pump();
      }
      await t.pumpAndSettle();
      expect(repo.montoPagado, const Money.soles(1250));
      expect(repo.mensajePagado, 'Menú');
    });
  });
}
