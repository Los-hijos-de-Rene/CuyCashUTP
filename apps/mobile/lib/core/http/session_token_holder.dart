/// Portador en memoria del token de la sesión abierta.
///
/// El token es una preocupación de transporte, no de dominio: `AuthSession` y
/// `AuthRepository` no lo conocen (su `Memory*` tendría que inventarse uno).
/// Quien lo recibe del servidor (`HttpAuthRepository`) lo escribe aquí, y el
/// interceptor de `buildAuthenticatedDio` lo lee en cada petición. Se comparte
/// una única instancia, armada en la composición raíz.
///
/// Vive solo en memoria: persistirlo es trabajo del almacén cifrado.
class SessionTokenHolder {
  String? token;

  void clear() => token = null;
}
