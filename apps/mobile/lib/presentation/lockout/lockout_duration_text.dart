import '../../l10n/app_localizations.dart';

/// Traduce la duración del PRÓXIMO bloqueo a copy es-PE ("15 minutos",
/// "1 hora", "24 horas").
///
/// El aviso no puede decir siempre 15 minutos: el bloqueo escala, y prometer
/// una espera más corta que la real es engañar al usuario justo cuando más
/// atención le presta.
String lockoutDurationText(AppLocalizations l10n, Duration duration) {
  if (duration.inHours >= 1) return l10n.durationHours(duration.inHours);
  if (duration.inMinutes >= 1) return l10n.durationMinutes(duration.inMinutes);
  return l10n.durationSeconds(duration.inSeconds);
}
