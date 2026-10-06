import 'package:cuycash/feature/auth/domain/pin_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las mismas reglas que el backend (pin_is_valid)', () {
    expect(PinRules.isValid('839201'), isTrue);
    expect(PinRules.isValid('111111'), isFalse);
    expect(PinRules.isValid('123456'), isFalse);
    expect(PinRules.isValid('654321'), isFalse);
    expect(PinRules.isValid('12345'), isFalse);
  });
}
