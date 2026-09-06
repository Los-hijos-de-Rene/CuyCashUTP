import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/auth/login_screen.dart';
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
    repo = MemoryAuthRepository();
    bloc = AuthBloc(AuthActions(repo));
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('ingresar con credenciales válidas autentica', (tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12345678');
    await tester.enterText(find.byType(TextField).last, '0000');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNotNull);
  });
}
