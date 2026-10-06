import 'package:cuycash/core/env/device_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDeviceName', () {
    test('caso normal', () {
      expect(
        formatDeviceName('android', 'Samsung SM-A546E'),
        'android|Samsung SM-A546E',
      );
    });

    test('quita lo que no es ASCII imprimible', () {
      expect(
        formatDeviceName('android', 'Xiaomi Redmi Nöte'),
        'android|Xiaomi Redmi Nte',
      );
    });

    test('fabricante vacío no deja espacio tras la barra', () {
      expect(formatDeviceName('android', ' Pixel 8'), 'android|Pixel 8');
    });

    test('quita la barra vertical del modelo', () {
      expect(formatDeviceName('android', 'Pix|el 8'), 'android|Pixel 8');
    });

    test('colapsa espacios repetidos y caracteres de control', () {
      expect(formatDeviceName('ios', 'iPhone\n  14,5'), 'ios|iPhone 14,5');
    });

    test('todo no ASCII -> null', () {
      expect(formatDeviceName('android', 'ñöü'), isNull);
    });
  });
}
