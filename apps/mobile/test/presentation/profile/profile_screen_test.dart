import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/profile/profile_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    bloc = AuthBloc(AuthActions(repo));
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('muestra el identificador y cerrar sesión dispara signOut',
      (tester) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12345678'), findsOneWidget);

    await tester.tap(find.byType(SecondaryButton));
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNull);
  });
}
