import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/home/home_screen.dart';
import 'package:cuycash/presentation/home/widgets/balance_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Igual que en el perfil: el bloc se crea fuera de testWidgets para que su
  // suscripción al broadcast del repo no quede pendiente dentro de FakeAsync.
  late AuthBloc bloc;
  late DeviceActions device;

  setUp(() async {
    bloc = AuthBloc(
      AuthActions(MemoryAuthRepository(
        initial: const AuthSession(userId: 'u', identifier: '12345678'),
      )),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(const RememberedUser(
      dni: '12345678',
      fullName: 'Jheampierre Ruiz Salas',
      alias: '@jheampierre',
    ));
  });

  tearDown(() async {
    await bloc.close();
  });

  Widget wrap() => RepositoryProvider<DeviceActions>.value(
        value: device,
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );

  testWidgets('saluda por el nombre del usuario recordado', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Jheampierre'), findsOneWidget);
    expect(find.text('Datos de demostración'), findsOneWidget);
  });

  testWidgets('el ojo oculta y vuelve a mostrar el saldo', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BalanceCard),
        matching: find.byIcon(Icons.visibility),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S/ 1,250.40'), findsNothing);
    expect(find.text('S/ ••••••'), findsOneWidget);
  });

  testWidgets('las acciones sin feature avisan en vez de callar',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pump();

    expect(find.text('Disponible en una próxima versión.'), findsOneWidget);
  });
}
