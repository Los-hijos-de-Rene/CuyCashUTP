import 'package:core_kernel/core_kernel.dart';

import '../../feature/account/domain/account_failure.dart';

/// Aplana el `GlobalFailure` a lo que una pantalla de cuentas sabe decir: sin
/// conexión o agotado el tiempo es red; lo que el servidor dijo se conserva.
AccountFailure flattenAccountFailure(GlobalFailure<AccountFailure> failure) =>
    switch (failure) {
      ServerFailure(:final failure) => failure,
      NoConnection() || Timeout() => const AccountFailure.network(),
      _ => const AccountFailure.unexpected(),
    };
