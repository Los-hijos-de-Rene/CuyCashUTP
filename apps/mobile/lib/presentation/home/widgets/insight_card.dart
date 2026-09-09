import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Gancho de WasiBot. Hoy es una frase fija: el asistente no está construido.
class InsightCard extends StatelessWidget {
  const InsightCard({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CuyCashColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(CuyCashRadii.sm),
            ),
            child: const Icon(Icons.smart_toy_outlined,
                size: 20, color: CuyCashColors.primaryContainer),
          ),
          const SizedBox(width: CuyCashSpacing.stackSm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeBotName,
                  style: CuyCashTypography.labelSm
                      .copyWith(color: CuyCashColors.accentText),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.homeBotInsight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CuyCashTypography.labelSm,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              size: 20, color: CuyCashColors.secondaryText),
        ],
      ),
    );
  }
}
