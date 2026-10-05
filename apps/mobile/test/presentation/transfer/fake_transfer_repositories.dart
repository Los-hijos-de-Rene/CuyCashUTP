import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/transfer/application/pending_transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/domain/recipient.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/domain/transfer_receipt.dart';
import 'package:cuycash/feature/transfer/domain/transfer_repository.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_pending_transfer_store.dart';
import 'package:fpdart/fpdart.dart';

/// Claves pendientes con reloj controlable (por defecto, fijo).
PendingTransferActions pendientesDePrueba({
  PendingTransferStore? store,
  DateTime Function()? clock,
}) => PendingTransferActions(
  store ?? MemoryPendingTransferStore(),
  clock: clock ?? () => DateTime.utc(2026, 10, 5, 18),
);

/// Un disco que no escribe: la lectura funciona, la escritura falla.
class StoreQueNoEscribe extends MemoryPendingTransferStore {
  @override
  Future<bool> writeAll(
    String userId,
    Map<String, PendingTransfer> entries,
  ) async => false;
}

/// Una entrada pendiente de otra intención, vigente según el reloj de prueba.
Future<void> sembrarPendiente(
  PendingTransferStore store, {
  String userId = 'u1',
  String huella = 'acc-demo-1|87654321|5000|Cena',
  DateTime? creada,
}) => store.writeAll(userId, {
  huella: PendingTransfer(
    idempotencyKey: 'clave-vieja-0001',
    createdAt: creada ?? DateTime.utc(2026, 10, 5, 17),
  ),
});

const destinatarioDePrueba = Recipient(
  dni: '87654321',
  nombreEnmascarado: 'J*** M*** R***',
  cuentaDestinoMasked: '••••7732',
);

/// Repositorio de prueba: resuelve siempre, y envía según [alEnviar]. Anota
/// cada llamada a `enviar` con la clave y el PIN que recibió.
class FakeTransferRepository implements TransferRepository {
  FakeTransferRepository({this.alEnviar, this.alResolver});

  /// Lo que responde `enviar`; por defecto, una constancia.
  final FutureResult<TransferFailure, TransferReceipt> Function(int llamada)?
  alEnviar;
  final FutureResult<TransferFailure, Recipient> Function(String dni)?
  alResolver;

  final claves = <String>[];
  final pines = <String>[];
  int get llamadas => claves.length;

  static Result<TransferFailure, T> falla<T>(TransferFailure f) =>
      left(GlobalFailure.server(f));

  static TransferReceipt constanciaDe(Money monto) => TransferReceipt(
    transactionId: 'tx-test-1',
    monto: monto,
    fecha: DateTime.utc(2026, 10, 5, 15, 30),
  );

  @override
  FutureResult<TransferFailure, Recipient> resolverDestinatario(String dni) =>
      alResolver?.call(dni) ?? Future.value(right(destinatarioDePrueba));

  @override
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String destinatarioDni,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) {
    claves.add(idempotencyKey);
    pines.add(pin);
    return alEnviar?.call(claves.length) ??
        Future.value(right(constanciaDe(monto)));
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  }) => throw UnimplementedError();
}
