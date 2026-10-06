import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/profile/application/profile_actions.dart';
import 'package:cuycash/feature/profile/domain/personal_data.dart';
import 'package:cuycash/feature/profile/domain/profile_failure.dart';
import 'package:cuycash/feature/profile/domain/profile_repository.dart';
import 'package:cuycash/feature/profile/infrastructure/memory_profile_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/profile/alias/bloc/edit_alias_bloc.dart';
import 'package:cuycash/presentation/profile/alias/edit_alias_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

class _SinRed implements ProfileRepository {
  @override
  FutureResult<ProfileFailure, PersonalData> me() async =>
      right(MemoryProfileRepository.demo);

  @override
  FutureResult<ProfileFailure, String> updateAlias(String alias) async =>
      left(const GlobalFailure.server(ProfileFailure.network()));
}

void main() {
  late DeviceActions device;
  bool? resultado;

  setUp(() async {
    device = DeviceActions(MemoryDeviceStore());
    await device.saveUser(const RememberedUser(
        dni: '70123456', fullName: 'Jheampierre Ruiz', alias: '@jheampierre'));
    resultado = null;
  });

  Future<void> abrir(WidgetTester tester, ProfileRepository repo) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => TextButton(
          onPressed: () async =>
              resultado = await context.push<bool>('/alias'),
          child: const Text('ABRIR'),
        ),
      ),
      GoRoute(
        path: '/alias',
        builder: (_, _) => BlocProvider(
          create: (_) => EditAliasBloc(
            profile: ProfileActions(repo),
            device: device,
            initial: '@jheampierre',
          ),
          child: const EditAliasScreen(),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      routerConfig: router,
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
  }

  Finder guardar() => find.widgetWithText(ElevatedButton, 'Guardar');

  testWidgets('sin cambios o con formato inválido no deja guardar',
      (tester) async {
    await abrir(tester, MemoryProfileRepository());
    expect(tester.widget<ElevatedButton>(guardar()).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'ñandú');
    await tester.pump();
    expect(
        find.text(
            'Usa de 3 a 20 letras sin tildes, números, punto o guion bajo.'),
        findsOneWidget);
    expect(tester.widget<ElevatedButton>(guardar()).onPressed, isNull);
  });

  testWidgets('guardar actualiza el usuario recordado y vuelve con true',
      (tester) async {
    await abrir(tester, MemoryProfileRepository());

    await tester.enterText(find.byType(TextField), 'Jheam_01');
    await tester.pump();
    await tester.tap(guardar());
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
    expect((await device.readUser())?.alias, '@jheam_01');
  });

  testWidgets('sin red avisa y se queda', (tester) async {
    await abrir(tester, _SinRed());

    await tester.enterText(find.byType(TextField), 'otro_alias');
    await tester.pump();
    await tester.tap(guardar());
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos guardar tu alias'), findsOneWidget);
    expect(resultado, isNull);
    expect((await device.readUser())?.alias, '@jheampierre');
  });
}
