import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/feature/profile/domain/alias_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signIn con PIN válido (6) → sesión y la emite', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);
    final result = await repo.signIn(identifier: '12345678', pin: '000000');
    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isA<AuthSession>());
  });

  test(
    'signInWithBiometric acepta la credencial vigente de este teléfono',
    () async {
      final estado = MemorySecurityState.demo(clock: DateTime.now);
      estado.credentials['ok'] = estado.thisDeviceId;
      final repo = MemoryAuthRepository(security: estado);

      final bien = await repo.signInWithBiometric(
        dni: estado.dni,
        credential: 'ok',
      );
      final mal = await repo.signInWithBiometric(
        dni: estado.dni,
        credential: 'x',
      );

      expect(bien.isRight(), isTrue);
      expect(repo.currentSession?.identifier, estado.dni);
      expect(switch (mal.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      }, isA<BiometricRevoked>());
    },
  );

  test(
    'la huella sirve para el DNI que abrió sesión, no solo el de la demo',
    () async {
      final estado = MemorySecurityState.demo(clock: DateTime.now);
      final repo = MemoryAuthRepository(security: estado);
      final seguridad = MemorySecurityRepository(estado, clock: DateTime.now);
      const otroDni = '45678912';

      await repo.signIn(identifier: otroDni, pin: '000000');
      final credencial = (await seguridad.enrollBiometric(
        '000000',
      )).getOrElse((_) => fail('no se activó la huella'));
      await repo.signOut();

      final r = await repo.signInWithBiometric(
        dni: otroDni,
        credential: credencial,
      );

      expect(r.isRight(), isTrue);
      expect(repo.currentSession?.identifier, otroDni);
    },
  );

  test('activate deja el DNI de la sesión en el estado compartido', () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    final repo = MemoryAuthRepository(security: estado);

    await repo.activate(
      const AuthSession(userId: 'mem-1', identifier: '45678912'),
    );

    expect(estado.dni, '45678912');
  });

  test(
    'un teléfono no confiable: PIN correcto → DeviceVerificationRequired',
    () async {
      final repo = MemoryAuthRepository(deviceTrusted: false);

      final r = await repo.signIn(identifier: '12345678', pin: '000000');

      expect(switch (r.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      }, isA<DeviceVerificationRequired>());
      expect(repo.currentSession, isNull);
    },
  );

  test('signIn con PIN inválido → InvalidCredentials', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.signIn(identifier: '12345678', pin: '999999');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>().having(
        (f) => f.failure,
        'failure',
        isA<InvalidCredentials>(),
      ),
    );
  });

  test(
    'register crea la cuenta (identifier=dni, alias) pero NO inicia sesión',
    () async {
      final repo = MemoryAuthRepository();
      final result = await repo.register(
        dni: '87654321',
        nombres: 'Juan Carlos',
        apellidos: 'Pérez García',
        email: 'juan@correo.com',
        pin: '024689',
      );
      final session = result.getRight().toNullable();
      expect(session?.identifier, '87654321');
      expect(session?.alias, '@juan'); // derivado del primer nombre
      expect(session?.fullName, 'Juan Carlos Pérez García');
      // No auto-login: la sesión se activa aparte.
      expect(repo.currentSession, isNull);
    },
  );

  test(
    'el alias del registro sigue la regla: sin tildes, nunca el DNI',
    () async {
      for (final (nombres, alias) in [
        ('José', '@jose'),
        ('Li', '@cuyli'),
        ('', '@cuy'),
      ]) {
        final s = (await MemoryAuthRepository().register(
          dni: '87654321',
          nombres: nombres,
          apellidos: 'Pérez',
          email: 'x@correo.com',
          pin: '024689',
        )).getRight().toNullable();
        expect(s?.alias, alias, reason: nombres);
        expect(AliasRules.isValid(s?.alias ?? ''), isTrue, reason: nombres);
      }
    },
  );

  test('activate inicia la sesión creada y la emite', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);
    final created = (await repo.register(
      dni: '87654321',
      nombres: 'Juan',
      apellidos: 'Pérez',
      email: 'j@p.pe',
      pin: '024689',
    )).getRight().toNullable()!;

    await repo.activate(created);

    expect(repo.currentSession, created);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, created);
  });

  test('register con PIN de 5 dígitos → WeakPin', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(
      dni: '87654321',
      nombres: 'A',
      apellidos: 'B',
      email: 'a@b.pe',
      pin: '12345',
    );
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>().having(
        (f) => f.failure,
        'failure',
        isA<WeakPin>(),
      ),
    );
  });

  test('register con DNI ya registrado → IdentifierTaken', () async {
    final repo = MemoryAuthRepository();
    await repo.register(
      dni: '87654321',
      nombres: 'A',
      apellidos: 'B',
      email: 'a@b.pe',
      pin: '024689',
    );
    await repo.signOut();
    final result = await repo.register(
      dni: '87654321',
      nombres: 'A',
      apellidos: 'B',
      email: 'a@b.pe',
      pin: '024689',
    );
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>().having(
        (f) => f.failure,
        'failure',
        isA<IdentifierTaken>(),
      ),
    );
  });

  test('signOut → sesión null y lo emite', () async {
    final repo = MemoryAuthRepository(
      initial: const AuthSession(userId: 'u', identifier: '12345678'),
    );
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);
    final result = await repo.signOut();
    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isNull);
  });

  test(
    'tras registrarse, el login devuelve nombre y alias (como el backend)',
    () async {
      final estado = MemorySecurityState.demo(clock: DateTime.now);
      estado.credentials['ok'] = estado.thisDeviceId;
      final repo = MemoryAuthRepository(security: estado);
      await repo.register(
        dni: '87654321',
        nombres: 'Juan Carlos',
        apellidos: 'Pérez García',
        email: 'juan@correo.com',
        pin: '000000',
      );
      await repo.signOut();

      final porPin = (await repo.signIn(
        identifier: '87654321',
        pin: '000000',
      )).getRight().toNullable();
      final porHuella = (await repo.signInWithBiometric(
        dni: '87654321',
        credential: 'ok',
      )).getRight().toNullable();

      for (final s in [porPin, porHuella]) {
        expect(s?.fullName, 'Juan Carlos Pérez García');
        expect(s?.alias, '@juan');
      }
    },
  );
}
