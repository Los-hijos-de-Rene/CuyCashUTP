import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_document_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(RegisterBloc bloc) => BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RegisterDocumentStep()),
      ),
    );

void main() {
  testWidgets('tomar foto marca capturado', (tester) async {
    // La card tiene AspectRatio 16/10 que al ancho de test (800px) genera ~500px
    // de alto; el botón queda fuera del frame por defecto (600px). Se amplía el
    // frame para que el primer SecondaryButton quede completamente visible.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()));
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text('0 de 2 capturas'), findsOneWidget);
    await tester.tap(find.byType(SecondaryButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Capturado'), findsOneWidget);
    expect(find.text('1 de 2 capturas'), findsOneWidget);
  });
}
