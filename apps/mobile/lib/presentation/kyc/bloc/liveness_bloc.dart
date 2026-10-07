import 'dart:async';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/kyc/application/kyc_actions.dart';
import '../../../feature/kyc/domain/face_observation.dart';
import '../../../feature/kyc/domain/face_tracker.dart';
import '../../../feature/kyc/domain/kyc_failure.dart';
import '../../../feature/kyc/domain/liveness_challenge.dart';
import '../../../feature/kyc/domain/liveness_gestures.dart';
import '../../../feature/kyc/domain/liveness_step.dart';

part 'liveness_bloc.freezed.dart';
part 'liveness_event.dart';
part 'liveness_state.dart';

/// Conduce el liveness como lo hace la industria: una sola experiencia
/// continua, sin botones.
///
/// 1. Encuadre: espera a que el rostro esté centrado, cerca y quieto.
/// 2. Gestos: los que pidió el servidor, en SU orden. Cada uno avanza solo en
///    cuanto el detector del teléfono lo ve hecho.
/// 3. Envío: UNA llamada con un segmento de fotogramas clave por gesto.
///
/// El teléfono solo GUÍA. Que ML Kit dé un gesto por hecho no aprueba nada:
/// el servidor vuelve a medir cada segmento y es el único que decide. El orden
/// sigue siendo del servidor, que es lo que protege contra un video grabado.
///
/// Cada segmento sigue la forma que espera el servicio: 3 fotogramas de frente
/// (su línea base) y después los del gesto. Los fotogramas se piden al tracker
/// en el mismo instante en que se observan, porque solo guarda los recientes.
class LivenessBloc extends Bloc<LivenessEvent, LivenessState> {
  LivenessBloc({
    required KycActions actions,
    required FaceTracker tracker,
    required Uint8List documentImage,
    this.gestures = const LivenessGestures(),
    DateTime Function()? clock,
    this.slowAfter = const Duration(seconds: 8),
  })  : _actions = actions,
        _tracker = tracker,
        _documentImage = documentImage,
        _now = clock ?? DateTime.now,
        super(const LivenessState()) {
    on<LivenessStarted>(_onStarted);
    on<LivenessObserved>(_onObserved);
  }

  final KycActions _actions;
  final FaceTracker _tracker;
  final Uint8List _documentImage;
  final LivenessGestures gestures;
  final DateTime Function() _now;

  /// Tras cuánto sin completar un gesto se sugiere hacerlo más marcado.
  final Duration slowAfter;

  /// Fotogramas de frente seguidos que hacen falta para empezar el primer
  /// gesto (encuadre estable) y para retomar entre gestos.
  static const _stableToStart = 5;
  static const _stableBetween = 3;

  /// Fotogramas de frente con que abre cada segmento: la línea base del
  /// servidor (`HEAD_POSE_BASELINE_FRAMES`).
  static const _baselineFrames = 3;

  /// Fotogramas con el giro ya hecho que cierran un segmento de pose.
  static const _peakFrames = 3;

  StreamSubscription<FaceObservation>? _subscription;
  LivenessChallenge? _challenge;

  /// Pose de partida del usuario, medida al encuadrar.
  FaceObservation? _baseline;
  final List<FaceObservation> _stable = [];
  final Map<LivenessStep, List<Future<String?>>> _segments = {};
  List<Future<String?>> _segment = [];
  var _peaks = 0;
  var _sawEyesClosed = false;
  DateTime? _stepStartedAt;

  Future<void> _onStarted(
    LivenessStarted event,
    Emitter<LivenessState> emit,
  ) async {
    _reset();
    emit(const LivenessState(phase: LivenessPhase.preparing));

    _subscription ??= _tracker.observations
        .listen((observation) => add(LivenessEvent.observed(observation)));
    try {
      await _tracker.start();
    } on FaceTrackerException {
      emit(const LivenessState(
          phase: LivenessPhase.failed, error: LivenessError.camera));
      return;
    }

    final result = await _actions.requestChallenge();
    result.match(
      (failure) {
        unawaited(_tracker.stop());
        emit(LivenessState(
            phase: LivenessPhase.failed, error: _errorFor(failure)));
      },
      (challenge) {
        _challenge = challenge;
        emit(LivenessState(
          phase: LivenessPhase.positioning,
          steps: challenge.steps,
          framing: FramingIssue.noFace,
        ));
      },
    );
  }

  Future<void> _onObserved(
    LivenessObserved event,
    Emitter<LivenessState> emit,
  ) async {
    if (!state.isTracking) return;
    final challenge = _challenge;
    if (challenge == null) return;
    if (challenge.isExpired(_now())) {
      await _tracker.stop();
      emit(state.copyWith(
          phase: LivenessPhase.failed, error: LivenessError.challengeExpired));
      return;
    }

    final observation = event.observation;
    switch (state.phase) {
      case LivenessPhase.positioning:
      case LivenessPhase.recentering:
        _onFraming(observation, emit);
      case LivenessPhase.performing:
        await _onGesture(observation, emit);
      default:
        break;
    }
  }

