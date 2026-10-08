import 'dart:convert';

import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/kyc/application/kyc_actions.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/kyc/widgets/camera_scope.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_face_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'register_test_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterBloc bloc;

  Future<void> pumpStep(WidgetTester tester, {required bool active}) async {
    bloc = RegisterBloc(AuthActions(MemoryAuthRepository()), biometric: biometricParaTests(), kyc: kycParaTests());
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<KycActions>.value(
              value: KycActions(MemoryKycRepository(clock: DateTime.now))),
          // El paso consulta el flavor para decidir si ofrece la salida sin
          // cámara, igual que en la app.
          RepositoryProvider<AppFlavor>.value(value: AppFlavor.local),
        ],
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: CuyCashTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RegisterFaceStep(active: active)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void capturarDni() =>
      bloc.add(RegisterEvent.captured(DocSide.front, _jpegMinimo));

  testWidgets('sin el frente del DNI no se abre la cámara, se avisa',
      (tester) async {
    await pumpStep(tester, active: true);

    // Es la imagen contra la que se compara el rostro: sin ella no hay nada
    // que verificar.
    expect(find.byType(CameraScope), findsNothing);
    expect(
      find.textContaining('captura el frente de tu DNI'),
      findsOneWidget,
    );
  });

  testWidgets('con el DNI capturado y el paso activo, se abre la cámara',
      (tester) async {
    await pumpStep(tester, active: true);

    capturarDni();
    // Dos pumps: uno para que el bloc emita y otro para reconstruir.
    await tester.pump();
    await tester.pump();

    expect(find.byType(CameraScope), findsOneWidget);
  });

  testWidgets('fuera de foco NO se toca la cámara aunque haya DNI',
      (tester) async {
    // El wizard usa IndexedStack y monta todos los pasos a la vez: sin esta
    // condición, la cámara frontal se abriría con el usuario todavía en el
    // paso 2 y chocaría con la trasera al fotografiar el reverso.
    await pumpStep(tester, active: false);

    capturarDni();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CameraScope), findsNothing);
  });
}

/// JPEG 1x1 real, para que la tarjeta pueda decodificarlo.
final _jpegMinimo = base64Decode(
  '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a'
  'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAA'
  'AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==',
);
