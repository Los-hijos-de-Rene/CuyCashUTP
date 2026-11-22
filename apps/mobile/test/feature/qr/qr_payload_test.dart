import 'package:cuycash/feature/qr/domain/qr_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Formato del servidor: 22 caracteres de id + '.' + 22 de firma.
  const token = 'Xq3_9aB-cD4eF5gH6iJ7kL.Mn8oP9qR0sT1uV2wX3y-_Z';
  const demo = 'cuycash://qr?cuenta=acc-1&monto=500&firma=abc-_=';

  test('el código solo pasa tal cual', () {
    expect(token.length, 45);
    expect(extraerCodigoQr(token), token);
    expect(extraerCodigoQr(demo), demo);
  });

  test('tolera espacios y texto alrededor', () {
    expect(extraerCodigoQr('  $token\n'), token);
    expect(extraerCodigoQr('Hola, págame: $token gracias'), token);
    expect(extraerCodigoQr('Págame con CuyCash.\n$demo'), demo);
  });

  test('un punto en el concepto no se confunde con el código', () {
    const mensaje = 'Cóbralo: S/ 1.50 por «a.b.c».\n$token';
    expect(extraerCodigoQr(mensaje), token);
  });

  test('un trozo de algo más largo no pasa por código', () {
    // 30 caracteres a cada lado del punto: no es un token, aunque contenga
    // uno de 22.22 dentro.
    final largo = '${'a' * 30}.${'b' * 30}';
    expect(extraerCodigoQr(largo), largo);
  });

  test('sin código reconocible devuelve el texto para que lo rechace la API',
      () {
    expect(extraerCodigoQr('  no es un qr  '), 'no es un qr');
  });
}
