import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'face_scan_ring.dart';

/// Paso 3 · Rostro. Pantalla inmersiva oscura. En mock: al montar inicia el
/// escaneo y tras un delay lo completa (simulación de prueba de vida).
class RegisterFaceStep extends StatefulWidget {
  const RegisterFaceStep({super.key});

  @override
  State<RegisterFaceStep> createState() => _RegisterFaceStepState();
}

class _RegisterFaceStepState extends State<RegisterFaceStep> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<RegisterBloc>();
    if (bloc.state.draft.faceStatus == FaceScanStatus.idle) {
      bloc.add(const RegisterEvent.faceScanStarted());
      _timer = Timer(const Duration(seconds: 3),
          () => bloc.add(const RegisterEvent.faceScanCompleted()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final done = state.draft.faceStatus == FaceScanStatus.success;
        return Column(
          children: [
            const SizedBox(height: CuyCashSpacing.stackXl),
            Text(l10n.faceHeadline,
                textAlign: TextAlign.center,
                style: CuyCashTypography.titleMd
                    .copyWith(color: CuyCashColors.immersiveOnDark)),
            const SizedBox(height: CuyCashSpacing.stackXl),
            FaceScanRing(active: !done),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rotate_right,
                    size: 18, color: CuyCashColors.immersiveOcre),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Flexible(
                  child: Text(l10n.faceInstruction,
                      style: CuyCashTypography.bodyLg
                          .copyWith(color: CuyCashColors.immersiveOcre)),
                ),
              ],
            ),
            const SizedBox(height: CuyCashSpacing.stackXl),
            _Checklist(livenessDone: done),
            const Spacer(),
            Text(l10n.faceCaption,
                textAlign: TextAlign.center,
                style: CuyCashTypography.labelSm
                    .copyWith(color: CuyCashColors.immersiveMuted)),
            const SizedBox(height: CuyCashSpacing.stackLg),
          ],
        );
      },
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.livenessDone});
  final bool livenessDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      decoration: BoxDecoration(
        color: CuyCashColors.immersivePanel,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
      ),
      child: Column(
        children: [
          _row(l10n.faceCheckLight, true, null),
          const SizedBox(height: CuyCashSpacing.stackMd),
          _row(l10n.faceCheckUncovered, true, null),
          const SizedBox(height: CuyCashSpacing.stackMd),
          _row(l10n.faceCheckLiveness, livenessDone,
              livenessDone ? null : l10n.faceInProgress),
        ],
      ),
    );
  }

  Widget _row(String label, bool done, String? suffix) => Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.hourglass_empty,
              size: 20,
              color: done
                  ? CuyCashColors.immersiveOcre
                  : CuyCashColors.immersiveMuted),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Text(label,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.immersiveOnDark)),
          if (suffix != null) ...[
            const SizedBox(width: 6),
            Text(suffix,
                style: CuyCashTypography.labelSm
                    .copyWith(color: CuyCashColors.immersiveMuted)),
          ],
        ],
      );
}
