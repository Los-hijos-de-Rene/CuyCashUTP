import '../../feature/account/domain/account.dart';
import '../../feature/account/domain/account_type.dart';
import '../../l10n/app_localizations.dart';

/// "Cuenta de ahorros", para títulos.
String accountTypeLabel(AppLocalizations l10n, AccountType t) => switch (t) {
  AccountType.ahorro => l10n.accountTypeAhorroLong,
  AccountType.corriente => l10n.accountTypeCorrienteLong,
  AccountType.sueldo => l10n.accountTypeSueldoLong,
};

/// "Ahorros", para líneas compactas ("Ahorros · S/ · ••••1234").
String accountTypeShort(AppLocalizations l10n, AccountType t) => switch (t) {
  AccountType.ahorro => l10n.accountTypeAhorroShort,
  AccountType.corriente => l10n.accountTypeCorrienteShort,
  AccountType.sueldo => l10n.accountTypeSueldoShort,
};

/// Cómo llama el titular a su cuenta: su nombre, o el tipo.
String accountLabel(AppLocalizations l10n, Account c) =>
    c.nombre ?? accountTypeLabel(l10n, c.tipo);
