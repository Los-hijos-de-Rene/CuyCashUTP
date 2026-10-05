import 'dart:async';

import '../../feature/auth/domain/auth_repository.dart';

/// Qué hace la app cuando el servidor rechaza la sesión: cerrarla en local.
///
/// `AppRedirect` lleva al login al emitirse `sessionChanges`. Si ya no hay
/// sesión (varios 401 en vuelo a la vez) no se repite.
void Function() closeSessionOnExpiry(AuthRepository auth) => () {
  if (auth.currentSession != null) unawaited(auth.signOut());
};
