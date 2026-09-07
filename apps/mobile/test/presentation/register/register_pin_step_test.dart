import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_pin_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tipear un PIN válido marca las reglas y actualiza el draft',
      (tester) async {
    // Ampliar el frame para que el contenido del ListView sea visible
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()));
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RegisterPinStep()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '024689');
    await tester.pumpAndSettle();
    expect(bloc.state.draft.pin, '024689');
    // dos íconos check_circle (6 dígitos + sin secuencia)
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });
}
