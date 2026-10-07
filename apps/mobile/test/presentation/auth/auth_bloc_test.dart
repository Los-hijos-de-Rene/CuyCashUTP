import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/lockout/application/identifier_lockout_actions.dart';
import 'package:cuycash/feature/lockout/infrastructure/memory_identifier_lockout_store.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Por defecto el teléfono YA está vinculado al 12345678: así el login
/// entra directo y estos tests siguen midiendo solo la parte de auth.
AuthBloc buildBloc(MemoryAuthRepository repo, {MemoryDeviceStore? store}) {
  final device = store ?? MemoryDeviceStore();
  if (store == null) {
    device.saveUser(const RememberedUser(
        dni: '12345678', fullName: 'Juan Pérez', alias: '@juan'));
  }
  return AuthBloc(
    AuthActions(repo),
    DeviceActions(device),
    IdentifierLockoutActions(MemoryIdentifierLockoutStore()),
  );
}

void main() {
  const session = AuthSession(userId: 'u', identifier: '12345678');

  test(
    'verificar el dispositivo sin nombre en la sesión NO guarda el DNI como '
    'nombre',
    () async {
      final store = MemoryDeviceStore();
      final bloc = buildBloc(MemoryAuthRepository(), store: store);
      addTearDown(bloc.close);

      bloc.add(const AuthEvent.deviceVerified(session, 'ticket'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final guardado = await store.readUser();
      expect(guardado?.dni, '12345678');
      expect(guardado?.fullName, isNot('12345678'));
      expect(guardado?.fullName, '');
    },
  );

  test('estado inicial sin sesión → AuthUnauthenticated', () {
    final bloc = buildBloc(MemoryAuthRepository());
    expect(bloc.state, isA<AuthUnauthenticated>());
    bloc.close();
  });

  test('estado inicial con sesión → AuthAuthenticated', () {
    final bloc = buildBloc(MemoryAuthRepository(initial: session));
    expect(bloc.state, isA<AuthAuthenticated>());
    bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'login correcto → submitting, luego AuthAuthenticated (vía stream)',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc.add(
        const AuthEvent.loginSubmitted(identifier: '12345678', pin: '000000')),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>(), isA<AuthAuthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'login incorrecto → submitting, luego error (sigue Unauthenticated)',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc.add(
        const AuthEvent.loginSubmitted(identifier: '12345678', pin: '9999')),
    expect: () => [
      isA<AuthUnauthenticated>(),
      isA<AuthUnauthenticated>()
          .having((s) => s.error, 'error', AuthError.invalidCredentials),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'signOut → AuthUnauthenticated',
    build: () => buildBloc(MemoryAuthRepository(initial: session)),
    act: (bloc) => bloc.add(const AuthEvent.signedOut()),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>()],
  );

  group('bloqueo por DNI tras 3 PIN fallidos', () {
    final t0 = DateTime(2026, 3, 1, 10);
    late MemoryIdentifierLockoutStore lockouts;

    AuthBloc buildForLockout() {
      final device = MemoryDeviceStore()
        ..saveUser(const RememberedUser(
            dni: '12345678', fullName: 'Juan Pérez', alias: '@juan'));
      return AuthBloc(
        AuthActions(MemoryAuthRepository()),
        DeviceActions(device),
        IdentifierLockoutActions(lockouts),
        clock: () => t0,
      );
    }

    setUp(() => lockouts = MemoryIdentifierLockoutStore());

    Future<void> failLogin(AuthBloc bloc, {String dni = '12345678'}) async {
      bloc.add(AuthEvent.loginSubmitted(identifier: dni, pin: '999999'));
      await Future<void>.delayed(Duration.zero);
    }

    test('cada PIN fallido descuenta un intento', () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);

      await failLogin(bloc);

      final state = bloc.state as AuthUnauthenticated;
      expect(state.error, AuthError.invalidCredentials);
      expect(state.attemptsLeft, 2);
      expect(state.lockedUntil, isNull);
    });

    test('el tercer fallo bloquea y expone lockedUntil', () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);

      for (var i = 0; i < 3; i++) {
        await failLogin(bloc);
      }

      final state = bloc.state as AuthUnauthenticated;
      expect(state.lockedUntil, t0.add(const Duration(minutes: 15)));
    });

    test('el bloqueo es del DNI: no deja entrar ni con el PIN correcto',
        () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);
      for (var i = 0; i < 3; i++) {
        await failLogin(bloc);
      }

      bloc.add(const AuthEvent.loginSubmitted(
          identifier: '12345678', pin: '000000'));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as AuthUnauthenticated).lockedUntil, isNotNull);
    });

    test('el bloqueo viaja con el DNI, no con el teléfono', () async {
      final phone1 = buildForLockout();
      addTearDown(phone1.close);
      for (var i = 0; i < 3; i++) {
        await failLogin(phone1);
      }

      // Otro teléfono (device store limpio) contra el MISMO DNI: sigue
      // bloqueado. Si el contador viviera en el dispositivo, aquí entraría.
      final phone2 = AuthBloc(
        AuthActions(MemoryAuthRepository()),
        DeviceActions(MemoryDeviceStore()),
        IdentifierLockoutActions(lockouts),
        clock: () => t0,
      );
      addTearDown(phone2.close);
      phone2.add(const AuthEvent.loginSubmitted(
          identifier: '12345678', pin: '000000'));
      await Future<void>.delayed(Duration.zero);

      expect((phone2.state as AuthUnauthenticated).lockedUntil, isNotNull);
    });

    test('bloquear un DNI no bloquea a otro', () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);
      for (var i = 0; i < 3; i++) {
        await failLogin(bloc);
      }

      await failLogin(bloc, dni: '87654321');

      final state = bloc.state as AuthUnauthenticated;
      expect(state.lockedUntil, isNull);
      expect(state.attemptsLeft, 2);
    });

    test('un login correcto limpia los intentos de ese DNI', () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);
      await failLogin(bloc);

      bloc.add(const AuthEvent.loginSubmitted(
          identifier: '12345678', pin: '000000'));
      await Future<void>.delayed(Duration.zero);

      expect((await lockouts.read('12345678')).failedAttempts, 0);
    });

    test('el aviso escala: 15 min, luego 1 h, luego 24 h', () async {
      final bloc = buildForLockout();
      addTearDown(bloc.close);

      // Primer ciclo: aún sin bloqueos previos.
      await failLogin(bloc);
      expect((bloc.state as AuthUnauthenticated).nextLockout,
          const Duration(minutes: 15));

      // Se consuma el primer bloqueo y se deja vencer.
      await failLogin(bloc);
      await failLogin(bloc);
      await lockouts.save(
          '12345678',
          (await lockouts.read('12345678'))
              .copyWith(lockedUntil: t0.subtract(const Duration(seconds: 1))));

      await failLogin(bloc);
      expect((bloc.state as AuthUnauthenticated).nextLockout,
          const Duration(hours: 1),
          reason: 'con un bloqueo previo el siguiente es de 1 hora');

      // Segundo bloqueo consumado y vencido → el tope de 24 h.
      await failLogin(bloc);
      await failLogin(bloc);
      await lockouts.save(
          '12345678',
          (await lockouts.read('12345678'))
              .copyWith(lockedUntil: t0.subtract(const Duration(seconds: 1))));

      await failLogin(bloc);
      expect((bloc.state as AuthUnauthenticated).nextLockout,
          const Duration(hours: 24));
    });
  });
}
