import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:camera/camera.dart';

import '../../../core/env/app_flavor.dart';
import '../../../feature/kyc/application/kyc_actions.dart';
import '../../../feature/kyc/domain/face_tracker.dart';
import '../../../feature/kyc/infrastructure/mlkit_face_tracker.dart';
import '../../../feature/kyc/infrastructure/simulated_face_tracker.dart';
import '../../../l10n/app_localizations.dart';
import '../../kyc/bloc/liveness_bloc.dart';
import '../../kyc/liveness_view.dart';
import '../../kyc/widgets/camera_scope.dart';
import '../../kyc/widgets/cover_camera_preview.dart';
import '../bloc/register_bloc.dart';

/// Paso 3 · Rostro. Pantalla inmersiva con el liveness guiado por el servidor.
///
/// La cámara frontal se analiza en vivo con ML Kit para guiar (encuadre y
/// avance de cada gesto) y, al final, el servicio valida los fotogramas clave. El paso se marca hecho solo cuando la verificación completa
/// —documento + liveness + match— resulta aprobada.
///
/// Necesita el frente del DNI capturado en el paso 2: es la imagen contra la
/// que se compara el rostro.
///
/// [active] importa más de lo que parece: el wizard usa `IndexedStack`, que
/// monta TODOS los pasos a la vez. Sin esta condición, la cámara frontal se
/// abriría en cuanto hay foto del DNI —con el usuario todavía en el paso 2— y
/// chocaría con la trasera al fotografiar el reverso: dos controllers vivos a
/// la vez fallan en la mayoría de teléfonos. Además la libera al retroceder.
class RegisterFaceStep extends StatelessWidget {
  const RegisterFaceStep({required this.active, super.key});

  /// Si este paso es el que el usuario está viendo.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) =>
          previous.draft.dniFrontImage != current.draft.dniFrontImage ||
          previous.draft.faceStatus != current.draft.faceStatus,
      builder: (context, state) {
        // Fuera de foco no se toca la cámara: el widget se va del árbol y el
        // controller se libera.
        if (!active) return const SizedBox.shrink();
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
/// inicializado: crearlo antes obligaría a un `FaceTracker` que todavía no
/// puede leer fotogramas.
class _LivenessScope extends StatelessWidget {
  const _LivenessScope({required this.documento});
  final Uint8List documento;

  @override
  Widget build(BuildContext context) {
    final esMock = context.read<AppFlavor>() == AppFlavor.mock;
    return CameraScope(
      lens: CameraLensDirection.front,
      imageFormatGroup: MlKitFaceTracker.preferredFormat,
      builder: (context, controller) => _Liveness(
        documento: documento,
        createTracker: () => MlKitFaceTracker(controller),
        preview: CoverCameraPreview(controller: controller),
      ),
      // En `mock` el flujo sigue aunque no haya cámara (el simulador de iOS no
      // tiene). Con backend real se muestra el aviso, como debe ser.
      unavailableBuilder: esMock
          ? (context, status) => _Liveness(
                documento: documento,
                createTracker: SimulatedFaceTracker.new,
                preview: const _PreviewSimulado(),
              )
          : null,
    );
  }
}

/// Arma el bloc con el tracker que corresponda (cámara real o simulado).
class _Liveness extends StatelessWidget {
  const _Liveness({
    required this.documento,
    required this.createTracker,
    required this.preview,
  });

  final Uint8List documento;

  /// Se llama UNA vez, al crear el bloc, que es quien lo libera al cerrarse.
  /// Construirlo en `build` dejaría detectores huérfanos en cada reconstrucción.
  final FaceTracker Function() createTracker;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final registerBloc = context.read<RegisterBloc>();
    return BlocProvider(
      create: (_) => LivenessBloc(
        actions: context.read<KycActions>(),
        tracker: createTracker(),
        documentImage: documento,
      )..add(const LivenessEvent.started()),
      child: LivenessView(
        preview: preview,
        onVerified: () =>
            registerBloc.add(const RegisterEvent.faceScanCompleted()),
      ),
    );
  }
}

/// Relleno del preview en `mock`: deja claro que no hay cámara detrás.
class _PreviewSimulado extends StatelessWidget {
  const _PreviewSimulado();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: CuyCashColors.immersivePanel,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                size: 32, color: CuyCashColors.immersiveMuted),
            const SizedBox(height: CuyCashSpacing.stackSm),
            Text(
              l10n.cameraSimulated,
              textAlign: TextAlign.center,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.immersiveMuted),
            ),
          ],
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
