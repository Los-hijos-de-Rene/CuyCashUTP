import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/profile/profile_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // El bloc se crea fuera de testWidgets para que su StreamSubscription
  // al broadcast de MemoryAuthRepository viva en el zone real (no en FakeAsync).
  // Si se creara dentro de testWidgets, FakeAsync lo vería como async pendiente
  // e impediría que pump() se resuelva.
  late MemoryAuthRepository repo;
  late AuthBloc bloc;

  setUp(() {
    repo = MemoryAuthRepository(
      initial: const AuthSession(userId: 'u', identifier: '12345678'),
    );
    bloc = AuthBloc(
      AuthActions(repo),
      DeviceActions(MemoryDeviceStore()),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('muestra el identificador y cerrar sesión abre diálogo y signOut',
      (tester) async {
    final device = DeviceActions(MemoryDeviceStore());

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DeviceActions>.value(value: device),
        ],
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12345678'), findsOneWidget);

    // Tocar "Cerrar sesión" abre el diálogo de confirmación
    await tester.tap(find.byType(SecondaryButton));
    await tester.pumpAndSettle();

    // El diálogo debe ser visible; confirmar con el botón primary del diálogo
    expect(find.byType(Dialog), findsOneWidget);

    // Tap the confirm button (PrimaryButton inside the dialog)
    final primaryButtons = find.byType(PrimaryButton);
    await tester.tap(primaryButtons.first);
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNull);
  });
}
