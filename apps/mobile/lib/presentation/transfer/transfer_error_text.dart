import 'package:intl/intl.dart';

import '../../core/format/soles.dart';
import '../../feature/transfer/domain/transfer_failure.dart';
import '../../feature/transfer/domain/transfer_limits.dart';
import '../../l10n/app_localizations.dart';

/// Texto de un fallo al BUSCAR al destinatario.
String transferResolveErrorText(
  AppLocalizations l10n,
  TransferFailure failure,
) => switch (failure) {
  RecipientNotFound() => l10n.transferErrorRecipientNotFound,
  SelfTransfer() => l10n.transferErrorSelfTransfer,
  RateLimited() => l10n.transferErrorSearchRateLimited,
  TransferNetworkFailure() => l10n.homeErrorNetwork,
  TransferUnauthenticated() => l10n.transferErrorUnauthenticated,
  InsufficientFunds() ||
  WrongPin() ||
  IdentifierLocked() ||
  DeviceLocked() ||
  AmountOutOfRange() ||
  AccountBlocked() ||
  IdempotencyKeyReused() ||
  TransferAccountNotFound() ||
  TransferUnexpectedFailure() => l10n.transferErrorSearchUnexpected,
};

/// Texto de un fallo al CONFIRMAR el envío. Cada uno dice algo distinto
/// porque el usuario hace cosas distintas.
///
/// Los fallos de red, límite de consultas e inesperados dicen "no pudimos
/// confirmar" y NUNCA "no se envió": el envío pudo haberse ejecutado. Un
/// reintento con la misma clave de idempotencia devuelve la operación
/// original en vez de cobrar otra vez.
String transferSubmitErrorText(
  AppLocalizations l10n,
  TransferFailure failure,
) => switch (failure) {
  InsufficientFunds() => l10n.transferErrorInsufficientFunds,
  WrongPin(:final intentosRestantes) => l10n.transferErrorWrongPin(
    intentosRestantes,
  ),
  IdentifierLocked(:final hasta) ||
  DeviceLocked(:final hasta) => l10n.transferErrorLocked(
    DateFormat('HH:mm').format(hasta.toLocal()),
  ),
  RecipientNotFound() => l10n.transferErrorRecipientNotFound,
  SelfTransfer() => l10n.transferErrorSelfTransfer,
  RateLimited() => l10n.transferErrorSubmitRateLimited,
  AmountOutOfRange() => l10n.transferErrorAmountOutOfRange(
    formatSoles(TransferLimits.montoMaximo),
  ),
  AccountBlocked() => l10n.transferErrorAccountBlocked,
  IdempotencyKeyReused() => l10n.transferErrorKeyReused,
  TransferAccountNotFound() => l10n.transferErrorAccountNotFound,
  TransferUnauthenticated() => l10n.transferErrorUnauthenticated,
  TransferNetworkFailure() => l10n.transferErrorNetwork,
  TransferUnexpectedFailure() => l10n.transferErrorUnexpected,
};

/// El fallo deja el resultado del envío DESCONOCIDO: el botón pasa a
/// "Reintentar" y el PIN escrito se conserva.
bool transferOutcomeUnknown(TransferFailure failure) => switch (failure) {
  TransferNetworkFailure() ||
  TransferUnexpectedFailure() ||
  RateLimited() => true,
  InsufficientFunds() ||
  WrongPin() ||
  IdentifierLocked() ||
  DeviceLocked() ||
  RecipientNotFound() ||
  SelfTransfer() ||
  AmountOutOfRange() ||
  AccountBlocked() ||
  IdempotencyKeyReused() ||
  TransferAccountNotFound() ||
  TransferUnauthenticated() => false,
};
