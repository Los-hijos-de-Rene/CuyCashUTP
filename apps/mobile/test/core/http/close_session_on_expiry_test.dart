import 'package:cuycash/core/http/close_session_on_expiry.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'la sesión vencida cierra la sesión local y emite sessionChanges',
    () async {
      final auth = MemoryAuthRepository(
        initial: const AuthSession(userId: 'u1', identifier: '12345678'),
      );
      final emitidos = <AuthSession?>[];
      final sub = auth.sessionChanges().listen(emitidos.add);

      closeSessionOnExpiry(auth)();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(auth.currentSession, isNull);
      expect(emitidos, [null]);
    },
  );

  test('sin sesión no hace nada', () async {
    final auth = MemoryAuthRepository();
    final emitidos = <AuthSession?>[];
    final sub = auth.sessionChanges().listen(emitidos.add);

    closeSessionOnExpiry(auth)();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(emitidos, isEmpty);
  });
}
