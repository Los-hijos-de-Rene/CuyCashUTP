// APF3 · Integración (capítulo C) · prueba de contrato app ↔ backend REAL.
//
// Usa los repositorios `Http*` de producción (los mismos del flavor `local` y
// `production`) contra un `services/api` levantado. Verifica que lo que el
// backend responde lo entiende la app: si el servidor cambia un campo, la
// forma de un error o un código, esta prueba falla antes que el teléfono.
//
// NO corre con `flutter test` a secas (está fuera de `test/`, así no hay
// pruebas omitidas ni dependencia de un servidor en la suite normal):
//
//   cd services/api && QR_SIGNING_SECRET=<32+ bytes> QR_MONTO_BASE_CENTIMOS=10000 \
//     DATABASE_URL="sqlite+aiosqlite:///./contrato.db" \
//     .venv/bin/python -m uvicorn app.main:app --port 8001
//   cd apps/mobile && flutter test contract_test \
//     --dart-define=CONTRACT_API_URL=http://127.0.0.1:8001
//
// Crea titulares con DNI aleatorio: se puede repetir sin limpiar la base.
import 'dart:math';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:cuycash/core/http/session_token_holder.dart';
import 'package:cuycash/feature/account/domain/account.dart';
import 'package:cuycash/feature/account/domain/movement.dart';
import 'package:cuycash/feature/account/infrastructure/http_account_repository.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/infrastructure/http_auth_repository.dart';
import 'package:cuycash/feature/qr/domain/qr_charge.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/domain/qr_payload.dart';
import 'package:cuycash/feature/qr/domain/qr_receipt.dart';
import 'package:cuycash/feature/qr/infrastructure/http_qr_repository.dart';
import 'package:cuycash/feature/transfer/domain/transfer_failure.dart';
import 'package:cuycash/feature/transfer/infrastructure/http_transfer_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseUrl = String.fromEnvironment(
  'CONTRACT_API_URL',
  defaultValue: 'http://127.0.0.1:8001',
);
const _pin = '258036';
final _rng = Random();

/// Un teléfono: su propio `Dio`, token y dispositivo, como en la app real.
class _Phone {
  _Phone(this.dni)
    : holder = SessionTokenHolder(),
      deviceId = 'contrato-${_rng.nextInt(1 << 30)}' {
    final dio = buildAuthenticatedDio(
      baseUrl: _baseUrl,
      deviceId: deviceId,
      readToken: () => holder.token,
      onUnauthenticated: () {},
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 20),
    );
    auth = HttpAuthRepository(
      dio: dio,
      deviceId: deviceId,
      tokenHolder: holder,
    );
    accounts = HttpAccountRepository(dio: dio);
    transfers = HttpTransferRepository(dio: dio);
    qr = HttpQrRepository(dio: dio);
  }

  final String dni;
  final String deviceId;
  final SessionTokenHolder holder;
  late final HttpAuthRepository auth;
  late final HttpAccountRepository accounts;
  late final HttpTransferRepository transfers;
  late final HttpQrRepository qr;
}

String _dniAleatorio() => (10000000 + _rng.nextInt(89999999)).toString();
String _clave() => 'k${DateTime.now().microsecondsSinceEpoch}${_rng.nextInt(9999)}';

/// Falla la prueba con el motivo si el resultado es un fallo.
T _ok<F, T>(Result<F, T> r) => r.fold(
  (l) => fail('Se esperaba éxito y llegó un fallo: $l'),
  (v) => v,
);

F _servidor<F, T>(Result<F, T> r) => r.fold(
  (l) => switch (l) {
    ServerFailure<F>(:final failure) => failure,
    _ => fail('Se esperaba un fallo de negocio y llegó: $l'),
  },
  (v) => fail('Se esperaba un fallo y llegó éxito: $v'),
);

Future<_Phone> _titular(String nombres) async {
  final phone = _Phone(_dniAleatorio());
  _ok(
    await phone.auth.register(
      dni: phone.dni,
      nombres: nombres,
      apellidos: 'Prueba Contrato',
      email: '${phone.dni}@contrato.pe',
      pin: _pin,
    ),
  );
  return phone;
}

