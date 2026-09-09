import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/kyc/application/kyc_actions.dart';
import '../../../feature/kyc/domain/frame_source.dart';
import '../../../feature/kyc/domain/kyc_failure.dart';
import '../../../feature/kyc/domain/liveness_challenge.dart';
import '../../../feature/kyc/domain/liveness_step.dart';

part 'liveness_bloc.freezed.dart';
part 'liveness_event.dart';
part 'liveness_state.dart';

/// Conduce el desafío de liveness: pide las tareas, graba una ráfaga por tarea
/// y cierra con la verificación completa.
///
/// El ORDEN nunca se decide aquí: se recorre el que mandó el servidor y una
/// tarea solo se marca hecha si el servidor responde `passed:true`. Avanzar por
/// tiempo o por cuenta propia rompería la protección anti-replay del servicio.
///
/// La cámara entra como `FrameSource` para que todo este recorrido —incluidos
/// los reintentos y el vencimiento— sea verificable sin cámara ni permisos.
class LivenessBloc extends Bloc<LivenessEvent, LivenessState> {
  LivenessBloc({
    required KycActions actions,
    required FrameSource frameSource,
    required Uint8List documentImage,
    this.framesPerStep = 8,
  })  : _actions = actions,
        _frames = frameSource,
        _documentImage = documentImage,
        super(const LivenessState()) {
    on<LivenessStarted>(_onStarted);
    on<LivenessStepCaptureRequested>(_onCaptureRequested);
  }

  final KycActions _actions;
  final FrameSource _frames;
  final Uint8List _documentImage;
  final int framesPerStep;

  /// Ráfagas ya validadas, para mandarlas juntas en la verificación final.
  final Map<LivenessStep, List<String>> _segments = {};

  Future<void> _onStarted(
    LivenessStarted event,
    Emitter<LivenessState> emit,
  ) async {
    _segments.clear();
    emit(const LivenessState(phase: LivenessPhase.preparing));
    final result = await _actions.requestChallenge();
    emit(result.match(
      (failure) => state.copyWith(
          phase: LivenessPhase.failed, error: _errorFor(failure)),
      (challenge) => LivenessState(
        phase: LivenessPhase.waiting,
        token: challenge.token,
        steps: challenge.steps,
      ),
    ));
  }

  Future<void> _onCaptureRequested(
    LivenessStepCaptureRequested event,
    Emitter<LivenessState> emit,
  ) async {
    final token = state.token;
    final step = state.currentStep;
    if (token == null || step == null || state.isBusy) return;

    emit(state.copyWith(phase: LivenessPhase.capturing, lastReason: null));

    final List<String> frames;
    try {
      frames = await _frames.captureBurst(frames: framesPerStep);
    } on FrameCaptureException {
      emit(state.copyWith(
          phase: LivenessPhase.failed, error: LivenessError.camera));
      return;
    }

    emit(state.copyWith(phase: LivenessPhase.evaluating));
    final result = await _actions.evaluateStep(
        token: token, step: step, framesBase64: frames);

    final next = await result.match(
      (failure) async => state.copyWith(
          phase: LivenessPhase.failed, error: _errorFor(failure)),
      (evaluation) async {
        // Que no pase NO es un error: es el usuario reintentando la misma
        // tarea, así que ni se avanza ni se descarta el desafío.
        if (!evaluation.passed) {
          return state.copyWith(
            phase: LivenessPhase.retry,
            lastReason: evaluation.reason,
          );
        }
        _segments[step] = frames;
        final advanced = state.copyWith(currentIndex: state.currentIndex + 1);
        if (advanced.currentStep != null) {
          return advanced.copyWith(phase: LivenessPhase.waiting);
        }
        return advanced.copyWith(phase: LivenessPhase.verifying);
      },
    );
    emit(next);

    if (next.phase == LivenessPhase.verifying) await _verify(token, emit);
  }

  Future<void> _verify(String token, Emitter<LivenessState> emit) async {
    final result = await _actions.verifyFull(
      token: token,
      documentImage: _documentImage,
      segments: Map.unmodifiable(_segments),
    );
    emit(result.match(
      (failure) => state.copyWith(
          phase: LivenessPhase.failed, error: _errorFor(failure)),
      (verification) => state.copyWith(
        phase: LivenessPhase.done,
        verification: verification,
        error: verification.approved ? null : LivenessError.rejected,
      ),
    ));
    // Los frames son datos biométricos: se sueltan en cuanto dejan de hacer
    // falta, en vez de quedarse vivos mientras dure la pantalla.
    _segments.clear();
  }

  static LivenessError _errorFor(GlobalFailure<KycFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: ChallengeExpired()) =>
          LivenessError.challengeExpired,
        ServerFailure(failure: ChallengeCompleted()) =>
          LivenessError.challengeExpired,
        ServerFailure(failure: Unauthorized()) => LivenessError.unauthorized,
        ServerFailure(failure: ServiceUnavailable()) =>
          LivenessError.serviceUnavailable,
        NoConnection() || Timeout() => LivenessError.serviceUnavailable,
        _ => LivenessError.generic,
      };

  @override
  Future<void> close() {
    _segments.clear();
    return super.close();
  }
}
