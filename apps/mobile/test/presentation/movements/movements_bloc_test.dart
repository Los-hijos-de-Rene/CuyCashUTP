import 'package:cuycash/feature/account/application/account_actions.dart';
import 'package:cuycash/feature/account/domain/account_failure.dart';
import 'package:cuycash/feature/account/infrastructure/memory_account_repository.dart';
import 'package:cuycash/feature/account/infrastructure/memory_ledger.dart';
import 'package:cuycash/presentation/movements/bloc/movements_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../home/scripted_account_repository.dart';

DateTime _reloj() => DateTime.utc(2026, 10, 6, 12);

void main() {
  // Los dos modos comparten la paginación: una cuenta y todas.
  for (final (modo, cuentaId) in [
    ('de una cuenta', MemoryLedger.cuentaId),
    ('de todas las cuentas', null),
  ]) {
    group('historial $modo', () {
      MovementsBloc construir(ScriptedAccountRepository repo) =>
          MovementsBloc(AccountActions(repo), cuentaId: cuentaId);

      Future<MovementsBloc> listo(ScriptedAccountRepository repo) async {
        final bloc = construir(repo);
        addTearDown(bloc.close);
        bloc.add(const MovementsEvent.started());
        await bloc.stream.firstWhere(
          (s) => s.status != MovementsStatus.loading,
        );
        return bloc;
      }

      test('la primera página trae los movimientos', () async {
        final bloc = await listo(
          ScriptedAccountRepository(MemoryAccountRepository(clock: _reloj)),
        );
        expect(bloc.state.status, MovementsStatus.ready);
        expect(bloc.state.movimientos, hasLength(3));
        expect(bloc.state.nextCursor, isNull);
        // Solo el combinado dice de qué cuenta es cada fila.
        expect(
          bloc.state.movimientos.every(
            (m) => (m.cuenta != null) == (cuentaId == null),
          ),
          isTrue,
        );
      });

      test('pedir más sin cursor no hace ninguna llamada', () async {
        final repo = ScriptedAccountRepository(MemoryAccountRepository());
        final bloc = await listo(repo);
        final antes = repo.paginas;

        bloc.add(const MovementsEvent.moreRequested());
        await Future<void>.delayed(Duration.zero);

        expect(repo.paginas, antes);
      });

      test(
        'con más páginas, pedir más añade al final y agota el cursor',
        () async {
          final bloc = await listo(
            ScriptedAccountRepository(MemoryAccountRepository(pageSize: 2)),
          );
          expect(bloc.state.movimientos, hasLength(2));
          expect(bloc.state.nextCursor, isNotNull);

          bloc.add(const MovementsEvent.moreRequested());
          await bloc.stream.firstWhere(
            (s) => !s.loadingMore && s.movimientos.length == 3,
          );

          expect(bloc.state.nextCursor, isNull);
        },
      );

      test('avisos de scroll en ráfaga piden UNA sola página', () async {
        final repo = ScriptedAccountRepository(
          MemoryAccountRepository(pageSize: 1),
          latencia: const Duration(milliseconds: 20),
        );
        final bloc = await listo(repo);
        final antes = repo.paginas;

        for (var i = 0; i < 5; i++) {
          bloc.add(const MovementsEvent.moreRequested());
        }
        await bloc.stream.firstWhere(
          (s) => !s.loadingMore && s.movimientos.length == 2,
        );
        await Future<void>.delayed(Duration.zero);

        expect(repo.paginas - antes, 1);
      });

      test('una página que falla conserva el cursor y lo dice', () async {
        final repo = ScriptedAccountRepository(
          MemoryAccountRepository(pageSize: 2),
        );
        final bloc = await listo(repo);
        final cursor = bloc.state.nextCursor;

        repo.falla = true;
        bloc.add(const MovementsEvent.moreRequested());
        await bloc.stream.firstWhere((s) => !s.loadingMore);

        expect(bloc.state.loadMoreFailed, isTrue);
        expect(bloc.state.nextCursor, cursor);
        expect(bloc.state.movimientos, hasLength(2));

        repo.falla = false;
        bloc.add(const MovementsEvent.moreRequested());
        await bloc.stream.firstWhere(
          (s) => !s.loadingMore && s.movimientos.length == 3,
        );
        expect(bloc.state.loadMoreFailed, isFalse);
      });

      test(
        'una página pedida antes de un refresco no se anexa a la lista nueva',
        () async {
          final repo = ScriptedAccountRepository(
            MemoryAccountRepository(pageSize: 1),
            latenciaConCursor: const Duration(milliseconds: 50),
          );
          final bloc = await listo(repo);

          bloc.add(const MovementsEvent.moreRequested()); // lenta
          await bloc.stream.firstWhere((s) => s.loadingMore);
          bloc.add(const MovementsEvent.refreshed()); // rápida: termina antes
          await bloc.stream.firstWhere((s) => !s.refreshing);
          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(bloc.state.movimientos, hasLength(1));
        },
      );

      test('un fallo inicial es error, y reintentar carga', () async {
        final repo = ScriptedAccountRepository(MemoryAccountRepository())
          ..falla = true;
        final bloc = await listo(repo);
        expect(bloc.state.status, MovementsStatus.error);
        expect(bloc.state.failure, isA<NetworkFailure>());

        repo.falla = false;
        bloc.add(const MovementsEvent.started());
        await bloc.stream.firstWhere((s) => s.status == MovementsStatus.ready);
        expect(bloc.state.movimientos, hasLength(3));
      });

      test(
        'un refresco fallido conserva la lista y marca refreshFailed',
        () async {
          final repo = ScriptedAccountRepository(MemoryAccountRepository());
          final bloc = await listo(repo);

          repo.falla = true;
          bloc.add(const MovementsEvent.refreshed());
          await bloc.stream.firstWhere((s) => !s.refreshing);

          expect(bloc.state.refreshFailed, isTrue);
          expect(bloc.state.movimientos, hasLength(3));
        },
      );
    });
  }
}
