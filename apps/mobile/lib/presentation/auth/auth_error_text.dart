import '../../l10n/app_localizations.dart';
import 'bloc/auth_bloc.dart';

/// Traduce el `AuthError` del bloc a copy es-PE (el bloc no carga texto).
String authErrorText(AppLocalizations l10n, AuthError error) => switch (error) {
      AuthError.invalidCredentials => l10n.errorInvalidCredentials,
      AuthError.identifierTaken => l10n.errorIdentifierTaken,
      AuthError.weakPin => l10n.errorWeakPin,
      AuthError.pinUnchanged => l10n.errorPinUnchanged,
      AuthError.generic => l10n.errorGeneric,
    };
