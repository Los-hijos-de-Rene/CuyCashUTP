import 'package:bloc_test/bloc_test.dart';
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/domain/account_repository.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/presentation/movement/bloc/movement_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

class _SinRed implements AccountRepository {
  @override
  FutureResult<AccountFailure, List<Account>> cuentas() async =>
      left(const GlobalFailure.server(AccountFailure.network()));

  @override
  FutureResult<AccountFailure, MovementPage> movimientos(
    String cuentaId, {
    String? cursor,
  }) async => left(const GlobalFailure.server(AccountFailure.network()));

  @override
  FutureResult<AccountFailure, MovementDetail> movimiento(
    String transactionId,
  ) async => left(const GlobalFailure.noConnection());
}

void main() {
  blocTest<MovementDetailBloc, MovementDetailState>(
    'carga la ficha del movimiento',
    build: () => MovementDetailBloc(AccountActions(MemoryAccountRepository())),
    act: (bloc) => bloc.add(const MovementDetailOpened('tx-demo-1')),
    expect: () => [
      isA<MovementDetailState>().having(
        (s) => s.status,
        'status',
        MovementDetailStatus.loading,
      ),
      isA<MovementDetailState>()
          .having((s) => s.status, 'status', MovementDetailStatus.ready)
          .having((s) => s.detalle?.monto, 'monto', isNotNull),
    ],
  );

  blocTest<MovementDetailBloc, MovementDetailState>(
    'un movimiento ajeno deja la pantalla en error, no en blanco',
    build: () => MovementDetailBloc(AccountActions(MemoryAccountRepository())),
    act: (bloc) => bloc.add(const MovementDetailOpened('tx-ajena')),
    expect: () => [
      isA<MovementDetailState>().having(
        (s) => s.status,
        'status',
        MovementDetailStatus.loading,
      ),
      isA<MovementDetailState>()
          .having((s) => s.status, 'status', MovementDetailStatus.error)
          .having((s) => s.failure, 'failure', isA<AccountNotFound>()),
    ],
  );

  blocTest<MovementDetailBloc, MovementDetailState>(
    'sin conexión el error es de red, no inesperado',
    build: () => MovementDetailBloc(AccountActions(_SinRed())),
    act: (bloc) => bloc.add(const MovementDetailOpened('tx-demo-1')),
    expect: () => [
      isA<MovementDetailState>(),
      isA<MovementDetailState>()
          .having((s) => s.status, 'status', MovementDetailStatus.error)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );
}
