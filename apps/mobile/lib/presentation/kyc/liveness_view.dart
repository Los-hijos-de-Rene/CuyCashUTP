import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/kyc/domain/liveness_step.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/liveness_bloc.dart';

/// Pantalla del liveness guiado: preview de la cámara frontal, la instrucción
/// de la tarea en curso y el progreso.
///
/// Nunca avanza sola por tiempo: cada tarea espera el `passed:true` del
/// servidor. Un avance automático rompería la protección anti-replay, además de
/// dar por verificado a quien no hizo el gesto.
class LivenessView extends StatelessWidget {
  const LivenessView({
    required this.preview,
    required this.onVerified,
    super.key,
  });

  /// Lo que se ve arriba: el preview de la cámara real, o un relleno cuando el
  /// flavor `mock` corre sin cámara.
  final Widget preview;

  /// Se llama cuando el servicio aprueba la identidad.
  final VoidCallback onVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<LivenessBloc, LivenessState>(
      listenWhen: (previous, current) =>
          previous.isApproved != current.isApproved && current.isApproved,
      listener: (context, state) => onVerified(),
      builder: (context, state) {
        final bloc = context.read<LivenessBloc>();
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CuyCashRadii.card),
                child: preview,
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _Instruction(state: state),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _Action(
              state: state,
              onCapture: () =>
                  bloc.add(const LivenessEvent.stepCaptureRequested()),
              onRestart: () => bloc.add(const LivenessEvent.started()),
            ),
            const SizedBox(height: CuyCashSpacing.stackSm),
            Text(
              l10n.faceCaption,
              textAlign: TextAlign.center,
              style: CuyCashTypography.labelSm.copyWith(
                color: CuyCashColors.immersiveMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Qué tiene que hacer el usuario ahora mismo.
class _Instruction extends StatelessWidget {
  const _Instruction({required this.state});
  final LivenessState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = switch (state.phase) {
      LivenessPhase.preparing => l10n.livenessPreparing,
      LivenessPhase.capturing => l10n.livenessCapturing,
      LivenessPhase.evaluating => l10n.livenessEvaluating,
      LivenessPhase.verifying => l10n.livenessVerifying,
      LivenessPhase.done =>
        state.isApproved ? l10n.livenessApproved : l10n.livenessRejected,
      LivenessPhase.failed => livenessErrorText(l10n, state.error),
      LivenessPhase.waiting ||
      LivenessPhase.retry => livenessStepText(l10n, state.currentStep),
    };
    final destacaError =
        state.phase == LivenessPhase.failed ||
        (state.phase == LivenessPhase.done && !state.isApproved);

    return Column(
      children: [
        if (state.steps.isNotEmpty && state.phase != LivenessPhase.failed)
          Text(
            l10n.livenessProgress(state.completedSteps, state.steps.length),
            style: CuyCashTypography.labelSm.copyWith(
              color: CuyCashColors.immersiveMuted,
            ),
          ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: CuyCashTypography.titleMd.copyWith(
            color: destacaError
                ? CuyCashColors.error
                : CuyCashColors.immersiveOnDark,
          ),
        ),
        // El motivo que dio el servidor ayuda a corregir el gesto; sin él, el
        // usuario repite exactamente lo mismo.
        if (state.phase == LivenessPhase.retry && state.lastReason != null) ...[
          const SizedBox(height: CuyCashSpacing.stackXs),
          Text(
            state.lastReason!,
            textAlign: TextAlign.center,
            style: CuyCashTypography.labelSm.copyWith(
              color: CuyCashColors.immersiveOcre,
            ),
          ),
        ],
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.state,
    required this.onCapture,
    required this.onRestart,
  });

  final LivenessState state;
  final VoidCallback onCapture;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: switch (state.phase) {
        LivenessPhase.waiting => PrimaryButton(
          label: l10n.livenessCapture,
          onPressed: onCapture,
        ),
        LivenessPhase.retry => PrimaryButton(
          label: l10n.livenessRetry,
          onPressed: onCapture,
        ),
        LivenessPhase.failed => PrimaryButton(
          label: l10n.livenessRestart,
          onPressed: onRestart,
        ),
        LivenessPhase.done when !state.isApproved => PrimaryButton(
          label: l10n.livenessRestart,
          onPressed: onRestart,
        ),
        // Capturando, evaluando o verificando: el botón no debe estar disponible,
        // porque una segunda ráfaga llegaría fuera de orden.
        _ => const PrimaryButton(label: '', loading: true),
      },
    );
  }
}

/// Instrucción de cada tarea. El bloc no carga texto: la UI traduce.
String livenessStepText(AppLocalizations l10n, LivenessStep? step) =>
    switch (step) {
      LivenessStep.arriba => l10n.livenessStepArriba,
      LivenessStep.abajo => l10n.livenessStepAbajo,
      LivenessStep.izquierda => l10n.livenessStepIzquierda,
      LivenessStep.derecha => l10n.livenessStepDerecha,
      LivenessStep.parpadeo => l10n.livenessStepParpadeo,
      null => l10n.livenessVerifying,
    };

String livenessErrorText(AppLocalizations l10n, LivenessError? error) =>
    switch (error) {
      LivenessError.challengeExpired => l10n.livenessExpired,
      LivenessError.camera => l10n.cameraUnavailable,
      LivenessError.serviceUnavailable => l10n.errorServiceUnavailable,
      LivenessError.rejected => l10n.livenessRejected,
      LivenessError.unauthorized ||
      LivenessError.generic ||
      null => l10n.errorGeneric,
    };
