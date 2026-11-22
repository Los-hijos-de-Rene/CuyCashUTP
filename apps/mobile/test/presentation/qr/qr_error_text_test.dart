import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/qr/qr_error_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('es'));

  test('límite diario con cupo restante dice cuánto queda', () {
    final texto = qrErrorText(
      l10n,
      const QrFailure.dailyLimit(Money(125050, Currency.pen)),
    );
    expect(texto, contains('S/ 1,250.50'));
  });

  test('límite diario agotado no muestra "S/ 0.00"', () {
    final texto = qrErrorText(
      l10n,
      const QrFailure.dailyLimit(Money(0, Currency.pen)),
    );
    expect(texto, l10n.qrErrorDailyLimitReached);
    expect(texto, isNot(contains('0.00')));
  });
}
