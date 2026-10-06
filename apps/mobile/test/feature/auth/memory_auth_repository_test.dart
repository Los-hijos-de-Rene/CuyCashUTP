import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
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

  test('signInWithBiometric acepta la credencial vigente de este teléfono',
      () async {
    final estado = MemorySecurityState.demo(clock: DateTime.now);
    estado.credentials['ok'] = estado.thisDeviceId;
    final repo = MemoryAuthRepository(security: estado);

    final bien =
        await repo.signInWithBiometric(dni: estado.dni, credential: 'ok');
    final mal =
        await repo.signInWithBiometric(dni: estado.dni, credential: 'x');

    expect(bien.isRight(), isTrue);
    expect(repo.currentSession?.identifier, estado.dni);
    expect(
      switch (mal.getLeft().toNullable()) {
        ServerFailure(:final failure) => failure,
        _ => null,
      },
      isA<BiometricRevoked>(),
    );
  });

  test('signIn con PIN inválido → InvalidCredentials', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.signIn(identifier: '12345678', pin: '999999');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<InvalidCredentials>()),
    );
  });

  test('register crea la cuenta (identifier=dni, alias) pero NO inicia sesión',
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
  });

  test('activate inicia la sesión creada y la emite', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);
    final created = (await repo.register(
      dni: '87654321', nombres: 'Juan', apellidos: 'Pérez',
      email: 'j@p.pe', pin: '024689',
    )).getRight().toNullable()!;

    await repo.activate(created);

    expect(repo.currentSession, created);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, created);
  });

  test('register con PIN de 5 dígitos → WeakPin', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '12345',
    );
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<WeakPin>()),
    );
  });

  test('register con DNI ya registrado → IdentifierTaken', () async {
    final repo = MemoryAuthRepository();
    await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '024689',
    );
    await repo.signOut();
    final result = await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '024689',
    );
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<IdentifierTaken>()),
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
}
