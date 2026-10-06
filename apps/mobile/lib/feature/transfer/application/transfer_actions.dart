import 'package:core_kernel/core_kernel.dart';

import '../domain/recipient.dart';
import '../domain/transfer_failure.dart';
import '../domain/transfer_receipt.dart';
import '../domain/transfer_repository.dart';

/// Operaciones FINAS de movimientos de dinero (delegación directa sobre el
/// `TransferRepository`). El bloc la consume por constructor; nunca toca el
/// repo.
class TransferActions {
  const TransferActions(this._repo);

  final TransferRepository _repo;

  FutureResult<TransferFailure, Recipient> resolverDestinatario(String dni) =>
      _repo.resolverDestinatario(dni);

  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) => _repo.enviar(
    cuentaOrigenId: cuentaOrigenId,
    destinatarioDni: destinatarioDni,
    monto: monto,
    motivo: motivo,
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  }) => _repo.recargar(
    cuentaId: cuentaId,
    monto: monto,
    pin: pin,
    idempotencyKey: idempotencyKey,
  );
}
