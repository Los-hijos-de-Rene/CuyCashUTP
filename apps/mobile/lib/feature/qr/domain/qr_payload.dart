/// El firmado por el servidor (`<id>.<firma>`, 22 + 1 + 22 caracteres
/// base64url) y el del flavor `mock` (`cuycash://qr?...`).
final _codigoQr = RegExp(
  r'(?<![A-Za-z0-9_-])[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{22}(?![A-Za-z0-9_-])'
  r'|cuycash://qr\?\S+',
);

/// Saca el código de lo que trajo la cámara o una imagen: si viene rodeado de
/// texto, se queda con el código. Sin código reconocible devuelve el texto
/// limpio y lo rechaza quien valida el QR, que es el único que decide.
String extraerCodigoQr(String texto) =>
    _codigoQr.stringMatch(texto) ?? texto.trim();
