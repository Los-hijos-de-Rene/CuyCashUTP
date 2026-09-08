/// Canal de soporte de CuyCash.
///
/// El número vive aquí y no dentro del botón: es configuración, no copy, y
/// cuando cambie tiene que cambiar en un solo sitio.
abstract final class SupportChannel {
  /// Número en formato internacional, solo dígitos (lo que espera wa.me).
  static const whatsAppNumber = '51954269667';

  /// Enlace universal de WhatsApp. Se usa `https://wa.me/…` en vez del esquema
  /// `whatsapp://` para que, si la app no está instalada, el sistema abra la
  /// versión web en lugar de fallar en silencio.
  static Uri get whatsAppUri => Uri.parse('https://wa.me/$whatsAppNumber');
}
