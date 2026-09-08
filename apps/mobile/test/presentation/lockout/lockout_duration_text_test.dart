import 'package:cuycash/feature/lockout/domain/lockout_policy.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/lockout/lockout_duration_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('es'));
  });

  test('la advertencia escala con el nivel del bloqueo', () {
    const policy = LockoutPolicy();

    // Sin bloqueos previos → el próximo es de 15 minutos.
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(0)), '15 minutos');
    // Ya bloqueado una vez → el siguiente es de 1 hora.
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(1)), '1 hora');
    // A partir del tercero se queda en el tope: 24 horas.
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(2)), '24 horas');
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(3)), '24 horas');
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(9)), '24 horas');
  });

  test('la política mock se anuncia en segundos', () {
    const policy = LockoutPolicy.mock();

    expect(lockoutDurationText(l10n, policy.nextLockoutFor(0)), '10 segundos');
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(1)), '20 segundos');
    expect(lockoutDurationText(l10n, policy.nextLockoutFor(2)), '30 segundos');
  });

  test('el singular no dice "1 horas"', () {
    expect(lockoutDurationText(l10n, const Duration(hours: 1)), '1 hora');
    expect(lockoutDurationText(l10n, const Duration(minutes: 1)), '1 minuto');
    expect(lockoutDurationText(l10n, const Duration(seconds: 1)), '1 segundo');
  });
}
