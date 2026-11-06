/// El firmado por el servidor (`<base64url>.<HMAC-SHA256 en hex>`) y el del
/// flavor `mock` (`cuycash://qr?...`).
final _codigoQr = RegExp(r'[A-Za-z0-9_-]+\.[0-9a-f]{64}|cuycash://qr\?\S+');

/// Saca el código de lo que trajo la cámara o el campo de pegar: al compartir
/// un cobro, el código viaja dentro de un mensaje y lo normal es copiarlo
/// entero. Sin código reconocible devuelve el texto limpio y lo rechaza quien
/// valida el QR, que es el único que decide.
String extraerCodigoQr(String texto) =>
    _codigoQr.stringMatch(texto) ?? texto.trim();
