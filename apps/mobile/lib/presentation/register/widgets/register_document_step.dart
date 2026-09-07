import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'document_capture_card.dart';

/// Paso 2 · Documento. Captura simulada de frente y reverso del DNI.
class RegisterDocumentStep extends StatelessWidget {
  const RegisterDocumentStep({super.key});

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
              onCapture: () => bloc.add(const RegisterEvent.captured(DocSide.front)),
              onRetake: () => bloc.add(const RegisterEvent.captured(DocSide.front)),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            DocumentCaptureCard(
              title: l10n.dniBack,
              hint: l10n.dniBackHint,
              status: draft.dniBack,
              onCapture: () => bloc.add(const RegisterEvent.captured(DocSide.back)),
              onRetake: () => bloc.add(const RegisterEvent.captured(DocSide.back)),
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
