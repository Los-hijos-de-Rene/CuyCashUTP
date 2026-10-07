import 'package:core_kernel/core_kernel.dart';

import '../../core/format/money_format.dart';
import '../../feature/transfer/domain/transfer_failure.dart';
import '../../feature/transfer/domain/transfer_limits.dart';
import '../../l10n/app_localizations.dart';

/// Texto de un fallo al CONFIRMAR el depósito simulado. Red, límite de
/// consultas e inesperado dicen "no pudimos confirmar" y NUNCA "no se
/// depositó": pudo haberse acreditado, y reintentar con la misma clave no
/// cobra dos veces.
///
/// PIN, bloqueo, fondos, destinatario, moneda distinta y misma cuenta no
/// existen en un depósito (no pide PIN ni saca dinero): si llegaran, es una
/// respuesta que la app no esperaba.
String topUpErrorText(
  AppLocalizations l10n,
  TransferFailure failure,
  Currency moneda,
) => switch (failure) {
  RateLimited() => l10n.topUpErrorRateLimited,
  AmountOutOfRange() => l10n.transferErrorAmountOutOfRange(
    formatMoney(TransferLimits.montoMinimo(moneda)),
    formatMoney(TransferLimits.montoMaximo(moneda)),
  ),
  AccountBlocked() => l10n.topUpErrorAccountBlocked,
  IdempotencyKeyReused() => l10n.topUpErrorKeyReused,
  TransferAccountNotFound() => l10n.transferErrorAccountNotFound,
  TransferUnauthenticated() => l10n.transferErrorUnauthenticated,
  TransferNetworkFailure() => l10n.topUpErrorNetwork,
  WrongPin() ||
  IdentifierLocked() ||
  DeviceLocked() ||
  InsufficientFunds() ||
  RecipientNotFound() ||
  CurrencyMismatch() ||
  SameAccount() ||
  TransferUnexpectedFailure() => l10n.topUpErrorUnexpected,
};
