import 'package:cuycash/feature/qr/domain/qr_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final firma = 'a1' * 32;
  final token = 'eyJjb25jZXB0byI6IkFsbXVlcnpvIn0.$firma';
  const demo = 'cuycash://qr?cuenta=acc-1&monto=500&firma=abc-_=';

  test('el código solo pasa tal cual', () {
    expect(extraerCodigoQr(token), token);
    expect(extraerCodigoQr(demo), demo);
  });

  test('toma el código del mensaje que comparte la app', () {
    final mensaje = 'Cóbralo con CuyCash: S/ 12.50 por «Almuerzo».\n$token';
    expect(extraerCodigoQr(mensaje), token);
    expect(
      extraerCodigoQr('Cóbralo con CuyCash: S/ 5.00 por «Taxi».\n$demo'),
      demo,
    );
  });

  test('tolera espacios y texto alrededor', () {
    expect(extraerCodigoQr('  $token\n'), token);
    expect(extraerCodigoQr('Hola, págame: $token gracias'), token);
  });

  test('un punto en el concepto no se confunde con el código', () {
    final mensaje = 'Cóbralo: S/ 1.50 por «a.b.c».\n$token';
    expect(extraerCodigoQr(mensaje), token);
  });

  test('sin código reconocible devuelve el texto para que lo rechace la API',
      () {
    expect(extraerCodigoQr('  no es un qr  '), 'no es un qr');
  });
}
