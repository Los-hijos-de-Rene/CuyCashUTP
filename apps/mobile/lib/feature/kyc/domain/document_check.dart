/// Qué impide usar una foto del DNI. Lo traduce la UI.
enum DocumentIssue {
  lowResolution,
  blurry,
  tooDark,
  tooBright,

  /// En el frente no se ve el rostro del titular.
  noFace,

  /// No se pudieron leer las 3 líneas de la parte inferior del reverso (MRZ).
  backUnreadable,

  /// El número leído del reverso no es el DNI que escribió el usuario.
  dniMismatch;

  /// Código que manda el servicio en `codes`. Null si esta versión no lo
  /// conoce: se ignora en vez de inventarle un mensaje.
  static DocumentIssue? fromWire(String code) => switch (code) {
        'low_resolution' => lowResolution,
        'blurry' => blurry,
        'too_dark' => tooDark,
        'too_bright' => tooBright,
        'no_face' => noFace,
        _ => null,
      };
}

/// Resultado de revisar UNA foto del DNI al momento de tomarla.
///
/// Es una guía temprana para que el usuario repita la foto en el paso 2 y no
/// recién al final. El veredicto que cuenta sigue siendo el de `verifyFull`,
/// que vuelve a revisar todo en el servidor.
class DocumentCheck {
  const DocumentCheck({this.issues = const [], this.dniRead});

  /// La foto sirve.
  const DocumentCheck.ok({String? dniRead}) : this(dniRead: dniRead);

  final List<DocumentIssue> issues;

  /// DNI leído del reverso, si se leyó con su dígito verificador correcto.
  final String? dniRead;

  bool get isOk => issues.isEmpty;

  /// El problema que se le muestra al usuario: uno a la vez, el primero.
  DocumentIssue? get mainIssue => issues.isEmpty ? null : issues.first;
}
