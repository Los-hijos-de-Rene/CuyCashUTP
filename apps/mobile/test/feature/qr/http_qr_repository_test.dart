import 'dart:convert';
import 'dart:typed_data';

import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/core/http/authenticated_dio.dart';
import 'package:cuycash/feature/qr/domain/qr_failure.dart';
import 'package:cuycash/feature/qr/infrastructure/http_qr_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responde siempre lo mismo y guarda la petición: la forma real del backend
/// la verifica `contract_test`; aquí se fija el mapeo de cada respuesta.
class _Backend implements HttpClientAdapter {
  _Backend(this.status, this.body);

  final int status;
  final Object? body;
  DioException? throwIt;
  RequestOptions? pedido;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pedido = options;
    if (throwIt case final e?) throw e;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

HttpQrRepository _repo(_Backend backend) {
  final dio = buildAuthenticatedDio(
    baseUrl: 'http://api.test',
    deviceId: 'd1',
    readToken: () => 't1',
    onUnauthenticated: () {},
  )..httpClientAdapter = backend;
  return HttpQrRepository(dio: dio);
}

QrFailure _fallo<T>(Result<QrFailure, T> r) => r.fold(
  (l) => switch (l) {
    ServerFailure<QrFailure>(:final failure) => failure,
    _ => fail('Fallo inesperado: $l'),
  },
  (v) => fail('Se esperaba un fallo y llegó: $v'),
);

void main() {
  const pago = (
    payload: 'abc.def',
    cuentaOrigenId: 'acc-1',
    pin: '258036',
    idempotencyKey: 'qr-pay-0001',
  );

  Future<Result<QrFailure, Object>> pagar(_Backend backend) =>
      _repo(backend).pagar(
        payload: pago.payload,
        cuentaOrigenId: pago.cuentaOrigenId,
        pin: pago.pin,
        idempotencyKey: pago.idempotencyKey,
      );

  test('emitir envía céntimos y lee el cobro firmado', () async {
    final backend = _Backend(201, {
      'id': 'n1',
      'qr': 'abc.def',
      'monto_centimos': 1250,
      'moneda': 'PEN',
      'concepto': 'Almuerzo',
      'caduca_en': '2026-11-06T22:58:04+00:00',
    });
    final r = await _repo(backend).emitir(
      cuentaId: 'acc-2',
      monto: const Money.soles(1250),
      concepto: 'Almuerzo',
      idempotencyKey: 'k',
    );
    final cobro = r.getOrElse((l) => fail('$l'));
    expect(cobro.payload, 'abc.def');
    expect(cobro.cuentaId, 'acc-2');
    expect(cobro.monto, const Money.soles(1250));
    expect(cobro.expira, DateTime.utc(2026, 11, 6, 22, 58, 4));
    expect(backend.pedido?.path, '/v1/qr/emitir');
    expect(backend.pedido?.data, {
      'cuenta_id': 'acc-2',
      'monto_centimos': 1250,
      'concepto': 'Almuerzo',
    });
  });

  test('leer arma la vista previa del pagador', () async {
    final backend = _Backend(200, {
      'cuenta_destino_id': 'acc-2',
      'nombre_enmascarado': 'L*** Q***',
      'monto_centimos': 900,
      'moneda': 'USD',
      'concepto': 'Taller',
      'caduca_en': '2026-11-06T22:58:04+00:00',
      'requiere_pin': false,
    });
    final previa = (await _repo(
      backend,
    ).leer('abc.def')).getOrElse((l) => fail('$l'));
    expect(previa.payload, 'abc.def');
    expect(previa.nombreEnmascarado, 'L*** Q***');
    expect(previa.monto, const Money(900, Currency.usd));
    expect(previa.cuentaDestinoId, 'acc-2');
  });

  test('pagar siempre manda el PIN y la clave', () async {
    final backend = _Backend(201, {
      'transaction_id': 'tx-1',
      'estado': 'confirmada',
      'monto_centimos': 900,
      'moneda': 'PEN',
      'created_at': '2026-11-06T22:53:04.307679Z',
    });
    final r = await pagar(backend);
    expect(r.isRight(), isTrue);
    expect(backend.pedido?.data, {
      'qr': pago.payload,
      'cuenta_origen_id': pago.cuentaOrigenId,
      'pin': pago.pin,
      'idempotency_key': pago.idempotencyKey,
    });
  });

  final casos = <String, ({int status, Map<String, Object?> body, Type tipo})>{
    'vencido': (status: 400, body: {'code': 'QR_EXPIRED'}, tipo: QrExpired),
    'alterado': (status: 400, body: {'code': 'QR_INVALID'}, tipo: QrTampered),
    'ya pagado': (
      status: 409,
      body: {'code': 'QR_ALREADY_PAID'},
      tipo: QrAlreadyPaid,
    ),
    'sin configurar': (
      status: 503,
      body: {'code': 'QR_NOT_CONFIGURED'},
      tipo: QrUnavailable,
    ),
    'sin saldo': (
      status: 400,
      body: {'code': 'INSUFFICIENT_FUNDS'},
      tipo: QrInsufficientFunds,
    ),
    'misma cuenta': (
      status: 400,
      body: {'code': 'SAME_ACCOUNT'},
      tipo: QrSameAccount,
    ),
    'otra moneda': (
      status: 400,
      body: {'code': 'CURRENCY_MISMATCH'},
      tipo: QrCurrencyMismatch,
    ),
    'monto': (
      status: 400,
      body: {'code': 'AMOUNT_OUT_OF_RANGE'},
      tipo: QrAmountOutOfRange,
    ),
    'cuenta bloqueada': (
      status: 409,
      body: {'code': 'ACCOUNT_BLOCKED'},
      tipo: QrAccountUnavailable,
    ),
    'bloqueado': (
      status: 423,
      body: {'code': 'DEVICE_LOCKED'},
      tipo: QrLocked,
    ),
    'desconocido': (
      status: 500,
      body: {'code': 'OTRO'},
      tipo: QrUnexpectedFailure,
    ),
  };
  for (final MapEntry(key: nombre, value: caso) in casos.entries) {
    test('fallo: $nombre', () async {
      final r = await pagar(_Backend(caso.status, caso.body));
      expect(_fallo(r).runtimeType, caso.tipo);
    });
  }

  test('PIN errado trae los intentos restantes', () async {
    final r = await pagar(
      _Backend(403, {'code': 'INVALID_CREDENTIALS', 'intentos_restantes': 2}),
    );
    expect(switch (_fallo(r)) {
      QrWrongPin(:final intentosRestantes) => intentosRestantes,
      _ => -1,
    }, 2);
  });

  test('sin red es un fallo de red, no una excepción', () async {
    final backend = _Backend(200, {})
      ..throwIt = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    expect(_fallo(await pagar(backend)), isA<QrNetworkFailure>());
  });
}
