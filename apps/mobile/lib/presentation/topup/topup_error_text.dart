import 'package:core_kernel/core_kernel.dart';
import 'package:intl/intl.dart';

import '../../core/format/money_format.dart';
import '../../feature/transfer/domain/transfer_failure.dart';
import '../../feature/transfer/domain/transfer_limits.dart';
import '../../l10n/app_localizations.dart';

/// Texto de un fallo al CONFIRMAR la recarga. Red, límite de consultas e
/// inesperado dicen "no pudimos confirmar" y NUNCA "no se recargó": pudo
/// haberse acreditado, y reintentar con la misma clave no cobra dos veces.
///
/// Fondos insuficiente, destinatario y autotransferencia no existen en una
/// recarga: si llegaran, es una respuesta que la app no esperaba.
String topUpErrorText(
  AppLocalizations l10n,
  TransferFailure failure,
  Currency moneda,
) => switch (failure) {
  WrongPin(:final intentosRestantes) => l10n.transferErrorWrongPin(
    intentosRestantes,
  ),
  IdentifierLocked(:final hasta) || DeviceLocked(:final hasta) =>
    l10n.transferErrorLocked(DateFormat('HH:mm').format(hasta.toLocal())),
  RateLimited() => l10n.topUpErrorRateLimited,
  AmountOutOfRange() => l10n.transferErrorAmountOutOfRange(
    formatMoney(TransferLimits.montoMaximo(moneda)),
  ),
  AccountBlocked() => l10n.topUpErrorAccountBlocked,
  IdempotencyKeyReused() => l10n.topUpErrorKeyReused,
  TransferAccountNotFound() => l10n.transferErrorAccountNotFound,
  TransferUnauthenticated() => l10n.transferErrorUnauthenticated,
  TransferNetworkFailure() => l10n.topUpErrorNetwork,
  InsufficientFunds() ||
  RecipientNotFound() ||
  SelfTransfer() ||
  TransferUnexpectedFailure() => l10n.topUpErrorUnexpected,
};
