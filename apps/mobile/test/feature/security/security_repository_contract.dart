import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/domain/security_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escenario que [construir] entrega con estado nuevo: PIN actual [pin],
/// dos dispositivos (este primero, sin huella; otro con id [otroId]),
/// [maxIntentos] PIN errados antes del bloqueo (el real: `LockoutPolicy`).
void probarContratoDeSeguridad(
  String nombre,
  SecurityRepository Function() construir, {
  required String pin,
  required String otroId,
  required int maxIntentos,
}) {
  T valorDe<T>(Result<SecurityFailure, T> r) =>
      r.match((f) => fail('No debía fallar: $f'), (v) => v);

  SecurityFailure falloDe(Result<SecurityFailure, Object?> r) {
    final failure = r.getLeft().toNullable();
    expect(failure, isA<ServerFailure<SecurityFailure>>(), reason: '$r');
    return (failure! as ServerFailure<SecurityFailure>).failure;
  }

  group('$nombre · contrato de SecurityRepository', () {
    test('cambiar el PIN devuelve las sesiones cerradas', () async {
      expect(valorDe(await construir().changePin(current: pin, nuevo: '502718')),
          greaterThanOrEqualTo(0));
    });

    test('PIN actual errado trae los intentos restantes', () async {
      final f = falloDe(
          await construir().changePin(current: '111222', nuevo: '502718'));
      expect(f, isA<SecurityWrongPin>());
      expect((f as SecurityWrongPin).attemptsLeft, maxIntentos - 1);
    });

    test('al agotar los intentos, locked', () async {
      final repo = construir();
      for (var i = 0; i < maxIntentos - 1; i++) {
        await repo.changePin(current: '111222', nuevo: '502718');
      }
      expect(falloDe(await repo.changePin(current: '111222', nuevo: '502718')),
          isA<SecurityLocked>());
    });

    test('PIN nuevo previsible o igual al actual', () async {
      expect(falloDe(await construir().changePin(current: pin, nuevo: '123456')),
          isA<SecurityWeakPin>());
      expect(falloDe(await construir().changePin(current: pin, nuevo: pin)),
          isA<SecurityPinUnchanged>());
    });

    test('lista con este teléfono primero', () async {
      final lista = valorDe(await construir().devices());
      expect(lista, hasLength(2));
      expect(lista.first.esEste, isTrue);
      expect(lista.last.id, otroId);
    });

    test('desvincular otro lo quita; dos veces es deviceNotFound', () async {
      final repo = construir();
      valorDe(await repo.unlinkDevice(otroId));
      expect(valorDe(await repo.devices()), hasLength(1));
      expect(falloDe(await repo.unlinkDevice(otroId)),
          isA<SecurityDeviceNotFound>());
    });

    test('desvincular este teléfono es cannotUnlinkCurrent', () async {
      final repo = construir();
      final este = valorDe(await repo.devices()).first.id;
      expect(falloDe(await repo.unlinkDevice(este)),
          isA<SecurityCannotUnlinkCurrent>());
    });

    test('activar la huella da un secreto y marca este teléfono', () async {
      final repo = construir();
      expect(valorDe(await repo.enrollBiometric(pin)), isNotEmpty);
      expect(valorDe(await repo.devices()).first.conHuella, isTrue);
      valorDe(await repo.revokeBiometric());
      expect(valorDe(await repo.devices()).first.conHuella, isFalse);
    });

    test('activar con PIN errado es wrongPin', () async {
      expect(falloDe(await construir().enrollBiometric('111222')),
          isA<SecurityWrongPin>());
    });
  });
}
