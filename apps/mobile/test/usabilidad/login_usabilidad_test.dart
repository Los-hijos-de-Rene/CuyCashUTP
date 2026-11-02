// APF3 · Usabilidad (ISO/IEC 25010 · capacidad de aprendizaje, accesibilidad,
// protección contra errores del usuario). Modelo para las demás pantallas:
// ver docs/apf3/spec-jheampierre-usabilidad-ui.md.
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/auth/login_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryDeviceStore();
    await store.saveUser(
      const RememberedUser(
        dni: '12345678',
        fullName: 'Juan Pérez',
        alias: '@juan',
      ),
    );
    final bloc = AuthBloc(
      AuthActions(MemoryAuthRepository()),
      DeviceActions(store),
      IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('UX-LOGIN · accesibilidad (WCAG vía flutter_test)', () {
    testWidgets('UX-01 áreas táctiles de al menos 48 dp (Android)', (t) async {
      final handle = t.ensureSemantics();
      await pumpLogin(t);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('UX-02 todo control tocable tiene etiqueta', (t) async {
      final handle = t.ensureSemantics();
      await pumpLogin(t);
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('UX-03 contraste de texto suficiente', (t) async {
      final handle = t.ensureSemantics();
      await pumpLogin(t);
      await expectLater(t, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('UX-LOGIN · adaptabilidad', () {
    testWidgets('UX-04 con texto al 200 % no hay desbordes', (t) async {
      await pumpLogin(t, textScale: 2);
      expect(t.takeException(), isNull);
    });
  });
}
