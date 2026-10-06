import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/beneficiary/domain/beneficiary.dart';
import '../../../l10n/app_localizations.dart';

/// Fila horizontal de frecuentes. Tocar uno avisa con el frecuente entero;
/// quien la usa decide qué hacer (ir al monto con su cuenta, o rellenar el
/// DNI). Sin frecuentes no ocupa
/// espacio.
class FrequentRow extends StatelessWidget {
  const FrequentRow({
    required this.beneficiarios,
    required this.onSelected,
    super.key,
  });

  final List<Beneficiary> beneficiarios;
  final ValueChanged<Beneficiary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (beneficiarios.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transferFrequentsTitle,
          style: CuyCashTypography.labelMd.copyWith(
            color: CuyCashColors.secondaryText,
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: beneficiarios.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: CuyCashSpacing.stackMd),
            itemBuilder: (context, i) {
              final b = beneficiarios[i];
              return Semantics(
                button: true,
                label: l10n.transferFrequentSemantics(b.apodo),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelected(b),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        InitialsAvatar(
                          initials: b.apodo.isEmpty
                              ? ''
                              : b.apodo.substring(0, 1).toUpperCase(),
                          size: 44,
                        ),
                        const SizedBox(height: CuyCashSpacing.stackXs),
                        Text(
                          b.apodo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CuyCashTypography.labelSm,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackMd),
      ],
    );
  }
}
