import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/home/widgets/movements_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Movement _mov(MovementKind tipo, String contraparte) => Movement(
  transactionId: 'tx-$contraparte',
  tipo: tipo,
  direccion: MovementDirection.credito,
  monto: const Money.soles(1000),
  contraparte: contraparte,
  saldoPosterior: const Money.soles(1000),
  fecha: DateTime.utc(2026, 10, 6, 15),
);

void main() {
  testWidgets(
    'el nombre de quien envió (guardado en minúsculas) se muestra con '
    'mayúscula en cada palabra; la recarga queda como está',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MovementsCard(
              movements: [
                _mov(MovementKind.transferencia, 'jenny marisol ruiz'),
                _mov(MovementKind.transferencia, 'L*** A*** Q***'),
                _mov(MovementKind.recarga, 'Recarga de saldo'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Jenny Marisol Ruiz'), findsOneWidget);
      expect(find.text('L*** A*** Q***'), findsOneWidget);
      expect(find.text('Recarga de saldo'), findsOneWidget);
    },
  );
}
