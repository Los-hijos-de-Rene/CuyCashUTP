import 'package:flutter/material.dart';

/// Tokens de color "Eucalipto y Ocre" (DESIGN.md). Regla dura: TODA superficie
/// usa estos tokens; prohibido hex suelto en widgets.
abstract final class CuyCashColors {
  // Marca
  static const primary = Color(0xFF152A1F);          // Eucalipto profundo
  static const primaryContainer = Color(0xFF2B4034); // Eucalipto
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFD98C2B);        // Ocre (fills/acentos)
  static const accentText = Color(0xFF9B5F12);       // Ocre oscuro (texto legible)
  // Sobre Eucalipto: el ocre de marca no contrasta lo suficiente y el blanco
  // apaga la jerarquía. Estos dos son los únicos permitidos sobre `primary*`.
  static const onPrimaryContainer = Color(0xFF94AB9C); // Texto secundario
  static const accentOnDark = Color(0xFFE9A64E);       // Cifra destacada

  // Superficies
  static const surface = Color(0xFFFBF9F4);                 // Stone (fondo app)
  static const surfaceContainerLowest = Color(0xFFFFFFFF);  // Cards
  static const surfaceContainerLow = Color(0xFFF5F3EE);
  static const surfaceContainer = Color(0xFFF0EEE9);
  static const surfaceContainerHigh = Color(0xFFEAE8E3);
  static const surfaceContainerHighest = Color(0xFFE4E2DD);

  // Texto / bordes
  static const onSurface = Color(0xFF1B1C19);
  static const secondaryText = Color(0xFF6B7268);   // Sage muted
  static const outline = Color(0xFF737873);
  static const outlineVariant = Color(0xFFC2C8C2);
  static const divider = Color(0xFFEBE8E0);

  // Estados
  static const error = Color(0xFFB31D3F);           // Carmín
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const errorSoft = Color(0xFFFAE8EC);       // Fondo suave de carmín
  static const success = Color(0xFF1B7A55);         // Verde de confirmación
  static const successSoft = Color(0xFFE4F0EA);     // Fondo suave de éxito

  // Sombra ambiental verde de cards
  static const ambientShadow = Color(0x0D2B4034);   // rgba(43,64,52,0.05)

  // Paso inmersivo (reconocimiento facial): tema oscuro local, DESIGN.md.
  static const immersiveDark = Color(0xFF121712);
  static const immersiveOnDark = Color(0xFFF3F1EA);
  static const immersiveMuted = Color(0xFFA3ACA0);
  static const immersiveOcre = Color(0xFFE5A34E);
  static const immersivePanel = Color(0xFF1D2620);
}
