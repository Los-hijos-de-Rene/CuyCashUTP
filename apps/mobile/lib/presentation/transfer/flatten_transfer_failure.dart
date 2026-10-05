import 'package:core_kernel/core_kernel.dart';

import '../../feature/transfer/domain/transfer_failure.dart';

/// Aplana el `GlobalFailure` a lo que las pantallas de dinero saben decir.
/// Lo comparten el envío y la recarga.
TransferFailure flattenTransferFailure(
  GlobalFailure<TransferFailure> failure,
) => switch (failure) {
  ServerFailure(:final failure) => failure,
  NoConnection() || Timeout() => const TransferFailure.network(),
  PermissionDenied() ||
  NotFound() ||
  StorageFailure() ||
  Unexpected() => const TransferFailure.unexpected(),
};
