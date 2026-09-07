import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_data_step.dart';
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
        home: const Scaffold(body: RegisterDataStep()),
      ),
    );

void main() {
  testWidgets('muestra el encabezado y los 4 campos', (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()));
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    await tester.pumpAndSettle();
    expect(find.text('Empecemos por ti'), findsOneWidget);
    expect(find.byType(CuyCashTextField), findsNWidgets(4));
  });

  testWidgets('avanzar con datos inválidos muestra el banner y errores',
      (tester) async {
    final bloc = RegisterBloc(AuthActions(MemoryAuthRepository()));
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc));
    bloc.add(const RegisterEvent.stepAdvanced());
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa'), findsOneWidget);
    expect(find.text('El DNI debe tener 8 dígitos numéricos.'), findsOneWidget);
  });
}
