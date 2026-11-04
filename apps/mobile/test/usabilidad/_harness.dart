// APF3 · Utilidades comunes de la suite de usabilidad (capítulo D).
//
// La usabilidad se verifica con `flutter_test`: no mide personas (eso es el
// informe de #104), sino que la interfaz cumpla reglas objetivas de ISO 25010:
// accesibilidad, adaptabilidad y protección contra errores.
//
// Cada pantalla se prueba a tamaño normal y a 320×568, con texto al 100 % y al
// 200 %, y contra las tres guías de accesibilidad de Flutter.
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Teléfono de referencia (390 × 844 lógicos).
const Size pantallaNormal = Size(390, 844);

/// Teléfono pequeño de referencia (320 × 568 lógicos).
const Size pantallaPequena = Size(320, 568);

/// Fija la pantalla lógica de la prueba y la restaura al terminar.
void fijarPantalla(WidgetTester tester, {Size size = pantallaNormal}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// `MaterialApp` con el tema y la localización reales de la app.
///
/// [textScale] simula la preferencia de accesibilidad del sistema (2 = 200 %).
Widget appDePrueba({required Widget home, double textScale = 1}) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

/// Igual que [appDePrueba], pero con el router que usa la pantalla.
Widget appRouterDePrueba({
  required GoRouter router,
  double textScale = 1,
}) => MaterialApp.router(
  routerConfig: router,
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
);

/// UX-A/B/C: las tres guías de accesibilidad de `flutter_test`.
///
/// - áreas táctiles ≥ 48 dp (Material/WCAG)
/// - todo control tocable tiene etiqueta para lectores de pantalla
/// - contraste de texto suficiente (WCAG AA)
Future<void> verificarAccesibilidad(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

/// UX-D/I: la pantalla no debe desbordar ni lanzar excepciones de layout.
void verificarSinDesbordes(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

/// UX-G: el mensaje de error no puede filtrar códigos técnicos.
void verificarSinCodigosTecnicos(String texto) {
  for (final codigo in const [
    'INSUFFICIENT_FUNDS',
    'Exception',
    'Error:',
    'null',
  ]) {
    expect(
      texto.contains(codigo),
      isFalse,
      reason: 'El mensaje de usuario no debe contener "$codigo".',
    );
  }
}
