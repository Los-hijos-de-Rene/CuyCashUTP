import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../kyc/document_capture_page.dart';
import '../bloc/register_bloc.dart';
import 'document_capture_card.dart';

/// Paso 2 · Documento. Captura real de frente y reverso del DNI.
///
/// Al servicio de verificación se le manda el FRENTE: es la cara que lleva la
/// foto, y el match biométrico compara ese rostro con el del liveness. El
/// reverso se conserva para el expediente.
class RegisterDocumentStep extends StatelessWidget {
  const RegisterDocumentStep({super.key});

  /// Abre la cámara y guarda los bytes solo si el usuario llegó a disparar.
  Future<void> _capture(
    BuildContext context, RegisterBloc bloc, DocSide side) async {
    final l10n = AppLocalizations.of(context);
    final title = side == DocSide.front ? l10n.dniFront : l10n.dniBack;
    final image = await DocumentCapturePage.open(context, title);
    if (image != null) bloc.add(RegisterEvent.captured(side, image));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final draft = state.draft;
        final count = [draft.dniFront, draft.dniBack]
            .where((s) => s == CaptureStatus.captured)
            .length;
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.documentHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.documentSubtitle,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.capturesCount(count),
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            DocumentCaptureCard(
              title: l10n.dniFront,
              hint: l10n.dniFrontHint,
              status: draft.dniFront,
              onCapture: () => _capture(context, bloc, DocSide.front),
              onRetake: () => _capture(context, bloc, DocSide.front),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            DocumentCaptureCard(
              title: l10n.dniBack,
              hint: l10n.dniBackHint,
              status: draft.dniBack,
              onCapture: () => _capture(context, bloc, DocSide.back),
              onRetake: () => _capture(context, bloc, DocSide.back),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 16, color: CuyCashColors.secondaryText),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Flexible(
                  child: Text(l10n.documentSecure,
                      style: CuyCashTypography.labelSm),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
