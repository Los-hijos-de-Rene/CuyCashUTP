import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
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
  late MemoryAuthRepository repo;
  late AuthBloc bloc;

  /// Monta el login a tamaño de teléfono real: el rediseño en dos pasos existe
  /// porque los dos campos más el teclado no cabían en 390x844.
  Future<void> pumpLogin(WidgetTester tester,
      {MemoryAuthRepository? repository}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repo = repository ?? MemoryAuthRepository();
    // Teléfono ya vinculado: el login entra directo, sin OTP de dispositivo.
    final store = MemoryDeviceStore();
    await store.saveUser(const RememberedUser(
        dni: '12345678', fullName: 'Juan Pérez', alias: '@juan'));
    bloc = AuthBloc(
      AuthActions(repo),
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
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterDni(WidgetTester tester, [String dni = '12345678']) async {
    await tester.enterText(find.byType(TextField), dni);
    await tester.pumpAndSettle();
  }

  /// Teclea el PIN en el teclado propio, tecla a tecla.
  Future<void> tapPin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.text(digit).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('el paso 1 solo pide el DNI, con el teclado del sistema',
      (tester) async {
    await pumpLogin(tester);

    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(
        find.text('Ingresa tu número de DNI para continuar.'), findsOneWidget);
    // El PIN todavía no existe: ni casillas ni teclado propio.
    expect(find.byType(PinBoxes), findsNothing);
    expect(find.byType(PinKeypad), findsNothing);
    // Sin botón: el octavo dígito avanza.
    expect(find.byType(PrimaryButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el octavo dígito del DNI avanza solo al paso del PIN',
      (tester) async {
    await pumpLogin(tester);

    await enterDni(tester);

    expect(find.text('Ingresa tu PIN'), findsOneWidget);
    expect(find.byType(PinKeypad), findsOneWidget);
    expect(find.byType(PinBoxes), findsOneWidget);
    // El teclado propio entero, el 0 incluido.
    expect(find.text('0'), findsOneWidget);
    // El DNI queda a la vista con su atajo para corregirlo.
    expect(find.text('DNI 12345678'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el sexto dígito del PIN envía solo y autentica', (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tapPin(tester, '000000');

    expect(repo.currentSession, isNotNull);
  });

  testWidgets('mientras se verifica el PIN avisa y apaga el teclado',
      (tester) async {
    final lento = _AuthLento();
    await pumpLogin(tester, repository: lento);
    await enterDni(tester);

    // Los cinco primeros no envían nada: el aviso no debe aparecer antes.
    await tapPin(tester, '00000');
    expect(find.byType(PinSubmittingNotice), findsNothing);

    // El sexto envía. Se avanza un solo frame a propósito: con
    // pumpAndSettle la respuesta ya habría llegado y el estado intermedio
    // —el que el usuario sí ve en una red real— sería invisible aquí.
    await tester.tap(find.text('0').first);
    await tester.pump();

    expect(find.byType(PinSubmittingNotice), findsOneWidget);
    expect(find.text('Verificando tu PIN…'), findsOneWidget);
    // El teclado queda apagado: sin esto el borrado sigue vivo y se puede
    // editar un PIN que ya viaja.
    final teclado = tester.widget<PinKeypad>(find.byType(PinKeypad));
    expect(teclado.enabled, isFalse);

    // Al responder, el aviso desaparece y el teclado vuelve.
    lento.responder();
    await tester.pumpAndSettle();
    expect(find.byType(PinSubmittingNotice), findsNothing);
  });

  testWidgets('el error NO distingue DNI inexistente de PIN equivocado',
      (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tapPin(tester, '999999');

    // Mensaje genérico: decir "PIN incorrecto" confirmaría que ese DNI existe.
    expect(find.text('Los datos no son correctos. Te quedan 2 intentos.'),
        findsOneWidget);
    expect(find.textContaining('PIN incorrecto'), findsNothing);
  });

  testWidgets('con un intento restante el mensaje va en singular',
      (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tapPin(tester, '999999');
    await tapPin(tester, '999998');

    expect(find.text('Los datos no son correctos. Te queda 1 intento.'),
        findsOneWidget);
  });

  testWidgets('"Cambiar" vuelve al paso 1 conservando el DNI', (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    // El DNI sigue escrito: corregir un dígito no cuesta escribirlo entero.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      '12345678',
    );
  });

  testWidgets('la flecha atrás del paso 2 vuelve al paso 1', (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(find.byType(PinKeypad), findsNothing);
  });

  testWidgets('volver a editar el DNI no rebota al paso 2', (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();

    // El campo ya trae 8 dígitos: quedarse en el paso 1 no puede depender de
    // que nadie vuelva a notificar ese mismo texto.
    expect(find.text('Bienvenido de vuelta'), findsOneWidget);

    // Borrar el último dígito deja editar, no salta.
    await enterDni(tester, '1234567');
    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(find.byType(PinKeypad), findsNothing);

    // Y completar el octavo vuelve a avanzar, como en el primer intento.
    await enterDni(tester, '12345679');
    expect(find.text('Ingresa tu PIN'), findsOneWidget);
    expect(find.text('DNI 12345679'), findsOneWidget);
  });

  testWidgets('la flecha atrás tampoco rebota con el DNI completo',
      (tester) async {
    await pumpLogin(tester);
    await enterDni(tester);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    // Un pump extra: es cuando el campo recupera el foco y el teclado
    // reconecta, el momento en que antes se disparaba el salto.
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
  });

  testWidgets('al retomar tras el bloqueo abre en el PIN con el DNI puesto',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = AuthBloc(
      AuthActions(MemoryAuthRepository()),
      DeviceActions(MemoryDeviceStore()),
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
          home: const LoginScreen(initialDni: '12345678'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Esperar el bloqueo ya fue el castigo; reescribir el DNI sería el segundo.
    expect(find.text('Ingresa tu PIN'), findsOneWidget);
    expect(find.text('DNI 12345678'), findsOneWidget);
    expect(find.byType(PinKeypad), findsOneWidget);
  });

  testWidgets('un DNI incompleto al retomar abre en el paso 1', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = AuthBloc(
      AuthActions(MemoryAuthRepository()),
      DeviceActions(MemoryDeviceStore()),
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
          home: const LoginScreen(initialDni: '1234'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido de vuelta'), findsOneWidget);
    expect(find.byType(PinKeypad), findsNothing);
  });
}

/// Repositorio que no responde hasta que la prueba lo decide.
///
/// Con el Memory* normal el estado "verificando" se emite y se sustituye en el
/// mismo microtask, así que ningún frame llega a mostrarlo y la prueba no
/// podría distinguir el aviso presente del ausente. Con red real ese estado
/// dura lo que dure la petición, que es justo lo que se quiere comprobar.
class _AuthLento extends MemoryAuthRepository {
  final _esperando = Completer<void>();

  void responder() => _esperando.complete();

  @override
  FutureResult<AuthFailure, AuthSession> authenticate({
    required String identifier,
    required String pin,
  }) async {
    await _esperando.future;
    return super.authenticate(identifier: identifier, pin: pin);
  }
}
