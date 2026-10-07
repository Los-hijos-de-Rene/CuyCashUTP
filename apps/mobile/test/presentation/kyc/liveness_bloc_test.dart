import 'dart:async';
import 'dart:typed_data';

import 'package:cuycash/feature/kyc/application/kyc_actions.dart';
import 'package:cuycash/feature/kyc/domain/face_observation.dart';
import 'package:cuycash/feature/kyc/domain/face_tracker.dart';
import 'package:cuycash/feature/kyc/domain/liveness_gestures.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:cuycash/presentation/kyc/bloc/liveness_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../feature/kyc/memory_kyc_repository_test.dart' show TestClock;

/// Cámara falsa: la prueba decide qué "ve" el detector en cada fotograma.
class FakeFaceTracker implements FaceTracker {
  final _controller = StreamController<FaceObservation>.broadcast();
  String? failOnStart;

  /// Si es true, los fotogramas pedidos ya salieron del búfer.
  bool framesEvicted = false;

  final List<int> kept = [];
  var starts = 0;
  var stops = 0;
  var disposed = false;

  void see(FaceObservation observation) => _controller.add(observation);

  @override
  Stream<FaceObservation> get observations => _controller.stream;

  @override
  Future<void> start() async {
    if (failOnStart case final message?) throw FaceTrackerException(message);
    starts++;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }

  @override
  Future<String?> keepFrame(int frameId) async {
    kept.add(frameId);
    return framesEvicted ? null : 'jpg-$frameId';
  }
}