void main() {
  late _Phone ana;
  late _Phone luis;

  setUpAll(() async {
    ana = await _titular('Ana');
    luis = await _titular('Luis');
  });

  group('INT-CT · registro y sesión', () {
    test('INT-CT-01 el alta abre sesión y deja una cuenta en soles', () async {
      expect(ana.holder.token, isNotNull);
      final cuentas = _ok(await ana.accounts.cuentas());
      expect(cuentas, isNotEmpty);
      expect(cuentas.first.moneda, Currency.pen);
      expect(cuentas.first.saldoDisponible.centimos, 0);
    });

    test('INT-CT-02 DNI repetido: el error de negocio llega tipado', () async {
      final otro = _Phone(ana.dni);
      final r = await otro.auth.register(
        dni: ana.dni,
        nombres: 'Otra',
        apellidos: 'Persona',
        email: '${_dniAleatorio()}@contrato.pe',
        pin: _pin,
      );
      expect(_servidor<AuthFailure, dynamic>(r), isA<AuthFailure>());
    });

    test('INT-CT-03 PIN errado en el ingreso: intentos restantes', () async {
      final telefono = _Phone(luis.dni);
      final r = await telefono.auth.authenticate(
        identifier: luis.dni,
        pin: '111111',
      );
      expect(_servidor<AuthFailure, dynamic>(r), isA<AuthFailure>());
    });
  });

  group('INT-CT · dinero (libro mayor)', () {
    late Account origen;
    late Account destino;

    test('INT-CT-04 recargar acredita y el saldo se lee como Money', () async {
      origen = _ok(await ana.accounts.cuentas()).first;
      final recibo = _ok(
        await ana.transfers.recargar(
          cuentaId: origen.id,
          monto: const Money.soles(50000),
          idempotencyKey: _clave(),
        ),
      );
      expect(recibo.monto.centimos, 50000);
      final despues = _ok(await ana.accounts.cuentas()).first;
      expect(despues.saldoDisponible.centimos, 50000);
    });

    test('INT-CT-05 buscar por DNI devuelve nombre enmascarado y cuentas',
        () async {
      final dir = _ok(await ana.transfers.resolverDestinatario(luis.dni));
      expect(dir.cuentas, isNotEmpty);
      expect(dir.nombreEnmascarado, contains('*'));
      expect(dir.nombreEnmascarado, isNot(contains('Luis')));
      destino = _ok(await luis.accounts.cuentas()).first;
    });

    test('INT-CT-06 enviar S/ 125.50: ambos saldos y movimientos cuadran',
        () async {
      final clave = _clave();
      final recibo = _ok(
        await ana.transfers.enviar(
          cuentaOrigenId: origen.id,
          cuentaDestinoId: destino.id,
          monto: const Money.soles(12550),
          pin: _pin,
          idempotencyKey: clave,
        ),
      );
      expect(recibo.reutilizada, isFalse);
      final a = _ok(await ana.accounts.cuentas()).first;
      final l = _ok(await luis.accounts.cuentas()).first;
      expect(a.saldoDisponible.centimos, 37450);
      expect(l.saldoDisponible.centimos, 12550);

      final pagina = _ok(await luis.accounts.movimientos(destino.id));
      expect(pagina.items.first.monto.centimos, 12550);
    });

    test('INT-CT-07 la misma clave no mueve dos veces (idempotencia)',
        () async {
      final clave = _clave();
      Future<Result<TransferFailure, dynamic>> enviar() =>
          ana.transfers.enviar(
            cuentaOrigenId: origen.id,
            cuentaDestinoId: destino.id,
            monto: const Money.soles(1000),
            pin: _pin,
            idempotencyKey: clave,
          );
      final primero = _ok(await enviar());
      final segundo = _ok(await enviar());
      expect(segundo.reutilizada, isTrue);
      expect(segundo.transactionId, primero.transactionId);
      final a = _ok(await ana.accounts.cuentas()).first;
      expect(a.saldoDisponible.centimos, 37450 - 1000);
    });

    test('INT-CT-08 sin saldo: InsufficientFunds y nada se mueve', () async {
      final antes = _ok(await ana.accounts.cuentas()).first;
      final r = await ana.transfers.enviar(
        cuentaOrigenId: origen.id,
        cuentaDestinoId: destino.id,
        monto: const Money.soles(100000),
        pin: _pin,
        idempotencyKey: _clave(),
      );
      expect(_servidor<TransferFailure, dynamic>(r), isA<InsufficientFunds>());
      final despues = _ok(await ana.accounts.cuentas()).first;
      expect(despues.saldoDisponible, antes.saldoDisponible);
    });

    test('INT-CT-09 PIN errado al enviar: WrongPin y nada se mueve', () async {
      final r = await ana.transfers.enviar(
        cuentaOrigenId: origen.id,
        cuentaDestinoId: destino.id,
        monto: const Money.soles(100),
        pin: '000000',
        idempotencyKey: _clave(),
      );
      expect(_servidor<TransferFailure, dynamic>(r), isA<WrongPin>());
    });

    test('INT-CT-10 destinatario inexistente: RecipientNotFound', () async {
      final r = await ana.transfers.resolverDestinatario('99999999');
      expect(_servidor<TransferFailure, dynamic>(r), isA<RecipientNotFound>());
    });

    test('INT-CT-11 cobrar con QR: consulta previa sin mover dinero', () async {
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(1250),
          concepto: 'Almuerzo',
          idempotencyKey: _clave(),
        ),
      );
      final antes = _ok(await ana.accounts.cuentas()).first;
      final previa = _ok(await ana.qr.leer(cobro.payload));
      expect(previa.monto, const Money.soles(1250));
      expect(previa.concepto, 'Almuerzo');
      expect(previa.cuentaDestinoId, destino.id);
      expect(previa.expira.isUtc, isTrue);
      final despues = _ok(await ana.accounts.cuentas()).first;
      expect(despues.saldoDisponible, antes.saldoDisponible);
    });

    test('INT-CT-16 el mensaje compartido se lee y vence en 15 min', () async {
      final inicio = DateTime.now().toUtc();
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(300),
          concepto: 'Compartido',
          idempotencyKey: _clave(),
        ),
      );
      expect(
        cobro.expira.difference(inicio).inMinutes,
        inInclusiveRange(
          QrCharge.vigencia.inMinutes - 1,
          QrCharge.vigencia.inMinutes,
        ),
      );
      final mensaje = 'Cóbralo con CuyCash: S/ 3.00 por «Compartido».\n'
          '${cobro.payload}';
      final previa = _ok(await ana.qr.leer(extraerCodigoQr(mensaje)));
      expect(previa.monto, const Money.soles(300));
    });

    test('INT-CT-12 pagar un QR mueve ambos saldos y sale como pago QR', () async {
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(1250),
          concepto: 'Almuerzo',
          idempotencyKey: _clave(),
        ),
      );
      final origenAntes = _ok(await ana.accounts.cuentas()).first;
      final destinoAntes = _ok(await luis.accounts.cuentas()).first;
      final recibo = _ok(
        await ana.qr.pagar(
          payload: cobro.payload,
          cuentaOrigenId: origen.id,
          pin: _pin,
          idempotencyKey: _clave(),
        ),
      );
      expect(recibo.monto, const Money.soles(1250));
      final origenDespues = _ok(await ana.accounts.cuentas()).first;
      final destinoDespues = _ok(await luis.accounts.cuentas()).first;
      expect(
        origenDespues.saldoDisponible.centimos,
        origenAntes.saldoDisponible.centimos - 1250,
      );
      expect(
        destinoDespues.saldoDisponible.centimos,
        destinoAntes.saldoDisponible.centimos + 1250,
      );
      final movimientos = _ok(await ana.accounts.movimientos(origen.id));
      expect(movimientos.items.first.tipo, MovementKind.pagoQr);
    });

    test('INT-CT-13 un QR pagado no se paga otra vez: QrAlreadyPaid', () async {
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(500),
          concepto: 'Unico',
          idempotencyKey: _clave(),
        ),
      );
      FutureResult<QrFailure, QrReceipt> pagar(String clave) => ana.qr.pagar(
        payload: cobro.payload,
        cuentaOrigenId: origen.id,
        pin: _pin,
        idempotencyKey: clave,
      );
      final clave = _clave();
      _ok(await pagar(clave));
      final antes = _ok(await ana.accounts.cuentas()).first;
      // Misma clave: reintento, devuelve el pago original.
      _ok(await pagar(clave));
      expect(
        _servidor<QrFailure, dynamic>(await pagar(_clave())),
        isA<QrAlreadyPaid>(),
      );
      expect(
        _servidor<QrFailure, dynamic>(await ana.qr.leer(cobro.payload)),
        isA<QrAlreadyPaid>(),
      );
      final despues = _ok(await ana.accounts.cuentas()).first;
      expect(despues.saldoDisponible, antes.saldoDisponible);
    });

    test('INT-CT-14 QR alterado: QrTampered', () async {
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(500),
          concepto: 'Alterado',
          idempotencyKey: _clave(),
        ),
      );
      final alterado = cobro.payload.replaceRange(
        cobro.payload.length - 4,
        cobro.payload.length,
        '0000',
      );
      expect(
        _servidor<QrFailure, dynamic>(await ana.qr.leer(alterado)),
        isA<QrTampered>(),
      );
    });

    test('INT-CT-15 PIN errado al pagar: QrWrongPin y nada se mueve', () async {
      final cobro = _ok(
        await luis.qr.emitir(
          cuentaId: destino.id,
          monto: const Money.soles(500),
          concepto: 'Pin',
          idempotencyKey: _clave(),
        ),
      );
      final antes = _ok(await ana.accounts.cuentas()).first;
      final r = await ana.qr.pagar(
        payload: cobro.payload,
        cuentaOrigenId: origen.id,
        pin: '000000',
        idempotencyKey: _clave(),
      );
      expect(_servidor<QrFailure, dynamic>(r), isA<QrWrongPin>());
      final despues = _ok(await ana.accounts.cuentas()).first;
      expect(despues.saldoDisponible, antes.saldoDisponible);
    });
  });
}
