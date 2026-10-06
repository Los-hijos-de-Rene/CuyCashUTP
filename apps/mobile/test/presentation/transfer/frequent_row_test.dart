import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary.dart';
import 'package:cuycash/feature/transfer/domain/recipient_account.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/transfer/widgets/frequent_row.dart';
import 'package:cuycash/presentation/transfer/widgets/recipient_account_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

const _ahorro = RecipientAccount(
  cuentaId: 'a1',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  numeroMasked: '••••7732',
);
const _sueldo = RecipientAccount(
  cuentaId: 'a2',
  tipo: AccountType.sueldo,
  moneda: Currency.pen,
  numeroMasked: '••••8800',
);

void main() {
  testWidgets('dos frecuentes de la misma persona se distinguen por cuenta', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        FrequentRow(
          beneficiarios: const [
            Beneficiary(
              id: 'b1',
              dni: '87654321',
              apodo: 'J*** M***',
              cuenta: _ahorro,
            ),
            Beneficiary(
              id: 'b2',
              dni: '87654321',
              apodo: 'J*** M***',
              cuenta: _sueldo,
            ),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.text('Ahorros · ••••7732'), findsOneWidget);
    expect(find.text('Sueldo · ••••8800'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Enviar a J\*\*\* M\*\*\*, Ahorros · ••••7732'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('la tarjeta apagada dice por qué en vez de "Enviar a"', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const RecipientAccountCard(
          cuenta: _ahorro,
          titulo: 'Ahorros · S/ · ••••7732',
          motivoDeshabilitada: 'Solo recibe US\$',
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp(r'Solo recibe US\$')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Enviar a')), findsNothing);
    handle.dispose();
  });
}
