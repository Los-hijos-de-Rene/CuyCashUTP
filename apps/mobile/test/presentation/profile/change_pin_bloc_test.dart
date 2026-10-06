import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/feature/security/application/security_actions.dart';
import 'package:cuycash/feature/security/domain/linked_device.dart';
import 'package:cuycash/feature/security/domain/security_failure.dart';
import 'package:cuycash/feature/security/domain/security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_repository.dart';
import 'package:cuycash/feature/security/infrastructure/memory_security_state.dart';
import 'package:cuycash/presentation/profile/change_pin/bloc/change_pin_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SinRed implements SecurityRepository {
  int llamadas = 0;

  @override
  FutureResult<SecurityFailure, int> changePin({
    required String current,
    required String nuevo,
  }) async {
    llamadas++;
    return left(const GlobalFailure.server(SecurityFailure.network()));
  }

  @override
  FutureResult<SecurityFailure, List<LinkedDevice>> devices() async =>
      right([]);
  @override
  FutureResult<SecurityFailure, Unit> unlinkDevice(String id) async =>
      right(unit);
  @override
  FutureResult<SecurityFailure, String> enrollBiometric(String pin) async =>
      right('x');
  @override
  FutureResult<SecurityFailure, Unit> revokeBiometric() async => right(unit);
}

ChangePinBloc _bloc([SecurityRepository? repo]) => ChangePinBloc(
  SecurityActions(
    repo ??
        MemorySecurityRepository(
          MemorySecurityState.demo(clock: DateTime.now),
          clock: DateTime.now,
        ),
  ),
);

void _teclear(ChangePinBloc b, String pin) {
  for (final d in pin.split('')) {
    b.add(ChangePinEvent.digitPressed(int.parse(d)));
  }
}

void main() {
  blocTest<ChangePinBloc, ChangePinState>(
    'tres pasos y éxito',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.status, ChangePinStatus.done);
      expect(b.state.revokedSessions, 1);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'un PIN nuevo previsible no avanza a confirmar',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '123456');
    },
    verify: (b) {
      expect(b.state.step, ChangePinStep.nuevo);
      expect(b.state.error, ChangePinError.weakPin);
      expect(b.state.pin, isEmpty);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'el nuevo igual al actual se rechaza sin preguntar al servidor',
    build: _bloc,
    act: (b) {
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    verify: (b) => expect(b.state.error, ChangePinError.samePin),
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'confirmación distinta vuelve a elegir el nuevo',
    build: _bloc,
    act: (b) {
      _teclear(b, '000000');
      _teclear(b, '502718');
      _teclear(b, '502719');
    },
    verify: (b) {
      expect(b.state.step, ChangePinStep.nuevo);
      expect(b.state.error, ChangePinError.mismatch);
    },
  );

  blocTest<ChangePinBloc, ChangePinState>(
    'PIN actual errado vuelve al paso 1 con los intentos',
    build: _bloc,
    act: (b) {
      _teclear(b, '111222');
      _teclear(b, '502718');
      _teclear(b, '502718');
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.step, ChangePinStep.actual);
      expect(b.state.error, ChangePinError.wrongPin);
      expect(b.state.attemptsLeft, LockoutPolicy.maxAttempts - 1);
      expect(b.state.currentPin, isEmpty);
    },
  );

  test('sin red: resultado desconocido y UNA sola llamada', () async {
    final repo = _SinRed();
    final b = _bloc(repo);
    _teclear(b, '000000');
    _teclear(b, '502718');
    _teclear(b, '502718');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(b.state.error, ChangePinError.unknownOutcome);
    expect(b.state.status, ChangePinStatus.idle);
    expect(repo.llamadas, 1);
    await b.close();
  });

  test('al agotar los intentos expone lockedUntil', () async {
    final b = _bloc();
    for (var i = 0; i < LockoutPolicy.maxAttempts; i++) {
      _teclear(b, '111222');
      _teclear(b, '502718');
      _teclear(b, '502718');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(b.state.lockedUntil, isNotNull);
    await b.close();
  });
}
