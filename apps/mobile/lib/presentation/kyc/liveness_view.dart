import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature/kyc/domain/liveness_gestures.dart';
import '../../feature/kyc/domain/liveness_step.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/liveness_bloc.dart';
import 'widgets/face_oval_overlay.dart';

/// Pantalla del liveness: vista previa de la cámara frontal con un óvalo guía,
/// la indicación de lo que toca y el avance de los gestos.
///
/// No hay botón de captura: el encuadre y cada gesto avanzan solos en cuanto
/// el detector del teléfono los ve, como en los flujos de la industria. El
/// único botón aparece si el flujo se cae, para empezar de nuevo.
class LivenessView extends StatelessWidget {
  const LivenessView({
    required this.preview,
    required this.onVerified,
    super.key,
  });

  /// La vista previa de la cámara real, o un relleno cuando el flavor `mock`
  /// corre sin cámara.
  final Widget preview;

  /// Se llama cuando el servicio aprueba la identidad, con el ticket que el
  /// backend emitió (null en el KYC simulado de producción).
  final ValueChanged<String?> onVerified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<LivenessBloc, LivenessState>(
      listenWhen: (previous, current) =>
          (current.isApproved && !previous.isApproved) ||
          current.currentIndex > previous.currentIndex,
      listener: (context, state) {
        if (state.isApproved) {
          onVerified(state.verification?.ticket);
        } else {
          // Un gesto recién completado se "siente": confirma sin tener que
          // leer la pantalla mientras se gira la cabeza.
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CuyCashRadii.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    FaceOvalOverlay(tone: _toneFor(state)),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: CuyCashSpacing.stackLg,
                      child: _StepDots(state: state),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _Instruction(state: state),
            const SizedBox(height: CuyCashSpacing.stackLg),
            if (_canRestart(state))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: PrimaryButton(
                  label: l10n.livenessRestart,
                  onPressed: () => context
                      .read<LivenessBloc>()
                      .add(const LivenessEvent.started()),
                ),
              )
            else
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

  static bool _canRestart(LivenessState state) =>
      state.phase == LivenessPhase.failed ||
      (state.phase == LivenessPhase.done && !state.isApproved);

  static OvalTone _toneFor(LivenessState state) => switch (state.phase) {
        LivenessPhase.failed => OvalTone.error,
        LivenessPhase.done =>
          state.isApproved ? OvalTone.success : OvalTone.error,
        LivenessPhase.sending => OvalTone.success,
        LivenessPhase.performing || LivenessPhase.recentering =>
          state.framing == null ? OvalTone.active : OvalTone.idle,
        LivenessPhase.positioning =>
          state.framing == null ? OvalTone.active : OvalTone.idle,
        LivenessPhase.preparing => OvalTone.idle,
      };
}

/// Un punto por gesto del desafío: hecho, en curso o pendiente.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.state});
  final LivenessState state;

  @override
  Widget build(BuildContext context) {
    if (state.steps.isEmpty || state.phase == LivenessPhase.failed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.livenessStepOf(state.completedSteps, state.steps.length),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < state.steps.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == state.currentIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i < state.completedSteps
                    ? CuyCashColors.success
                    : (i == state.currentIndex
                        ? CuyCashColors.immersiveOcre
                        : CuyCashColors.immersiveMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Qué tiene que hacer el usuario ahora mismo, y qué corregir si algo falla.
class _Instruction extends StatelessWidget {
  const _Instruction({required this.state});
  final LivenessState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final framing = state.framing;
    final texto = switch (state.phase) {
      LivenessPhase.preparing => l10n.livenessPreparing,
      LivenessPhase.positioning => framing != null
          ? livenessFramingText(l10n, framing)
          : l10n.livenessHoldStill,
      LivenessPhase.recentering => framing != null &&
              framing != FramingIssue.notFrontal
          ? livenessFramingText(l10n, framing)
          : l10n.livenessBackToCenter,
      LivenessPhase.performing => framing != null
          ? livenessFramingText(l10n, framing)
          : livenessStepText(l10n, state.currentStep),
      LivenessPhase.sending => l10n.livenessVerifying,
      LivenessPhase.done =>
        state.isApproved ? l10n.livenessApproved : l10n.livenessRejected,
      LivenessPhase.failed => livenessErrorText(l10n, state.error),
    };
    final destacaError = state.phase == LivenessPhase.failed ||
        (state.phase == LivenessPhase.done && !state.isApproved);

    return Column(
      children: [
        // Se anuncia en voz alta con TalkBack/VoiceOver: quien no puede leer
        // la pantalla mientras gira la cabeza igual sabe qué hacer.
        Semantics(
          liveRegion: true,
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: CuyCashTypography.titleMd.copyWith(
              color: destacaError
                  ? CuyCashColors.error
                  : CuyCashColors.immersiveOnDark,
            ),
          ),
        ),
        if (state.phase == LivenessPhase.performing && state.slow) ...[
          const SizedBox(height: CuyCashSpacing.stackXs),
          Text(
            l10n.livenessStepSlow,
            textAlign: TextAlign.center,
            style: CuyCashTypography.labelSm.copyWith(
              color: CuyCashColors.immersiveOcre,
            ),
          ),
        ],
        if (state.phase == LivenessPhase.sending) ...[
          const SizedBox(height: CuyCashSpacing.stackSm),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CuyCashColors.immersiveOnDark,
            ),
          ),
        ],
      ],
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

String livenessFramingText(AppLocalizations l10n, FramingIssue issue) =>
    switch (issue) {
      FramingIssue.noFace => l10n.livenessGuideNoFace,
      FramingIssue.multipleFaces => l10n.livenessGuideMultipleFaces,
      FramingIssue.tooFar => l10n.livenessGuideTooFar,
      FramingIssue.tooClose => l10n.livenessGuideTooClose,
      FramingIssue.offCenter => l10n.livenessGuideOffCenter,
      FramingIssue.notFrontal => l10n.livenessGuideNotFrontal,
      FramingIssue.eyesClosed => l10n.livenessGuideEyesClosed,
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
