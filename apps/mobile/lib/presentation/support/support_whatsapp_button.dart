import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/support_channel.dart';
import '../../l10n/app_localizations.dart';

/// Botón "Escribir a soporte por WhatsApp".
///
/// Es el MISMO componente en las dos pantallas que ofrecen esa salida —
/// bloqueo de acceso y flujo de ingreso cancelado — para que el copy, el icono
/// y el número no se separen con el tiempo.
class SupportWhatsAppButton extends StatelessWidget {
  const SupportWhatsAppButton({this.onPressed, super.key});

  /// Permite sustituir la acción (en tests, o si una pantalla necesita otra
  /// cosa). Por defecto abre el chat de soporte.
  final VoidCallback? onPressed;

  Future<void> _openWhatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        SupportChannel.whatsAppUri,
        mode: LaunchMode.externalApplication,
      );
    } on Exception catch (_) {
      opened = false;
    }
    // Estas pantallas son callejones sin salida: si el enlace no abre, el
    // usuario se queda sin ninguna vía, así que el fallo se dice en vez de
    // dejar un botón que no responde.
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.supportUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GhostButton(
      label: l10n.blockedSupport,
      icon: Icons.chat_bubble_outline,
      onPressed: onPressed ?? () => _openWhatsApp(context),
    );
  }
}
