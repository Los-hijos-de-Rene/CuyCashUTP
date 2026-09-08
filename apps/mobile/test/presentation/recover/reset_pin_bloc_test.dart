import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/app/app_redirect.dart';
import 'package:cuycash/presentation/app/app_routes.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/recover/bloc/reset_pin_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// PIN actual de la cuenta simulada.
  const currentPin = '482913';
  const email = 'juan.perez@gmail.com';

  late MemoryAuthRepository repo;
  late ResetPinBloc bloc;

  setUp(() {
    repo = MemoryAuthRepository(
      validPin: currentPin,
      otherDeviceTokens: const ['tablet-1', 'phone-2'],
    );
    bloc = ResetPinBloc(actions: AuthActions(repo), identifier: email);
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Teclea dígito a dígito, como el teclado propio.
  Future<void> type(String digits) async {
    for (final digit in digits.split('')) {
      bloc.add(ResetPinEvent.digitPressed(int.parse(digit)));
      await settle();
    }
  }

  test('el sexto dígito del paso 1 avanza solo: no hay botón', () async {
    await type('314159');

    expect(bloc.state.step, ResetPinStep.confirmar);
    expect(bloc.state.chosenPin, '314159');
    // Una sola fila visible: las casillas del paso 2 arrancan vacías.
    expect(bloc.state.pin, isEmpty);
  });

  test('CP-12 · el PIN actual se rechaza al cerrar el PASO 1', () async {
    await type(currentPin);

    expect(bloc.state.error, ResetPinError.samePin);
    // No se avanza: escribir seis dígitos más para que luego lo rechacen sería
    // hacerle perder el tiempo al usuario.
    expect(bloc.state.step, ResetPinStep.crear);
    expect(bloc.state.pin, isEmpty);
    expect(repo.validPin, currentPin);
  });

  test('CP-11 · la confirmación distinta limpia SOLO el paso 2', () async {
    await type('314159');
    await type('222222');

    expect(bloc.state.error, ResetPinError.mismatch);
    expect(bloc.state.step, ResetPinStep.confirmar);
    expect(bloc.state.pin, isEmpty);
    // El PIN elegido NUNCA se pierde.
    expect(bloc.state.chosenPin, '314159');
  });

  test('CP-13 · confirmar guarda e invalida los otros dispositivos', () async {
    await type('314159');
    await type('314159');

    expect(bloc.state.done, isTrue);
    expect(repo.validPin, '314159');
    expect(repo.otherDeviceTokens, isEmpty);
  });

  test('CP-14 · restablecer NO crea sesión: /home sigue exigiendo auth',
      () async {
    await type('314159');
    await type('314159');

    expect(repo.currentSession, isNull);
    expect(
      appRedirect(const AuthState.unauthenticated(), AppRoutes.home),
      AppRoutes.onboarding,
    );
  });

  test('el PIN nuevo sí sirve para entrar después', () async {
    await type('314159');
    await type('314159');

    final signedIn =
        await repo.signIn(identifier: '12345678', pin: '314159');

    expect(signedIn.isRight(), isTrue);
  });

  test('el retroceso borra el último dígito del paso activo', () async {
    await type('3141');
    bloc.add(const ResetPinEvent.backspace());
    await settle();

    expect(bloc.state.pin, '314');
    expect(bloc.state.step, ResetPinStep.crear);
  });

  test('volver del paso 2 deja ambas filas vacías', () async {
    await type('314159');
    await type('22');

    bloc.add(const ResetPinEvent.backToFirstStep());
    await settle();

    expect(bloc.state.step, ResetPinStep.crear);
    expect(bloc.state.pin, isEmpty);
    expect(bloc.state.chosenPin, isEmpty);
  });

  test('en el paso 1 volver atrás no hace nada', () async {
    await type('314');

    bloc.add(const ResetPinEvent.backToFirstStep());
    await settle();

    expect(bloc.state.step, ResetPinStep.crear);
    expect(bloc.state.pin, '314');
  });

  test('un séptimo dígito no desborda las casillas', () async {
    await type('314159');
    await type('222222');
    // Con el error en pantalla las casillas ya están vacías; se puede reescribir.
    await type('314159');

    expect(bloc.state.done, isTrue);
  });
}