void main() {
  late TestClock clock;
  late FakeFaceTracker tracker;
  late MemoryKycRepository repo;
  var frame = 0;

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    tracker = FakeFaceTracker();
    repo = MemoryKycRepository(
      clock: clock.call,
      steps: const [LivenessStep.izquierda, LivenessStep.parpadeo],
    );
    frame = 0;
  });

  LivenessBloc build() => LivenessBloc(
        actions: KycActions(repo),
        tracker: tracker,
        documentImage: Uint8List.fromList([1, 2, 3]),
        clock: clock.call,
      );

  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Un rostro bien encuadrado, con el giro y los ojos que se pidan.
  FaceObservation face({
    double yaw = 0,
    double eyes = 0.95,
    double widthRatio = 0.45,
    double centerX = 0.5,
    int faceCount = 1,
  }) =>
      FaceObservation(
        frameId: frame++,
        faceCount: faceCount,
        centerX: centerX,
        centerY: 0.5,
        widthRatio: widthRatio,
        yaw: yaw,
        leftEyeOpen: eyes,
        rightEyeOpen: eyes,
      );

  Future<void> see(FaceObservation observation, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      tracker.see(i == 0 ? observation : face(
            yaw: observation.yaw,
            eyes: observation.leftEyeOpen ?? 1,
            widthRatio: observation.widthRatio,
            centerX: observation.centerX,
            faceCount: observation.faceCount,
          ));
      await settle();
    }
  }

  Future<LivenessBloc> started() async {
    final bloc = build()..add(const LivenessEvent.started());
    await settle();
    return bloc;
  }

  Future<LivenessBloc> framed() async {
    final bloc = await started();
    await see(face(), times: 5);
    return bloc;
  }

  test('al empezar abre la cámara, trae los gestos y pide encuadrar', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    expect(tracker.starts, 1);
    expect(bloc.state.phase, LivenessPhase.positioning);
    expect(bloc.state.steps, [LivenessStep.izquierda, LivenessStep.parpadeo]);
    expect(bloc.state.framing, FramingIssue.noFace);
  });

  test('guía el encuadre: lejos, descentrado, dos personas', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    await see(face(widthRatio: 0.1));
    expect(bloc.state.framing, FramingIssue.tooFar);

    await see(face(centerX: 0.9));
    expect(bloc.state.framing, FramingIssue.offCenter);

    await see(face(faceCount: 2));
    expect(bloc.state.framing, FramingIssue.multipleFaces);
  });

  test('con el rostro quieto y encuadrado empieza el primer gesto, sin botón',
      () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    expect(bloc.state.phase, LivenessPhase.performing);
    expect(bloc.state.currentStep, LivenessStep.izquierda);
    expect(bloc.state.framing, isNull);
  });

  test('un mal encuadre a mitad del encuadre reinicia la cuenta', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    await see(face(), times: 4);
    await see(face(widthRatio: 0.1));
    await see(face(), times: 4);

    expect(bloc.state.phase, LivenessPhase.positioning);
  });

  test('girar al lado contrario no cuenta', () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: -0.25), times: 5);

    expect(bloc.state.phase, LivenessPhase.performing);
    expect(bloc.state.completedSteps, 0);
  });

  test('el giro pedido avanza solo y pide volver al frente', () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: 0.25), times: 3);

    expect(bloc.state.completedSteps, 1);
    expect(bloc.state.phase, LivenessPhase.recentering);
    expect(bloc.state.currentStep, LivenessStep.parpadeo);
  });

  test('perder el rostro a mitad del gesto avisa pero no reinicia', () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: 0.25), times: 2);
    await see(FaceObservation.empty(frame++));
    expect(bloc.state.framing, FramingIssue.noFace);
    expect(bloc.state.phase, LivenessPhase.performing);

    await see(face(yaw: 0.25));
    expect(bloc.state.completedSteps, 1);
  });

  test('el parpadeo exige ver los ojos cerrados Y volver a abrirse', () async {
    final bloc = await framed();
    addTearDown(bloc.close);
    await see(face(yaw: 0.25), times: 3);
    await see(face(), times: 3);
    expect(bloc.state.phase, LivenessPhase.performing);

    await see(face(eyes: 0.05), times: 2);
    expect(bloc.state.phase, LivenessPhase.performing,
        reason: 'ojos cerrados todavía no es un parpadeo');
  });

  test('hechos todos los gestos, envía UNA vez y aprueba', () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: 0.25), times: 3); // izquierda
    await see(face(), times: 3); // de vuelta al frente
    await see(face(eyes: 0.05)); // ojos cerrados
    await see(face()); // y abiertos otra vez

    expect(bloc.state.phase, LivenessPhase.done);
    expect(bloc.state.isApproved, isTrue);
    expect(tracker.stops, greaterThanOrEqualTo(1),
        reason: 'la cámara deja de analizar antes de enviar');
    // izquierda: 3 de frente + 3 girado; parpadeo: 3 + cerrado + abierto.
    expect(tracker.kept, hasLength(11));
  });

  test('tras un rato sin completar el gesto, sugiere marcarlo más', () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: 0.05));
    expect(bloc.state.slow, isFalse);

    clock.advance(const Duration(seconds: 9));
    await see(face(yaw: 0.05));
    expect(bloc.state.slow, isTrue);
  });

  test('si el token vence durante el flujo, se cae y pide empezar de nuevo',
      () async {
    final bloc = await framed();
    addTearDown(bloc.close);

    clock.advance(const Duration(minutes: 4));
    await see(face(yaw: 0.25));

    expect(bloc.state.phase, LivenessPhase.failed);
    expect(bloc.state.error, LivenessError.challengeExpired);
  });

  test('sin cámara, falla con el error de cámara', () async {
    tracker.failOnStart = 'permiso denegado';
    final bloc = await started();
    addTearDown(bloc.close);

    expect(bloc.state.phase, LivenessPhase.failed);
    expect(bloc.state.error, LivenessError.camera);
  });

  test('si los fotogramas no llegaron, el servidor rechaza (no se aprueba)',
      () async {
    tracker.framesEvicted = true;
    final bloc = await framed();
    addTearDown(bloc.close);

    await see(face(yaw: 0.25), times: 3);
    await see(face(), times: 3);
    await see(face(eyes: 0.05));
    await see(face());

    expect(bloc.state.phase, LivenessPhase.done);
    expect(bloc.state.isApproved, isFalse);
    expect(bloc.state.error, LivenessError.rejected);
  });

  test('empezar de nuevo tras un fallo pide otro desafío', () async {
    final bloc = await framed();
    addTearDown(bloc.close);
    clock.advance(const Duration(minutes: 4));
    await see(face());
    expect(bloc.state.phase, LivenessPhase.failed);

    bloc.add(const LivenessEvent.started());
    await settle();

    expect(bloc.state.phase, LivenessPhase.positioning);
    expect(bloc.state.completedSteps, 0);
  });

  test('cerrar el bloc libera la cámara', () async {
    final bloc = await started();
    await bloc.close();

    expect(tracker.disposed, isTrue);
  });
}
