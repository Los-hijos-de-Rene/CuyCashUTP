import 'package:cuycash/feature/dev_tools/application/dev_tools_actions.dart';
import 'package:cuycash/feature/dev_tools/domain/dev_tools_repository.dart';
import 'package:cuycash/feature/dev_tools/infrastructure/memory_dev_tools_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/dev_tools/dev_tools_overlay.dart';
import 'package:cuycash/presentation/dev_tools/dev_tools_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryDevToolsRepository repo;
  late int limpiezas;

  setUp(() {
    repo = MemoryDevToolsRepository(
      otps: const [
        DevOtp(destination: 'ana@prueba.local', code: '482167', purpose: 'device'),
      ],
    );
    limpiezas = 0;
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DevToolsSheet(
          actions: DevToolsActions(repo),
          onReset: () async => limpiezas++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('reiniciar pide confirmar, siembra y limpia el teléfono',
      (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Reiniciar todo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, reiniciar'));
    await tester.pumpAndSettle();

    expect(repo.resets, 1);
    expect(limpiezas, 1);
    expect(find.textContaining('PIN 258036'), findsOneWidget);
    expect(find.textContaining('@ana'), findsOneWidget);
  });

  testWidgets('cancelar no reinicia nada', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Reiniciar todo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.resets, 0);
    expect(limpiezas, 0);
  });

  testWidgets('crear usuarios no limpia la sesión', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Crear usuarios de prueba'));
    await tester.pumpAndSettle();

    expect(repo.seeds, 1);
    expect(limpiezas, 0);
    expect(find.textContaining('@luis'), findsOneWidget);
  });

  testWidgets('muestra el último código OTP', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Ver últimos códigos OTP'));
    await tester.pumpAndSettle();

    expect(find.textContaining('482167'), findsOneWidget);
  });

  testWidgets('sin backend de desarrollo, lo explica y no limpia nada',
      (tester) async {
    repo.failure = const DevToolsFailure.unavailable();
    await pumpSheet(tester);

    await tester.tap(find.text('Reiniciar todo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, reiniciar'));
    await tester.pumpAndSettle();

    expect(limpiezas, 0);
    expect(find.textContaining('DEV_TOOLS'), findsOneWidget);
  });

  testWidgets('el botón DEV abre el menú', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => DevToolsOverlay(
        actions: DevToolsActions(repo),
        navigatorKey: navigatorKey,
        onReset: () async {},
        child: child!,
      ),
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DEV'));
    await tester.pumpAndSettle();

    expect(find.text('Menú de desarrollo (solo local)'), findsOneWidget);
  });
}
