import 'package:intl/intl.dart';

import '../../feature/account/domain/account_failure.dart';
import '../../l10n/app_localizations.dart';

/// Texto de un fallo al ABRIR una cuenta. Red e inesperado dicen "no pudimos
/// confirmar" y NUNCA "no se abrió": pudo haberse abierto, y reintentar con la
/// misma clave no abre dos.
String openAccountErrorText(AppLocalizations l10n, AccountFailure f) =>
    switch (f) {
      AccountWrongPin(:final intentosRestantes) => l10n.transferErrorWrongPin(
        intentosRestantes,
      ),
      AccountLocked(:final hasta) => l10n.transferErrorLocked(
        DateFormat('HH:mm').format(hasta.toLocal()),
      ),
      AccountLimitReached() => l10n.openAccountErrorLimit,
      SalaryAccountExists() => l10n.openAccountErrorSalary,
      InvalidAccountCurrency() => l10n.openAccountErrorCurrency,
      InvalidAccountName() => l10n.openAccountErrorName,
      AccountKeyReused() => l10n.openAccountErrorKeyReused,
      NetworkFailure() => l10n.openAccountErrorNetwork,
      Unauthenticated() => l10n.transferErrorUnauthenticated,
      AccountNotFound() ||
      UnexpectedFailure() => l10n.openAccountErrorUnexpected,
    };
