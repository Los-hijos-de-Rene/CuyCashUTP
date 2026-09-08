import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Botón "Escribir a soporte por WhatsApp".
///
/// Es el MISMO componente en las dos pantallas que ofrecen esa salida —
/// bloqueo de acceso y flujo de ingreso cancelado — para que el copy y el
/// icono no se separen con el tiempo.
class SupportWhatsAppButton extends StatelessWidget {
  const SupportWhatsAppButton({this.onPressed, super.key});

  /// Abre el canal de soporte. Sin canal real cableado todavía, queda
  /// deshabilitado en vez de simular una acción que no ocurre.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GhostButton(
      label: l10n.blockedSupport,
      icon: Icons.chat_bubble_outline,
      onPressed: onPressed,
    );
  }
}
