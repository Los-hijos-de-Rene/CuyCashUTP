import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';

/// Franja informativa opcional del OTP (icono + texto).
class OtpNotice {
  const OtpNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

/// Todo lo que cambia entre un consumidor del OTP y otro. La pantalla
/// `OtpVerificationScreen` lee de aquí y NO conoce a sus consumidores: montar
/// una configuración nueva no exige tocar su código.
class OtpConfig {
  const OtpConfig({
    required this.identifier,
    required this.title,
    required this.heading,
    required this.subtitleBuilder,
    required this.attemptsWarning,
    required this.allowChangeEmail,
    required this.cancelledRoute,
    required this.submitLabel,
    this.notice,
  });

  /// Lo que se manda al servicio: el correo en recuperación, el DNI en
  /// verificación de dispositivo.
  final String identifier;

  /// Texto de la barra superior.
  final String title;

  /// Titular de la pantalla.
  final String heading;

  /// Cuerpo, interpolado con el correo enmascarado que devuelve el servicio.
  final String Function(String maskedEmail) subtitleBuilder;

  /// Segunda línea del error: qué pasa al agotar los intentos. Cambia con el
  /// flujo (se cancela la recuperación o se cancela el ingreso).
  final String attemptsWarning;

  final bool allowChangeEmail;
  final OtpNotice? notice;

  /// Etiqueta del botón primario mientras el código sigue vigente.
  final String submitLabel;

  /// A dónde se sale cuando el reto queda cancelado.
  final String cancelledRoute;

  /// Recuperación de PIN: se puede corregir el correo, sin franja informativa.
  factory OtpConfig.recuperacion(AppLocalizations l10n, String email) =>
      OtpConfig(
        identifier: email,
        title: l10n.otpRecoveryTitle,
        heading: l10n.otpRecoveryHeading,
        subtitleBuilder: l10n.otpRecoverySubtitle,
        attemptsWarning: l10n.otpAttemptsWarningRecovery,
        allowChangeEmail: true,
        submitLabel: l10n.otpSubmit,
        cancelledRoute: AppRoutes.recuperarCancelado,
      );

  /// Teléfono nuevo: el correo no se elige (es el de la cuenta) y se avisa que
  /// verificar vincula el teléfono.
  factory OtpConfig.dispositivo(AppLocalizations l10n, String dni) => OtpConfig(
        identifier: dni,
        title: l10n.otpDeviceTitle,
        heading: l10n.otpDeviceHeading,
        subtitleBuilder: l10n.otpDeviceSubtitle,
        attemptsWarning: l10n.otpAttemptsWarningDevice,
        allowChangeEmail: false,
        submitLabel: l10n.otpSubmit,
        notice: OtpNotice(
          icon: Icons.smartphone_outlined,
          text: l10n.otpDeviceNotice,
        ),
        cancelledRoute: AppRoutes.ingresarCancelado,
      );
}
