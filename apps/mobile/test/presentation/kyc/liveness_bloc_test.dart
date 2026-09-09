import 'dart:typed_data';

import 'package:cuycash/feature/kyc/application/kyc_actions.dart';
import 'package:cuycash/feature/kyc/domain/frame_source.dart';
import 'package:cuycash/feature/kyc/domain/liveness_step.dart';
import 'package:cuycash/feature/kyc/infrastructure/memory_kyc_repository.dart';
import 'package:cuycash/presentation/kyc/bloc/liveness_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../feature/kyc/memory_kyc_repository_test.dart' show TestClock;

/// Cámara falsa: devuelve la cantidad de frames que se le pida, o falla si se
/// le indica. Permite recorrer el desafío entero sin cámara ni permisos.
class FakeFrameSource implements FrameSource {
  FakeFrameSource({this.framesToReturn, this.failWith});

  /// Si es null devuelve exactamente los que se piden.
  int? framesToReturn;
  String? failWith;

  int bursts = 0;

  @override
  Future<List<String>> captureBurst({int frames = 8}) async {
    bursts++;
    if (failWith case final message?) throw FrameCaptureException(message);
    final count = framesToReturn ?? frames;
    return List.generate(count, (i) => 'frame-$i');
  }
}

void main() {
  late TestClock clock;
  late MemoryKycRepository repo;
  late FakeFrameSource frames;

  setUp(() {
    clock = TestClock(DateTime(2026, 3, 1, 10));
    repo = MemoryKycRepository(clock: clock.call);
    frames = FakeFrameSource();
  });

  LivenessBloc build() => LivenessBloc(
        actions: KycActions(repo),
        frameSource: frames,
        documentImage: Uint8List.fromList([1, 2, 3]),
      );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<LivenessBloc> started() async {
    final bloc = build()..add(const LivenessEvent.started());
    await settle();
    return bloc;
  }

  test('al empezar trae las tareas y espera al usuario', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    expect(bloc.state.phase, LivenessPhase.waiting);
    expect(bloc.state.steps, isNotEmpty);
    expect(bloc.state.currentStep, bloc.state.steps.first);
    expect(bloc.state.completedSteps, 0);
  });

  test('una tarea que pasa avanza a la siguiente', () async {
    final bloc = await started();
    addTearDown(bloc.close);
    final primera = bloc.state.steps.first;

    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(bloc.state.completedSteps, 1);
    expect(bloc.state.currentStep, isNot(primera));
    expect(bloc.state.phase, LivenessPhase.waiting);
  });

  test('una tarea que no pasa se reintenta, no se avanza ni se cae', () async {
    final bloc = await started();
    addTearDown(bloc.close);
    // Ráfaga corta: el servicio la rechaza sin dar por perdido el desafío.
    frames.framesToReturn = 2;

    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(bloc.state.phase, LivenessPhase.retry);
    expect(bloc.state.completedSteps, 0);
    expect(bloc.state.currentStep, bloc.state.steps.first);
    expect(bloc.state.error, isNull, reason: 'reintentar no es un fallo');
    expect(bloc.state.lastReason, isNotEmpty);
  });

  test('tras reintentar bien, la misma tarea avanza', () async {
    final bloc = await started();
    addTearDown(bloc.close);
    frames.framesToReturn = 2;
    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    frames.framesToReturn = null;
    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(bloc.state.completedSteps, 1);
  });

  test('completar todas las tareas dispara la verificación y aprueba',
      () async {
    final bloc = await started();
    addTearDown(bloc.close);

    for (var i = 0; i < bloc.state.steps.length; i++) {
      bloc.add(const LivenessEvent.stepCaptureRequested());
      await settle();
    }

    expect(bloc.state.phase, LivenessPhase.done);
    expect(bloc.state.isApproved, isTrue);
    expect(bloc.state.verification?.faceMatch, isTrue);
  });

  test('el token vencido corta el flujo con su propio error', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    clock.advance(const Duration(seconds: 181));
    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(bloc.state.phase, LivenessPhase.failed);
    expect(bloc.state.error, LivenessError.challengeExpired);
  });

  test('empezar de nuevo tras vencer reabre un desafío limpio', () async {
    final bloc = await started();
    addTearDown(bloc.close);
    clock.advance(const Duration(seconds: 181));
    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    bloc.add(const LivenessEvent.started());
    await settle();

    expect(bloc.state.phase, LivenessPhase.waiting);
    expect(bloc.state.completedSteps, 0);
    expect(bloc.state.error, isNull);
  });

  test('un fallo de cámara se distingue de un fallo del servicio', () async {
    final bloc = await started();
    addTearDown(bloc.close);
    frames.failWith = 'La cámara no está lista';

    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(bloc.state.phase, LivenessPhase.failed);
    expect(bloc.state.error, LivenessError.camera);
  });

  test('mientras se captura no se acepta otra ráfaga', () async {
    final bloc = await started();
    addTearDown(bloc.close);

    // Dos pulsaciones seguidas: la segunda mandaría la MISMA tarea otra vez y
    // el servidor la vería fuera de orden.
    bloc
      ..add(const LivenessEvent.stepCaptureRequested())
      ..add(const LivenessEvent.stepCaptureRequested());
    await settle();

    expect(frames.bursts, 1);
    expect(bloc.state.completedSteps, 1);
  });

  test('el bloc no inventa el orden: recorre el que mandó el servidor',
      () async {
    repo = MemoryKycRepository(
      clock: clock.call,
      steps: const [LivenessStep.derecha, LivenessStep.parpadeo],
    );
    final bloc = await started();
    addTearDown(bloc.close);

    expect(bloc.state.steps,
        const [LivenessStep.derecha, LivenessStep.parpadeo]);
    bloc.add(const LivenessEvent.stepCaptureRequested());
    await settle();
    expect(bloc.state.currentStep, LivenessStep.parpadeo);
  });
}
