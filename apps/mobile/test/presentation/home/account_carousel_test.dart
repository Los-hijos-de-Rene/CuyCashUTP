import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/home/widgets/account_carousel.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Account _c(String id, AccountType t, Currency m, int c, {String? nombre}) =>
    Account(
      id: id,
      numero: '1910000000${id.hashCode.abs() % 10000}'.padRight(14, '0'),
      tipo: t,
      moneda: m,
      estado: 'activa',
      nombre: nombre,
      saldoDisponible: Money(c, m),
      saldoContable: Money(c, m),
    );

void main() {
  final tres = [
    _c('a', AccountType.ahorro, Currency.pen, 125040),
    _c('b', AccountType.sueldo, Currency.pen, 350000, nombre: 'Planilla'),
    _c('c', AccountType.ahorro, Currency.usd, 12000),
  ];

  testWidgets('muestra la etiqueta y el saldo de la cuenta seleccionada', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 0,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text('Cuenta de ahorros'), findsOneWidget);
    expect(find.text('S/ 1,250.40'), findsOneWidget);
    expect(find.bySemanticsLabel('Cuenta 1 de 3'), findsOneWidget);
  });

  testWidgets('deslizar avisa el índice nuevo', (t) async {
    int? elegido;
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 0,
          onSelected: (i) => elegido = i,
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    expect(elegido, 1);
    expect(find.text('Planilla'), findsOneWidget);
  });

  testWidgets('sin cupo no hay tarjeta de abrir: nada después de la última', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 2,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    expect(find.text(r'US$ 120.00'), findsOneWidget);
    expect(find.text('Abrir otra cuenta'), findsNothing);
    expect(find.bySemanticsLabel('Cuenta 3 de 3'), findsOneWidget);
  });

  testWidgets('con una sola cuenta no hay puntos: no hay a dónde deslizar', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: [tres.first],
          seleccionada: 0,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );

    expect(find.text('S/ 1,250.40'), findsOneWidget);
    expect(find.bySemanticsLabel('Cuenta 1 de 1'), findsNothing);
  });

  testWidgets('el saldo en dólares se pinta en dólares', (t) async {
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 2,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    expect(find.text(r'US$ 120.00'), findsOneWidget);
  });

  testWidgets('un rebuild con la misma selección no devuelve la página', (
    t,
  ) async {
    late StateSetter rebuild;
    var n = 0;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return AccountCarousel(
              cuentas: tres,
              seleccionada: 0,
              onSelected: (_) {},
              onRename: (_) {},
              onOpen: (_) {},
            );
          },
        ),
      ),
    );
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    expect(find.text('Planilla'), findsOneWidget);

    rebuild(() => n++);
    await t.pumpAndSettle();
    expect(find.text('Planilla'), findsOneWidget);
  });

  testWidgets('la tarjeta de saldo no desborda en 360x800', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 1,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (_) {},
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Planilla'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('tocar una tarjeta abre esa cuenta', (t) async {
    Account? abierta;
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 0,
          onSelected: (_) {},
          onRename: (_) {},
          onOpen: (c) => abierta = c,
        ),
      ),
    );
    await t.tap(find.text('S/ 1,250.40'));
    expect(abierta?.id, 'a');
  });

  testWidgets('el lápiz renombra y no abre la cuenta', (t) async {
    Account? abierta;
    Account? renombrada;
    await t.pumpWidget(
      _app(
        AccountCarousel(
          cuentas: tres,
          seleccionada: 0,
          onSelected: (_) {},
          onRename: (c) => renombrada = c,
          onOpen: (c) => abierta = c,
        ),
      ),
    );
    await t.tap(find.byIcon(Icons.edit_outlined).first);
    expect(renombrada?.id, 'a');
    expect(abierta, isNull);
  });

  testWidgets(
    'con cupo, la última página es "Abrir otra cuenta" y no cambia la '
    'seleccionada',
    (t) async {
      final elegidos = <int>[];
      var abrir = 0;
      await t.pumpWidget(
        _app(
          AccountCarousel(
            cuentas: tres,
            seleccionada: 2,
            onSelected: elegidos.add,
            onRename: (_) {},
            onOpen: (_) {},
            onOpenNew: () => abrir++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Cuenta 3 de 4'), findsOneWidget);

      await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await t.pumpAndSettle();
      expect(find.text('Abrir otra cuenta'), findsOneWidget);
      expect(elegidos, isEmpty);

      await t.tap(find.text('Abrir otra cuenta'));
      expect(abrir, 1);
    },
  );
}
