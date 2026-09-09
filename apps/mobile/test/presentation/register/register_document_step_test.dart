import 'dart:convert';
import 'dart:typed_data';

import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/kyc/document_capture_page.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_document_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// El flavor viaja por el árbol igual que en la app: la pantalla de captura lo
/// consulta para decidir si ofrece la salida sin cámara.
Widget _wrap(RegisterBloc bloc, {AppFlavor flavor = AppFlavor.local}) =>
    RepositoryProvider<AppFlavor>.value(
      value: flavor,
      child: BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RegisterDocumentStep()),
        ),
      ),
    );

void main() {
  late RegisterBloc bloc;

  Future<void> pumpStep(
    WidgetTester tester, {
    AppFlavor flavor = AppFlavor.local,
  }) async {
    // La card tiene AspectRatio 16/10 que al ancho de test (800px) genera ~500px
    // de alto; el botón queda fuera del frame por defecto (600px). Se amplía el
    // frame para que el primer SecondaryButton quede completamente visible.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bloc = RegisterBloc(AuthActions(MemoryAuthRepository()));
    addTearDown(bloc.close);
    await tester.pumpWidget(_wrap(bloc, flavor: flavor));
    await tester.pumpAndSettle();
  }

  testWidgets('"Tomar foto" abre la cámara, ya no simula la captura', (
    tester,
  ) async {
    await pumpStep(tester);
    expect(find.text('0 de 2 capturas'), findsOneWidget);

    await tester.tap(find.byType(SecondaryButton).first);
    // Sin `pumpAndSettle`: la pantalla de captura muestra un spinner mientras
    // espera a la cámara, que en el entorno de test nunca llega, y esperar a
    // que todo se asiente colgaría el test.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Lo que importa es que se navegó a capturar en vez de dar la foto por
    // hecha.
    expect(find.byType(DocumentCapturePage), findsOneWidget);
    expect(bloc.state.draft.dniFront, CaptureStatus.empty);
  });

  testWidgets('la captura marca el lado y CONSERVA los bytes', (tester) async {
    await pumpStep(tester);

    // Los bytes son los que después se mandan a verificar: si el evento solo
    // marcara el estado, el paso 3 se quedaría sin documento que comparar.
    bloc.add(
      RegisterEvent.captured(
        DocSide.front,
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
      ),
    );
    await tester.pumpAndSettle();

    expect(bloc.state.draft.dniFront, CaptureStatus.captured);
    expect(bloc.state.draft.dniFrontImage, isNotNull);
    expect(find.text('Capturado'), findsOneWidget);
    expect(find.text('1 de 2 capturas'), findsOneWidget);
  });

  testWidgets('la foto tomada se muestra, no solo un sello de capturado',
      (tester) async {
    await pumpStep(tester);
    expect(find.byType(Image), findsNothing);

    bloc.add(RegisterEvent.captured(DocSide.front, _jpegMinimo));
    await tester.pumpAndSettle();

    // Verla es lo que permite repetirla antes de que el servicio la rechace
    // por borrosa o mal encuadrada.
    expect(find.byType(Image), findsOneWidget);
    // El reverso sigue sin foto: cada lado muestra la suya.
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Volver a tomar'), findsOneWidget);
  });
}

/// JPEG 1x1 real, para que `Image.memory` pueda decodificarlo.
final _jpegMinimo = base64Decode(
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a'
  'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAA'
  'AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
);
