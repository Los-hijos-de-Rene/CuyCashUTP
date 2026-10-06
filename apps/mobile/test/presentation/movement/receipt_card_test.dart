import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/movement/widgets/receipt_card.dart';
import 'package:cuycash/presentation/movement/widgets/share_receipt_button.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptCard _card({
  String estado = 'confirmada',
  bool reutilizada = false,
  Money? saldoPosterior,
}) => ReceiptCard(
  headline: 'Enviaste',
  monto: const Money.fromCentimos(4500),
  fecha: DateTime.utc(2026, 10, 5, 19, 30),
  transactionId: 'tx-demo-1',
  estado: estado,
  contraparteLabel: 'Enviado a',
  contraparte: 'Bodega Don Aurelio',
  cuentaDestinoMasked: '••••7732',
  motivo: 'Menú',
  saldoPosterior: saldoPosterior,
  reutilizada: reutilizada,
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: CuyCashTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('muestra monto, contraparte, motivo, estado y operación', (
    tester,
  ) async {
    await _pump(tester, _card(saldoPosterior: const Money.fromCentimos(1000)));

    expect(find.text('Enviaste'), findsOneWidget);
    expect(find.text('S/ 45.00'), findsOneWidget);
    expect(find.text('Enviado a'), findsOneWidget);
    expect(find.text('Bodega Don Aurelio'), findsOneWidget);
    expect(find.text('••••7732'), findsOneWidget);
    expect(find.text('Menú'), findsOneWidget);
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Saldo posterior'), findsOneWidget);
    expect(find.text('tx-demo-1'), findsOneWidget);
  });

  testWidgets('lo que no se sabe, no se pinta', (tester) async {
    await _pump(
      tester,
      ReceiptCard(
        headline: 'Recarga de saldo',
        monto: Money.fromCentimos(1000),
        fecha: _fecha,
        transactionId: 'tx-9',
        estado: 'confirmada',
      ),
    );

    expect(find.text('Cuenta destino'), findsNothing);
    expect(find.text('Motivo'), findsNothing);
    expect(find.text('Saldo posterior'), findsNothing);
    expect(find.text('Con'), findsNothing);
  });

  testWidgets('un estado desconocido se muestra tal cual', (tester) async {
    await _pump(tester, _card(estado: 'en_revision'));
    expect(find.text('en_revision'), findsOneWidget);
  });

  testWidgets('la repetición idempotente se avisa', (tester) async {
    await _pump(tester, _card(reutilizada: true));
    expect(
      find.text('Este envío ya estaba registrado. No se cobró otra vez.'),
      findsOneWidget,
    );
  });

  testWidgets('el texto para compartir dice lo mismo que la tarjeta', (
    tester,
  ) async {
    await _pump(tester, _card());
    final l10n = AppLocalizations.of(tester.element(find.byType(ReceiptCard)));

    final texto = _card().shareText(l10n);

    expect(texto, startsWith('Constancia de CuyCash'));
    expect(texto, contains('Enviaste: S/ 45.00'));
    expect(texto, contains('Enviado a: Bodega Don Aurelio'));
    expect(texto, contains('N.º de operación: tx-demo-1'));
  });

  testWidgets('el botón entrega el texto a quien comparte', (tester) async {
    String? compartido;
    await _pump(
      tester,
      ShareReceiptButton(
        text: 'hola',
        onShare: (t) async => compartido = t,
      ),
    );

    await tester.tap(find.text('Compartir constancia'));
    await tester.pump();

    expect(compartido, 'hola');
  });
}

final _fecha = DateTime.utc(2026, 10, 5, 19, 30);
