import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(
    dni: '70000077',
    fullName: 'jair alberto conislla pérez',
    alias: '@jair',
  );

  test('el saludo usa el primer nombre con mayúscula inicial', () {
    expect(user.firstName, 'Jair');
  });

  test('el nombre completo se muestra con mayúscula en cada palabra', () {
    expect(user.nombreCompleto, 'Jair Alberto Conislla Pérez');
  });

  test('las iniciales siguen siendo mayúsculas', () {
    expect(user.initials, 'JA');
  });

  test('sin nombre, el saludo cae al alias y el nombre completo queda vacío',
      () {
    const sinNombre = RememberedUser(dni: '1', fullName: '', alias: '@jair');
    expect(sinNombre.firstName, '@jair');
    expect(sinNombre.nombreCompleto, '');
  });
}
