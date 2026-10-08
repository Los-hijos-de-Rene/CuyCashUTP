import 'dart:async';

import 'package:cuycash/feature/otp/application/otp_actions.dart';
import 'package:cuycash/feature/otp/domain/otp_policy.dart';
import 'package:cuycash/feature/otp/infrastructure/memory_otp_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/otp/bloc/otp_bloc.dart';
import 'package:cuycash/presentation/otp/otp_config.dart';
import 'package:cuycash/presentation/otp/otp_verification_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../feature/otp/memory_otp_repository_test.dart' show TestClock;

void main() {
  late TestClock clock;
  late MemoryOtpRepository repo;

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryOtpRepository(clock: clock.call);
  });

  /// Monta la MISMA pantalla con la configuración que se le pase. Si montar una
  /// configuración nueva exigiera tocar `OtpVerificationScreen`, la abstracción
  /// estaría mal.
  Future<OtpBloc> pumpWith(
    WidgetTester tester,
    OtpConfig Function(AppLocalizations l10n) buildConfig, {
    String? verifiedChallengeId,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = OtpBloc(
      actions: OtpActions(repo),
      identifier: 'juan.perez@gmail.com',
      clock: clock.call,
      ticks: const Stream<void>.empty(),
    )..add(const OtpEvent.started());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => BlocProvider.value(
            value: bloc,
            child: OtpVerificationScreen(
              config: buildConfig(AppLocalizations.of(context)),
              onVerified: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('CP-15 · monta la configuración de recuperación', (tester) async {
    await pumpWith(
        tester, (l10n) => OtpConfig.recuperacion(l10n, 'juan.perez@gmail.com'));

    expect(find.text('Verificar código'), findsOneWidget);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(
      find.text('Enviamos un código de 6 dígitos a j•••••@gmail.com'),
      findsOneWidget,
    );
    // allowChangeEmail: true, notice: null.
    expect(find.text('Cambiar correo'), findsOneWidget);
    expect(find.byType(InfoStrip), findsNothing);
  });

  testWidgets('CP-15 · monta la configuración de dispositivo sin tocar el widget',
      (tester) async {
    await pumpWith(tester, (l10n) => OtpConfig.dispositivo(l10n, '12345678'));

    expect(find.text('Verificar dispositivo'), findsOneWidget);
    expect(find.text('Revisa tu correo'), findsOneWidget);
    // allowChangeEmail: false, con franja informativa.
    expect(find.text('Cambiar correo'), findsNothing);
    expect(find.byType(InfoStrip), findsOneWidget);
    expect(
      find.text('Al verificar, vincularemos este teléfono a tu cuenta.'),
      findsOneWidget,
    );
  });

  testWidgets('CP-05/06 · la línea de spam solo aparece con el reenvío listo',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.dispositivo(l10n, '12345678'));

    // Enfriamiento corriendo: una sola línea, sin spam.
    clock.advance(const Duration(seconds: 59));
    bloc.add(const OtpEvent.ticked());
    await tester.pumpAndSettle();
    expect(find.text('Enviar otro código en 00:01'), findsOneWidget);
    expect(find.text('Revisa tu carpeta de spam.'), findsNothing);

    // Disponible: aparece la leyenda del spam.
    clock.advance(const Duration(seconds: 1));
    bloc.add(const OtpEvent.ticked());
    await tester.pumpAndSettle();
    expect(find.text('Enviar otro código'), findsOneWidget);
    expect(find.text('Revisa tu carpeta de spam.'), findsOneWidget);
  });

  testWidgets('CP-04 · vencido: se va la fila de reenvío y cambia el botón',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.recuperacion(l10n, 'juan.perez@gmail.com'));

    clock.advance(const Duration(seconds: 601));
    bloc.add(const OtpEvent.ticked());
    await tester.pumpAndSettle();

    expect(find.text('Enviar otro código'), findsOneWidget);
    expect(find.text('Verificar'), findsNothing);
    expect(find.textContaining('Enviar otro código en'), findsNothing);
    expect(find.text('Revisa tu carpeta de spam.'), findsNothing);
  });

  testWidgets('CP-01 · las seis casillas se llenan de una sola vez',
      (tester) async {
    var verified = false;
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = OtpBloc(
      actions: OtpActions(repo),
      identifier: 'juan.perez@gmail.com',
      clock: clock.call,
      ticks: const Stream<void>.empty(),
    )..add(const OtpEvent.started());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => BlocProvider.value(
            value: bloc,
            child: OtpVerificationScreen(
              config: OtpConfig.dispositivo(
                  AppLocalizations.of(context), '12345678'),
              onVerified: (_) => verified = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pegar el código completo llena las seis casillas de golpe.
    await tester.enterText(find.byType(TextField), OtpPolicy.validCode);
    await tester.pumpAndSettle();
    expect(bloc.state.codeState, OtpCodeState.complete);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(verified, isTrue);
  });

  // El bloc emite cada segundo (cuenta regresiva del reenvío) y `verified`
  // sigue en true: avisar en cada tic abría DOS sesiones con el mismo ticket
  // (la segunda, 401). Visto en el ingreso con un teléfono nuevo.
  testWidgets('verificado se avisa UNA vez aunque el reloj siga emitiendo',
      (tester) async {
    var avisos = 0;
    final ticks = StreamController<void>();
    addTearDown(ticks.close);
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = OtpBloc(
      actions: OtpActions(repo),
      identifier: 'juan.perez@gmail.com',
      clock: clock.call,
      ticks: ticks.stream,
    )..add(const OtpEvent.started());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => BlocProvider.value(
            value: bloc,
            child: OtpVerificationScreen(
              config: OtpConfig.dispositivo(
                  AppLocalizations.of(context), '12345678'),
              onVerified: (_) => avisos++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), OtpPolicy.validCode);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(avisos, 1);

    // El reloj sigue: tres segundos más en la misma pantalla.
    for (var i = 0; i < 3; i++) {
      clock.advance(const Duration(seconds: 1));
      ticks.add(null);
      await tester.pumpAndSettle();
    }

    expect(avisos, 1);
  });

  testWidgets('el error nombra el flujo que se cancelará: recuperación',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.recuperacion(l10n, 'juan.perez@gmail.com'));

    bloc
      ..add(const OtpEvent.codeChanged('000000'))
      ..add(const OtpEvent.submitted());
    await tester.pumpAndSettle();

    expect(find.text('Código incorrecto. Te quedan 2 intentos.'),
        findsOneWidget);
    expect(find.text('Tras 3 intentos cancelaremos la recuperación.'),
        findsOneWidget);
  });

  testWidgets('el error nombra el flujo que se cancelará: ingreso',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.dispositivo(l10n, '12345678'));

    bloc
      ..add(const OtpEvent.codeChanged('000000'))
      ..add(const OtpEvent.submitted());
    await tester.pumpAndSettle();

    expect(find.text('Tras 3 intentos cancelaremos el ingreso.'),
        findsOneWidget);
  });

  testWidgets('con un solo intento restante el mensaje va en singular',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.dispositivo(l10n, '12345678'));

    for (final code in ['000000', '000001']) {
      bloc
        ..add(OtpEvent.codeChanged(code))
        ..add(const OtpEvent.submitted());
      await tester.pumpAndSettle();
    }

    expect(find.text('Código incorrecto. Te queda 1 intento.'), findsOneWidget);
  });

  testWidgets('al caducar, las casillas quedan vacías y deshabilitadas',
      (tester) async {
    final bloc = await pumpWith(
        tester, (l10n) => OtpConfig.recuperacion(l10n, 'juan.perez@gmail.com'));
    bloc.add(const OtpEvent.codeChanged('4821'));
    await tester.pumpAndSettle();

    clock.advance(const Duration(seconds: 601));
    bloc.add(const OtpEvent.ticked());
    await tester.pumpAndSettle();

    expect(bloc.state.code, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.text('Este código venció. Los códigos duran 10 minutos.'),
        findsOneWidget);
  });
}
