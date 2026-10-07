import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/core/injection/envs/shared/shared_backend_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local con la bandera usa el KYC real', () {
    expect(usesRealKyc(AppFlavor.local, enabled: true), isTrue);
  });

  test('local sin la bandera simula', () {
    expect(usesRealKyc(AppFlavor.local, enabled: false), isFalse);
  });

  test('production simula aunque la config lo pida: el KYC no está en Render',
      () {
    expect(usesRealKyc(AppFlavor.production, enabled: true), isFalse);
  });
}
