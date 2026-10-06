import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/beneficiary/application/beneficiary_actions.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_failure.dart';
import 'package:cuycash/feature/beneficiary/domain/beneficiary_repository.dart';
import 'package:cuycash/feature/beneficiary/infrastructure/memory_beneficiary_repository.dart';
import 'package:cuycash/feature/transfer/application/transfer_actions.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/infrastructure/memory_transfer_repository.dart';
import 'package:cuycash/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'fake_transfer_repositories.dart';

const _cuenta = Account(
  id: MemoryTransferRepository.cuentaId,
  numero: '19100000004521',
  tipo: 'ahorro',
  moneda: Currency.pen,
  estado: 'activa',
  saldoDisponible: Money.soles(125040),
  saldoContable: Money.soles(125040),
);

const _monto = Money.soles(5000);

class _FrecuentesQueFallan implements BeneficiaryRepository {
  @override
  FutureResult<BeneficiaryFailure, List<Beneficiary>> listar() async =>
      left(const GlobalFailure.server(BeneficiaryFailure.network()));

  @override
  FutureResult<BeneficiaryFailure, Unit> guardar(
    String dni,
    String apodo,
  ) async =>
      left(const GlobalFailure.server(BeneficiaryFailure.rateLimited(null)));

  @override
  FutureResult<BeneficiaryFailure, Unit> eliminar(String id) async =>
      right(unit);
}

Future<TransferBloc> _hastaConfirmar(
  FakeTransferRepository repo,
  BeneficiaryRepository frecuentes, {
  bool guardar = true,
}) async {
  final b = TransferBloc(
    TransferActions(repo),
    pending: pendientesDePrueba(),
    userId: 'u1',
    beneficiaries: BeneficiaryActions(frecuentes),
  );
  b.add(const TransferEvent.started(_cuenta));
  b.add(const TransferEvent.recipientRequested('87654321'));
  await b.stream.firstWhere((s) => s.status == TransferStatus.ready);
  if (guardar) b.add(const TransferEvent.saveFrequentToggled(true));
  b.add(const TransferEvent.amountEntered(monto: _monto));
  b.add(const TransferEvent.confirmationOpened());
  await b.stream.firstWhere((s) => s.idempotencyKey.isNotEmpty);
  return b;
}

Future<Beneficiary?> _guardado(MemoryBeneficiaryRepository repo) async =>
    (await repo.listar()).match((_) => null, (l) => l.firstOrNull);

void main() {
  late MemoryBeneficiaryRepository frecuentes;
  setUp(() {
    frecuentes = MemoryBeneficiaryRepository(
      clock: () => DateTime.utc(2026, 10, 5, 18),
    );
  });

  test('con el interruptor encendido, un envío exitoso guarda al '
      'destinatario', () async {
    final b = await _hastaConfirmar(FakeTransferRepository(), frecuentes);
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.status == TransferStatus.done);
    await pumpEventQueue();

    final guardado = await _guardado(frecuentes);
    expect(guardado?.dni, '87654321');
    expect(guardado?.apodo, 'J*** M*** R***');
    expect(b.state.frecuenteNoGuardado, isFalse);
    await b.close();
  });

  test('el apodo escrito por el usuario es el que se guarda', () async {
    final b = await _hastaConfirmar(FakeTransferRepository(), frecuentes);
    b.add(const TransferEvent.frequentNicknameChanged('  Carlos  '));
    await pumpEventQueue();
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.status == TransferStatus.done);
    await pumpEventQueue();

    expect((await _guardado(frecuentes))?.apodo, 'Carlos');
    await b.close();
  });

  test('un apodo en blanco cae al nombre enmascarado', () async {
    final b = await _hastaConfirmar(FakeTransferRepository(), frecuentes);
    b.add(const TransferEvent.frequentNicknameChanged('   '));
    await pumpEventQueue();
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.status == TransferStatus.done);
    await pumpEventQueue();

    expect((await _guardado(frecuentes))?.apodo, 'J*** M*** R***');
    await b.close();
  });

  test('si el envío FALLA no se guarda a nadie', () async {
    final repo = FakeTransferRepository(
      alEnviar: (_) async =>
          FakeTransferRepository.falla(const TransferFailure.wrongPin(4)),
    );
    final b = await _hastaConfirmar(repo, frecuentes);
    b.add(const TransferEvent.submitted(pin: '111111'));
    await b.stream.firstWhere((s) => s.failure != null);
    await pumpEventQueue();

    expect(await _guardado(frecuentes), isNull);
    await b.close();
  });

  test('un envío con resultado desconocido tampoco guarda', () async {
    final repo = FakeTransferRepository(
      alEnviar: (_) async =>
          FakeTransferRepository.falla(const TransferFailure.network()),
    );
    final b = await _hastaConfirmar(repo, frecuentes);
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.outcomeUnknown);
    await pumpEventQueue();

    expect(await _guardado(frecuentes), isNull);
    await b.close();
  });

  test('con el interruptor apagado un envío exitoso no guarda', () async {
    final b = await _hastaConfirmar(
      FakeTransferRepository(),
      frecuentes,
      guardar: false,
    );
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.status == TransferStatus.done);
    await pumpEventQueue();

    expect(await _guardado(frecuentes), isNull);
    await b.close();
  });

  test('si guardar falla, el envío sigue hecho y se avisa', () async {
    final b = await _hastaConfirmar(
      FakeTransferRepository(),
      _FrecuentesQueFallan(),
    );
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.frecuenteNoGuardado);

    expect(b.state.status, TransferStatus.done);
    expect(b.state.constancia, isNotNull);
    await b.close();
  });

  test('el interruptor no se puede mover con la intención sellada', () async {
    final repo = FakeTransferRepository(
      alEnviar: (_) async =>
          FakeTransferRepository.falla(const TransferFailure.network()),
    );
    final b = await _hastaConfirmar(repo, frecuentes, guardar: false);
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.outcomeUnknown);

    b.add(const TransferEvent.saveFrequentToggled(true));
    await pumpEventQueue();

    expect(b.state.guardarFrecuente, isFalse);
    await b.close();
  });

  test('el apodo no se puede cambiar con la intención sellada', () async {
    final repo = FakeTransferRepository(
      alEnviar: (_) async =>
          FakeTransferRepository.falla(const TransferFailure.network()),
    );
    final b = await _hastaConfirmar(repo, frecuentes);
    b.add(const TransferEvent.submitted(pin: '000000'));
    await b.stream.firstWhere((s) => s.outcomeUnknown);

    b.add(const TransferEvent.frequentNicknameChanged('X'));
    await pumpEventQueue();

    expect(b.state.apodoFrecuente, '');
    await b.close();
  });
}
