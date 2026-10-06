import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../feature/device/domain/remembered_user.dart';
import '../../../l10n/app_localizations.dart';

/// Saludo + avatar + campana. Reemplaza al `AppBar`: Inicio no necesita título,
/// necesita decirte quién eres.
class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.user, this.onNotifications, super.key});

  final RememberedUser user;

  /// Sin él no hay campana: las notificaciones aún no existen.
  final VoidCallback? onNotifications;

  /// El saludo depende de la hora del teléfono; no hay dato de servidor que
  /// consultar para esto.
  static String greetingFor(AppLocalizations l10n, int hour) {
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 19) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        InitialsAvatar(
          initials: user.initials,
          size: 44,
          background: CuyCashColors.surfaceContainerHigh,
          foreground: CuyCashColors.primaryContainer,
        ),
        const SizedBox(width: CuyCashSpacing.stackSm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingFor(l10n, DateTime.now().hour),
                style: CuyCashTypography.bodyMd,
              ),
              Text(
                user.firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CuyCashTypography.titleMd,
              ),
            ],
          ),
        ),
        if (onNotifications case final onNotifications?)
          IconButton(
            onPressed: onNotifications,
            tooltip: l10n.homeNotifications,
            icon: const Icon(
              Icons.notifications_none,
              color: CuyCashColors.primaryContainer,
            ),
            style: IconButton.styleFrom(
              backgroundColor: CuyCashColors.surfaceContainerLowest,
              side: const BorderSide(color: CuyCashColors.divider),
              minimumSize: const Size.square(44),
            ),
          ),
      ],
    );
  }
}
