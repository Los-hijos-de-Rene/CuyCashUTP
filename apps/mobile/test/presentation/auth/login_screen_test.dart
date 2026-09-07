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
  testWidgets('ingresar con credenciales válidas autentica', (tester) async {
    // Vista amplia: el botón "Ingresar" queda fuera del frame por defecto
    // (800x600) y el tap no lo alcanzaría.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // El bloc se crea dentro de testWidgets (zone de FakeAsync) para que el
    // evento del tap se procese durante pumpAndSettle.
    final repo = MemoryAuthRepository();
    final bloc = AuthBloc(AuthActions(repo));
    addTearDown(bloc.close);

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
    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.pumpAndSettle(); // habilita "Ingresar" (DNI 8 + PIN 6)
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNotNull);
  });
}
