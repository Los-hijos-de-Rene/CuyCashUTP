import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/profile/application/profile_actions.dart';
import 'package:cuycash/feature/profile/domain/personal_data.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/personal_data/bloc/personal_data_bloc.dart';
import 'package:cuycash/presentation/profile/personal_data/personal_data_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _Controlado implements ProfileRepository {
  final pendiente = Completer<Result<ProfileFailure, PersonalData>>();
  int llamadas = 0;

  @override
  FutureResult<ProfileFailure, PersonalData> me() {
    llamadas++;
    return pendiente.future;
  }

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async =>
      right(alias);
}

Widget _app(ProfileRepository repo) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BlocProvider(
    create: (_) =>
        PersonalDataBloc(ProfileActions(repo))
          ..add(const PersonalDataEvent.started()),
    child: const PersonalDataScreen(),
  ),
);

void main() {
  testWidgets('mientras carga muestra la silueta', (tester) async {
    final repo = _Controlado();
    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.byType(SkeletonBox), findsWidgets);
    repo.pendiente.complete(right(MemoryProfileRepository.demo));
    await tester.pumpAndSettle();
  });

  testWidgets('con KYC sin confirmar no afirma nada sobre la verificación', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MemoryProfileRepository(
          initial: MemoryProfileRepository.demo.copyWith(kycVerified: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Identidad verificada'), findsNothing);
    expect(find.textContaining('pendiente'), findsNothing);
  });

  testWidgets('muestra los datos y el sello de verificación', (tester) async {
    // El sello solo sale con el KYC confirmado; la demo, como el backend
    // real hoy, lo tiene pendiente (R7).
    await tester.pumpWidget(
      _app(
        MemoryProfileRepository(
          initial: MemoryProfileRepository.demo.copyWith(kycVerified: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jheampierre'), findsOneWidget);
    expect(find.text('Ruiz Salas'), findsOneWidget);
    expect(find.text('70123456'), findsOneWidget);
    expect(find.text('j•••••@correo.pe'), findsOneWidget);
    expect(find.text('@jheampierre'), findsOneWidget);
    expect(find.text('Identidad verificada'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('un error ofrece reintentar y vuelve a pedir', (tester) async {
    final repo = _Controlado();
    await tester.pumpWidget(_app(repo));
    repo.pendiente.complete(
      left(const GlobalFailure.server(ProfileFailure.network())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus datos.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repo.llamadas, 2);
  });
}
