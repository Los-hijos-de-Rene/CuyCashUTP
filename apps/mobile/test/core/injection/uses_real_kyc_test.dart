import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/core/injection/envs/shared/shared_backend_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local con la bandera usa el KYC real', () {
    expect(usesRealKyc(AppFlavor.local, enabled: true), isTrue);
  });

  test('production con la bandera usa el KYC real (ya está en Render)', () {
    expect(usesRealKyc(AppFlavor.production, enabled: true), isTrue);
  });

  test('sin la bandera se simula, en cualquier flavor', () {
    expect(usesRealKyc(AppFlavor.local, enabled: false), isFalse);
    expect(usesRealKyc(AppFlavor.production, enabled: false), isFalse);
  });

  test('mock nunca usa el KYC real', () {
    expect(usesRealKyc(AppFlavor.mock, enabled: true), isFalse);
  });
}
