import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account_type.dart';
import 'package:cuycash/feature/transfer/application/pending_transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/pending_transfer_store.dart';
import 'package:cuycash/feature/transfer/domain/recipient.dart';
import 'package:cuycash/feature/transfer/domain/recipient_account.dart';
import 'package:cuycash/feature/transfer/domain/recipient_directory.dart';
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

/// Un disco LENTO: la lectura espera a que el test libere [abrir]. Sirve para
/// probar que dos toques no se cuelan mientras se consulta el almacén.
class StoreLento extends MemoryPendingTransferStore {
  final abrir = Completer<void>();
  int lecturas = 0;

  @override
  Future<Map<String, PendingTransfer>> readAll(String userId) async {
    lecturas++;
    await abrir.future;
    return super.readAll(userId);
  }
}

/// Una entrada pendiente de otra intención, vigente según el reloj de prueba.
Future<void> sembrarPendiente(
  PendingTransferStore store, {
  String userId = 'u1',
  String huella = 'acc-demo-1|acc-ext-1|5000|Cena',
  DateTime? creada,
}) => store.writeAll(userId, {
  huella: PendingTransfer(
    idempotencyKey: 'clave-vieja-0001',
    createdAt: creada ?? DateTime.utc(2026, 10, 5, 17),
  ),
});

const cuentaDeDestinoDePrueba = RecipientAccount(
  cuentaId: 'acc-ext-1',
  tipo: AccountType.ahorro,
  moneda: Currency.pen,
  numeroMasked: '••••7732',
);

const directorioDePrueba = RecipientDirectory(
  dni: '87654321',
  nombreEnmascarado: 'J*** M*** R***',
  cuentas: [
    cuentaDeDestinoDePrueba,
    RecipientAccount(
      cuentaId: 'acc-ext-2',
      tipo: AccountType.corriente,
      moneda: Currency.pen,
      numeroMasked: '••••5510',
    ),
    RecipientAccount(
      cuentaId: 'acc-ext-3',
      tipo: AccountType.ahorro,
      moneda: Currency.usd,
      numeroMasked: '••••0419',
    ),
  ],
);

const destinatarioDePrueba = Recipient(
  dni: '87654321',
  nombreEnmascarado: 'J*** M*** R***',
  cuenta: cuentaDeDestinoDePrueba,
);

/// Repositorio de prueba: resuelve siempre, y envía según [alEnviar]. Anota
/// cada llamada a `enviar` con la clave, el PIN y la cuenta destino que
/// recibió.
class FakeTransferRepository implements TransferRepository {
  FakeTransferRepository({this.alEnviar, this.alResolver, this.alRecargar});

  /// Lo que responde `enviar`; por defecto, una constancia.
  final FutureResult<TransferFailure, TransferReceipt> Function(int llamada)?
  alEnviar;
  final FutureResult<TransferFailure, RecipientDirectory> Function(String dni)?
  alResolver;

  /// Lo que responde `recargar`; por defecto, una constancia.
  final FutureResult<TransferFailure, TransferReceipt> Function(int llamada)?
  alRecargar;

  final clavesRecarga = <String>[];
  int get recargas => clavesRecarga.length;

  final claves = <String>[];
  final pines = <String>[];
  final cuentasDestino = <String>[];
  int get llamadas => claves.length;

  static Result<TransferFailure, T> falla<T>(TransferFailure f) =>
      left(GlobalFailure.server(f));

  static TransferReceipt constanciaDe(Money monto) => TransferReceipt(
    transactionId: 'tx-test-1',
    monto: monto,
    fecha: DateTime.utc(2026, 10, 5, 15, 30),
  );

  @override
  FutureResult<TransferFailure, RecipientDirectory> resolverDestinatario(
    String dni,
  ) => alResolver?.call(dni) ?? Future.value(right(directorioDePrueba));

  @override
  FutureResult<TransferFailure, TransferReceipt> enviar({
    required String cuentaOrigenId,
    required String cuentaDestinoId,
    required Money monto,
    String? motivo,
    required String pin,
    required String idempotencyKey,
  }) {
    claves.add(idempotencyKey);
    pines.add(pin);
    cuentasDestino.add(cuentaDestinoId);
    return alEnviar?.call(claves.length) ??
        Future.value(right(constanciaDe(monto)));
  }

  @override
  FutureResult<TransferFailure, TransferReceipt> recargar({
    required String cuentaId,
    required Money monto,
    required String pin,
    required String idempotencyKey,
  }) {
    clavesRecarga.add(idempotencyKey);
    return alRecargar?.call(clavesRecarga.length) ??
        Future.value(right(constanciaDe(monto)));
  }
}