  /// Encuadre (al inicio) o vuelta al frente (entre gestos).
  void _onFraming(FaceObservation o, Emitter<LivenessState> emit) {
    final recentering = state.phase == LivenessPhase.recentering;
    final issue = gestures.framingIssue(o, baseline: _baseline);
    if (issue != null) {
      _stable.clear();
      if (state.framing != issue) emit(state.copyWith(framing: issue));
      return;
    }

    _stable.add(o);
    final needed = recentering ? _stableBetween : _stableToStart;
    if (_stable.length < needed) {
      if (state.framing != null) emit(state.copyWith(framing: null));
      return;
    }

    if (!recentering) _baseline = _average(_stable);
    // Los últimos fotogramas de frente abren el segmento del próximo gesto.
    _segment = [
      for (final frame in _stable.skip(_stable.length - _baselineFrames))
        _tracker.keepFrame(frame.frameId),
    ];
    _stable.clear();
    _peaks = 0;
    _sawEyesClosed = false;
    _stepStartedAt = _now();
    emit(state.copyWith(
        phase: LivenessPhase.performing, framing: null, slow: false));
  }

  Future<void> _onGesture(
    FaceObservation o,
    Emitter<LivenessState> emit,
  ) async {
    final step = state.currentStep;
    final baseline = _baseline;
    if (step == null || baseline == null) return;

    // A mitad del gesto no se reinicia por encuadre: solo se avisa si el
    // rostro se perdió o apareció otro.
    if (!o.hasSingleFace) {
      final issue = o.faceCount == 0
          ? FramingIssue.noFace
          : FramingIssue.multipleFaces;
      if (state.framing != issue) emit(state.copyWith(framing: issue));
      return;
    }

    var completed = false;
    if (step == LivenessStep.parpadeo) {
      if (o.eyesClosedBelow(gestures.eyeClosed)) {
        _segment.add(_tracker.keepFrame(o.frameId));
        _sawEyesClosed = true;
      } else if (_sawEyesClosed && o.eyesOpenAbove(gestures.eyeOpen)) {
        // Uno abierto DESPUÉS del cerrado: el servidor necesita ver la
        // reapertura para contar el parpadeo.
        _segment.add(_tracker.keepFrame(o.frameId));
        completed = true;
      }
    } else if (gestures.reachesPose(step, o, baseline)) {
      _segment.add(_tracker.keepFrame(o.frameId));
      completed = ++_peaks >= _peakFrames;
    }

    if (!completed) {
      final started = _stepStartedAt;
      final slow =
          started != null && _now().difference(started) >= slowAfter;
      if (state.framing != null || state.slow != slow) {
        emit(state.copyWith(framing: null, slow: slow));
      }
      return;
    }

    _segments[step] = _segment;
    _segment = [];
    final next = state.currentIndex + 1;
    if (next < state.steps.length) {
      emit(state.copyWith(
        phase: LivenessPhase.recentering,
        currentIndex: next,
        framing: null,
        slow: false,
      ));
      return;
    }
    emit(state.copyWith(
        phase: LivenessPhase.sending, currentIndex: next, slow: false));
    await _send(emit);
  }

  Future<void> _send(Emitter<LivenessState> emit) async {
    await _tracker.stop();
    final challenge = _challenge;
    if (challenge == null) return;

    final segments = <LivenessStep, List<String>>{};
    for (final entry in _segments.entries) {
      final frames = await Future.wait(entry.value);
      segments[entry.key] = frames.whereType<String>().toList();
    }

    final result = await _actions.verifyFull(
      token: challenge.token,
      documentImage: _documentImage,
      segments: Map.unmodifiable(segments),
    );
    // Los fotogramas son datos biométricos: se sueltan en cuanto dejan de
    // hacer falta, en vez de quedarse vivos mientras dure la pantalla.
    _reset();
    emit(result.match(
      (failure) => state.copyWith(
          phase: LivenessPhase.failed, error: _errorFor(failure)),
      (verification) => state.copyWith(
        phase: LivenessPhase.done,
        verification: verification,
        error: verification.approved ? null : LivenessError.rejected,
      ),
    ));
  }

  void _reset() {
    _challenge = null;
    _baseline = null;
    _stable.clear();
    _segments.clear();
    _segment = [];
    _peaks = 0;
    _sawEyesClosed = false;
    _stepStartedAt = null;
  }

  static FaceObservation _average(List<FaceObservation> frames) {
    double mean(double Function(FaceObservation o) pick) =>
        frames.map(pick).reduce((a, b) => a + b) / frames.length;
    return FaceObservation(
      frameId: frames.last.frameId,
      faceCount: 1,
      centerX: mean((o) => o.centerX),
      centerY: mean((o) => o.centerY),
      widthRatio: mean((o) => o.widthRatio),
      yaw: mean((o) => o.yaw),
      pitchDegrees: mean((o) => o.pitchDegrees),
    );
  }

  static LivenessError _errorFor(GlobalFailure<KycFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: ChallengeExpired()) =>
          LivenessError.challengeExpired,
        ServerFailure(failure: Unauthorized()) => LivenessError.unauthorized,
        ServerFailure(failure: ServiceUnavailable()) =>
          LivenessError.serviceUnavailable,
        NoConnection() || Timeout() => LivenessError.serviceUnavailable,
        _ => LivenessError.generic,
      };

  @override
  Future<void> close() async {
    _reset();
    await _subscription?.cancel();
    await _tracker.dispose();
    return super.close();
  }
}
