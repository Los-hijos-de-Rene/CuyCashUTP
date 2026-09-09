import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:camera/camera.dart';

import '../../../feature/kyc/application/kyc_actions.dart';
import '../../../feature/kyc/infrastructure/camera_frame_source.dart';
import '../../../l10n/app_localizations.dart';
import '../../kyc/bloc/liveness_bloc.dart';
import '../../kyc/liveness_view.dart';
import '../../kyc/widgets/camera_scope.dart';
import '../bloc/register_bloc.dart';

/// Paso 3 · Rostro. Pantalla inmersiva con el liveness guiado por el servidor.
///
/// Ya no hay simulación: cada tarea se graba con la cámara frontal y la valida
/// el servicio. El paso se marca hecho solo cuando la verificación completa
/// —documento + liveness + match— resulta aprobada.
///
/// Necesita el frente del DNI capturado en el paso 2: es la imagen contra la
/// que se compara el rostro.
class RegisterFaceStep extends StatelessWidget {
  const RegisterFaceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) =>
          previous.draft.dniFrontImage != current.draft.dniFrontImage ||
          previous.draft.faceStatus != current.draft.faceStatus,
      builder: (context, state) {
        final documento = state.draft.dniFrontImage;
        if (documento == null) {
          // Sin el frente del DNI no hay contra qué comparar el rostro.
          return _Aviso(text: l10n.faceNeedsDocument);
        }
        if (state.draft.faceStatus == FaceScanStatus.success) {
          return _Aviso(text: l10n.livenessApproved, success: true);
        }
        return _LivenessScope(documento: documento);
      },
    );
  }
}

/// Monta la cámara frontal y, con ella, el bloc del liveness.
///
/// El bloc se crea DENTRO del `CameraScope` porque necesita el controller ya
/// inicializado: crearlo antes obligaría a un `FrameSource` que todavía no
/// puede capturar.
class _LivenessScope extends StatelessWidget {
  const _LivenessScope({required this.documento});
  final Uint8List documento;

  @override
  Widget build(BuildContext context) {
    final actions = context.read<KycActions>();
    final registerBloc = context.read<RegisterBloc>();
    return CameraScope(
      lens: CameraLensDirection.front,
      builder: (context, controller) => BlocProvider(
        create: (_) => LivenessBloc(
          actions: actions,
          frameSource: CameraFrameSource(controller),
          documentImage: documento,
        )..add(const LivenessEvent.started()),
        child: LivenessView(
          onVerified: () =>
              registerBloc.add(const RegisterEvent.faceScanCompleted()),
          controller: controller,
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.text, this.success = false});
  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.verified_user_outlined : Icons.badge_outlined,
              size: 40,
              color: success
                  ? CuyCashColors.success
                  : CuyCashColors.immersiveOcre,
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Text(
              text,
              textAlign: TextAlign.center,
              style: CuyCashTypography.titleMd
                  .copyWith(color: CuyCashColors.immersiveOnDark),
            ),
          ],
        ),
      ),
    );
  }
}
