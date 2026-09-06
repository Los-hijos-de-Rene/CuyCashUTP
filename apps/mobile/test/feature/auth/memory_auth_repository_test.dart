import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signIn con PIN válido → sesión y la emite por el stream', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);

    final result = await repo.signIn(identifier: '12345678', pin: '0000');

    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isA<AuthSession>());
  });

  test('signIn con PIN inválido → InvalidCredentials', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.signIn(identifier: '12345678', pin: '9999');

    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<InvalidCredentials>()),
    );
    expect(repo.currentSession, isNull);
  });

  test('register nuevo DNI → sesión', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(dni: '87654321', pin: '0000');
    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
  });

  test('register con PIN de menos de 4 dígitos → WeakPin', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(dni: '87654321', pin: '12');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<WeakPin>()),
    );
  });

  test('register con DNI ya registrado → IdentifierTaken', () async {
    final repo = MemoryAuthRepository();
    await repo.register(dni: '87654321', pin: '0000');
    await repo.signOut();
    final result = await repo.register(dni: '87654321', pin: '0000');
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
