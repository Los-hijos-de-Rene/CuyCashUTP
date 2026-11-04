import '../../../feature/qr/domain/qr_failure.dart';
import '../../../l10n/app_localizations.dart';

/// Texto de un fallo de QR para el usuario. Sin códigos técnicos.
String qrErrorText(AppLocalizations l10n, QrFailure failure) => switch (failure) {
      QrExpired() => l10n.qrErrorExpired,
      QrTampered() => l10n.qrErrorTampered,
      QrInsufficientFunds() => l10n.qrErrorInsufficientFunds,
      QrWrongPin(:final intentosRestantes) =>
        l10n.qrErrorWrongPin(intentosRestantes),
      QrNetworkFailure() => l10n.qrErrorNetwork,
      QrUnavailable() => l10n.qrErrorUnavailable,
      QrUnexpectedFailure() => l10n.qrErrorUnexpected,
    };
