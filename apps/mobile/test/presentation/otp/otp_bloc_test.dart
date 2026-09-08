import 'package:cuycash/feature/otp/application/otp_actions.dart';
import 'package:cuycash/feature/otp/domain/otp_failure.dart';
import 'package:cuycash/feature/otp/domain/otp_policy.dart';
import 'package:cuycash/feature/otp/infrastructure/memory_otp_repository.dart';
import 'package:cuycash/presentation/otp/bloc/otp_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../feature/otp/memory_otp_repository_test.dart' show TestClock;

void main() {
  const email = 'juan.perez@gmail.com';
  late TestClock clock;
  late MemoryOtpRepository repo;

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryOtpRepository(clock: clock.call);
  });

  /// Sin latido automático: el tiempo lo mueven los tests con `clock.advance`
  /// seguido de un `ticked` explícito.
  Future<OtpBloc> open() async {
    final bloc = OtpBloc(
      actions: OtpActions(repo),
      identifier: email,
      clock: clock.call,
      ticks: const Stream<void>.empty(),
    )..add(const OtpEvent.started());
    await Future<void>.delayed(Duration.zero);
    return bloc;
  }

  Future<void> settle(OtpBloc bloc) =>
      Future<void>.delayed(Duration.zero);

  test('al abrir muestra el correo enmascarado y arranca en enfriamiento',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);

    expect(bloc.state.maskedEmail, 'j•••••@gmail.com');
    expect(bloc.state.codeState, OtpCodeState.empty);
    expect(bloc.state.resendState, OtpResendState.cooling);
    expect(bloc.state.status, OtpStatus.idle);
  });

  test('el código avanza empty → incomplete → complete', () async {
    final bloc = await open();
    addTearDown(bloc.close);

    bloc.add(const OtpEvent.codeChanged('48'));
    await settle(bloc);
    expect(bloc.state.codeState, OtpCodeState.incomplete);
    expect(bloc.state.canSubmit, isFalse);

    bloc.add(const OtpEvent.codeChanged(OtpPolicy.validCode));
    await settle(bloc);
    expect(bloc.state.codeState, OtpCodeState.complete);
    expect(bloc.state.canSubmit, isTrue);
  });

  test('CP-01 · código correcto → verificado', () async {
    final bloc = await open();
    addTearDown(bloc.close);

    bloc
      ..add(const OtpEvent.codeChanged(OtpPolicy.validCode))
      ..add(const OtpEvent.submitted());
    await settle(bloc);

    expect(bloc.state.verified, isTrue);
    expect(bloc.state.cancelled, isFalse);
  });

  test('CP-02 · código incorrecto → 2 intentos y casillas limpias', () async {
    final bloc = await open();
    addTearDown(bloc.close);

    bloc
      ..add(const OtpEvent.codeChanged('000000'))
      ..add(const OtpEvent.submitted());
    await settle(bloc);

    expect(bloc.state.codeState, OtpCodeState.invalid);
    expect(bloc.state.attemptsLeft, 2);
    // Casillas limpias: la pantalla devuelve el foco a la primera.
    expect(bloc.state.code, isEmpty);
    // El reenvío sigue rigiéndose por SU propio reloj.
    expect(bloc.state.resendState, OtpResendState.cooling);
  });

  test('CP-03 · tercer código incorrecto → cancelado por intentos', () async {
    final bloc = await open();
    addTearDown(bloc.close);

    for (final code in ['000000', '000001', '000002']) {
      bloc
        ..add(OtpEvent.codeChanged(code))
        ..add(const OtpEvent.submitted());
      await settle(bloc);
    }

    expect(bloc.state.cancelled, isTrue);
    expect(bloc.state.cancelledReason, OtpCancelReason.attempts);
  });

  test('CP-04 · con +601 s el código vence y el botón cambia de acción',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);
    bloc.add(const OtpEvent.codeChanged('4821'));
    await settle(bloc);

    clock.advance(const Duration(seconds: 601));
    bloc.add(const OtpEvent.ticked());
    await settle(bloc);

    expect(bloc.state.codeState, OtpCodeState.expired);
    // Reintentar deja de ser posible: pedir código nuevo pasa a ser principal.
    expect(bloc.state.canSubmit, isTrue);
    expect(bloc.state.showsResendRow, isFalse);
  });

  test('CP-05 · con +59 s sigue en enfriamiento y sin línea de spam',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);

    clock.advance(const Duration(seconds: 59));
    bloc.add(const OtpEvent.ticked());
    await settle(bloc);

    expect(bloc.state.resendState, OtpResendState.cooling);
    expect(bloc.state.showsSpamHint, isFalse);
    expect(bloc.state.cooldownRemaining, const Duration(seconds: 1));
    // El enfriamiento no toca el código.
    expect(bloc.state.codeState, OtpCodeState.empty);
  });

  test('CP-06 · con +60 s el reenvío está disponible y aparece el spam',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);

    clock.advance(const Duration(seconds: 60));
    bloc.add(const OtpEvent.ticked());
    await settle(bloc);

    expect(bloc.state.resendState, OtpResendState.available);
    expect(bloc.state.showsSpamHint, isTrue);
    // El enfriamiento en cero NO invalida el código vigente.
    expect(bloc.state.codeState, OtpCodeState.empty);
  });

  test('CP-07 · reenviar reinicia ambos relojes y limpia las casillas',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);
    bloc.add(const OtpEvent.codeChanged('4821'));
    clock.advance(const Duration(seconds: 60));
    bloc.add(const OtpEvent.ticked());
    await settle(bloc);
    final previousExpiry = bloc.state.expiresAt;

    bloc.add(const OtpEvent.resendRequested());
    await settle(bloc);

    expect(bloc.state.code, isEmpty);
    expect(bloc.state.codeState, OtpCodeState.empty);
    expect(bloc.state.expiresAt, isNot(previousExpiry));
    expect(bloc.state.resendState, OtpResendState.cooling);
    expect(bloc.state.resendsLeft, OtpPolicy.maxResends - 1);
  });

  test('un código inválido no bloquea el reenvío (relojes independientes)',
      () async {
    final bloc = await open();
    addTearDown(bloc.close);

    bloc
      ..add(const OtpEvent.codeChanged('000000'))
      ..add(const OtpEvent.submitted());
    await settle(bloc);
    clock.advance(const Duration(seconds: 60));
    bloc.add(const OtpEvent.ticked());
    await settle(bloc);

    expect(bloc.state.codeState, OtpCodeState.invalid);
    expect(bloc.state.resendState, OtpResendState.available);
  });

  test('CP-08 · el cuarto reenvío cancela por reenvíos', () async {
    final bloc = await open();
    addTearDown(bloc.close);

    for (var i = 0; i < OtpPolicy.maxResends + 1; i++) {
      clock.advance(const Duration(seconds: 60));
      bloc.add(const OtpEvent.ticked());
      await settle(bloc);
      bloc.add(const OtpEvent.resendRequested());
      await settle(bloc);
    }

    expect(bloc.state.cancelled, isTrue);
    expect(bloc.state.cancelledReason, OtpCancelReason.resends);
  });

  test('CP-10 · abrir con el identificador bloqueado sale por cancelado',
      () async {
    final first = await open();
    for (final code in ['000000', '000001', '000002']) {
      first
        ..add(OtpEvent.codeChanged(code))
        ..add(const OtpEvent.submitted());
      await settle(first);
    }
    await first.close();

    final retry = await open();
    addTearDown(retry.close);

    expect(retry.state.cancelled, isTrue);
  });
}
