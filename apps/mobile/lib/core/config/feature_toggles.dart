/// Funciones que existen en el código pero no se muestran todavía.
///
/// Apagar una aquí la oculta sin borrarla: el código, sus pruebas y su
/// backend siguen vivos, y volver a mostrarla es cambiar un `false`.
abstract final class FeatureToggles {
  /// Frecuentes en el envío: la fila de la pantalla del destinatario y el
  /// interruptor "Guardar como frecuente" de la pantalla del monto. Ocultos
  /// por ahora; el resto de la app (detalle de movimiento, backend) no cambia.
  static const frecuentesEnEnvio = false;
}
