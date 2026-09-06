import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

AuthBloc buildBloc(MemoryAuthRepository repo) => AuthBloc(AuthActions(repo));

void main() {
  const session = AuthSession(userId: 'u', identifier: '12345678');

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
        const AuthEvent.loginSubmitted(identifier: '12345678', pin: '0000')),
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
    'register correcto → AuthAuthenticated',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc
        .add(const AuthEvent.registerSubmitted(dni: '87654321', pin: '0000')),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>(), isA<AuthAuthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'signOut → AuthUnauthenticated',
    build: () => buildBloc(MemoryAuthRepository(initial: session)),
    act: (bloc) => bloc.add(const AuthEvent.signedOut()),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>()],
  );
}
