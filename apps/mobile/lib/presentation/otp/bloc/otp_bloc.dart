import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/otp/application/otp_actions.dart';
import '../../../feature/otp/domain/otp_challenge.dart';
import '../../../feature/otp/domain/otp_failure.dart';
import '../../../feature/otp/domain/otp_policy.dart';

part 'otp_bloc.freezed.dart';
part 'otp_event.dart';
part 'otp_state.dart';

/// Bloc del código de un solo uso. Consume `OtpActions` por constructor.
///
/// Un solo bloc sirve a la recuperación de PIN y a la verificación de teléfono
/// nuevo: lo único que cambia entre ambos es el identificador y el copy, que
/// viaja en `OtpConfig` (ver `otp_config.dart`).
///
/// El reloj entra por constructor; el latido llega como stream para poder
/// adelantarlo en los tests sin esperar en tiempo real.
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc({
    required OtpActions actions,
    required String identifier,
    required DateTime Function() clock,
    Stream<void>? ticks,
  })  : _actions = actions,
        _identifier = identifier,
        _now = clock,
        super(const OtpState()) {
    on<OtpStarted>(_onStarted);
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<OtpTicked>((event, emit) => emit(_withClocks(state)));

    _ticker = (ticks ?? Stream<void>.periodic(const Duration(seconds: 1)))
        .listen((_) => add(const OtpEvent.ticked()));
  }

  final OtpActions _actions;
  final String _identifier;
  final DateTime Function() _now;
  late final StreamSubscription<void> _ticker;

  Future<void> _onStarted(OtpStarted event, Emitter<OtpState> emit) async {
    final result = await _actions.request(_identifier);
    emit(result.match(
      // El identificador está en enfriamiento tras una cancelación previa: no
      // hay camino de reenvío, se sale por la pantalla de flujo cancelado.
      (failure) => state.copyWith(status: OtpStatus.idle, cancelled: true),
      (challenge) => _fromChallenge(state, challenge),
    ));
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    // Con el código vencido, escribir no lo revive: hay que pedir uno nuevo.
    if (state.codeState == OtpCodeState.expired) return;
    final code = event.code;
    emit(state.copyWith(
      code: code,
      codeState: switch (code.length) {
        0 => OtpCodeState.empty,
        6 => OtpCodeState.complete,
        _ => OtpCodeState.incomplete,
      },
    ));
  }

  Future<void> _onSubmitted(OtpSubmitted event, Emitter<OtpState> emit) async {
    final challengeId = state.challengeId;
    if (challengeId == null || state.code.length != 6) return;
    if (state.codeState == OtpCodeState.expired) return;

    emit(state.copyWith(status: OtpStatus.submitting));
    final result =
        await _actions.verify(challengeId: challengeId, code: state.code);
    emit(result.match(
      (failure) => _afterFailedVerify(failure),
      (ticket) => state.copyWith(
        status: OtpStatus.idle,
        verified: true,
        otpTicket: ticket,
      ),
    ));
  }

  OtpState _afterFailedVerify(GlobalFailure<OtpFailure> failure) {
    final base = state.copyWith(status: OtpStatus.idle);
    return switch (failure) {
      // Casillas limpias y foco a la primera: reintentar es lo esperable.
      ServerFailure(failure: InvalidCode(:final attemptsLeft)) => base.copyWith(
          code: '',
          codeState: OtpCodeState.invalid,
          attemptsLeft: attemptsLeft,
        ),
      ServerFailure(failure: ChallengeCancelled(:final reason)) => base.copyWith(
          code: '',
          attemptsLeft: 0,
          cancelled: true,
          cancelledReason: reason,
        ),
      // Vencido o ya consumido: el código dejó de existir, se pide uno nuevo.
      ServerFailure(failure: CodeExpired()) ||
      ServerFailure(failure: ChallengeNotFound()) =>
        base.copyWith(code: '', codeState: OtpCodeState.expired),
      _ => base.copyWith(cancelled: true),
    };
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    final challengeId = state.challengeId;
    if (challengeId == null || state.status == OtpStatus.submitting) return;
    // Solo frena el enfriamiento en curso. Vencido el código, reenviar es la
    // acción principal aunque el enfriamiento siga corriendo: son relojes
    // distintos. Agotados los reenvíos la petición SÍ llega al servicio, que
    // la responde cancelando el reto.
    if (state.codeState != OtpCodeState.expired &&
        state.resendState == OtpResendState.cooling) {
      return;
    }

    emit(state.copyWith(status: OtpStatus.submitting));
    final result = await _actions.resend(challengeId);
    emit(result.match(
      (failure) => switch (failure) {
        ServerFailure(failure: ChallengeCancelled(:final reason)) =>
          state.copyWith(
            status: OtpStatus.idle,
            cancelled: true,
            cancelledReason: reason,
          ),
        _ => state.copyWith(status: OtpStatus.idle, cancelled: true),
      },
      // Código nuevo: casillas limpias y los dos relojes reiniciados.
      (challenge) => _fromChallenge(
        state.copyWith(code: '', codeState: OtpCodeState.empty),
        challenge,
      ),
    ));
  }

  OtpState _fromChallenge(OtpState base, OtpChallenge challenge) => _withClocks(
        base.copyWith(
          status: OtpStatus.idle,
          challengeId: challenge.id,
          maskedEmail: challenge.maskedEmail,
          attemptsLeft: challenge.attemptsLeft,
          resendsLeft: challenge.resendsLeft,
          expiresAt: challenge.expiresAt,
          cooldownUntil: challenge.cooldownUntil,
        ),
      );

  /// Recalcula los dos relojes SIN mezclarlos: el vencimiento solo toca
  /// `codeState` y el enfriamiento solo toca `resendState`.
  OtpState _withClocks(OtpState base) {
    final now = _now();
    final expiresAt = base.expiresAt;
    final cooldownUntil = base.cooldownUntil;

    final expired = expiresAt != null && !now.isBefore(expiresAt);
    final codeState = expired ? OtpCodeState.expired : base.codeState;

    final remaining = cooldownUntil == null || !now.isBefore(cooldownUntil)
        ? Duration.zero
        : cooldownUntil.difference(now);
    final resendState = base.resendsLeft <= 0
        ? OtpResendState.exhausted
        : (remaining > Duration.zero
            ? OtpResendState.cooling
            : OtpResendState.available);

    return base.copyWith(
      // Vencido, el código escrito ya no sirve: las casillas quedan vacías.
      code: expired ? '' : base.code,
      codeState: codeState,
      resendState: resendState,
      cooldownRemaining: remaining,
    );
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
