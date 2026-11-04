import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../../transfer/application/transfer_actions.dart';
import '../../transfer/domain/transfer_failure.dart';
import '../domain/qr_charge.dart';
import '../domain/qr_failure.dart';
import '../domain/qr_payment_preview.dart';
import '../domain/qr_receipt.dart';
import '../domain/qr_repository.dart';

/// QR en memoria para el flavor `mock` y las pruebas.
///
/// El pago es un envío más: delega en `TransferActions.enviar`, así que mueve
/// el mismo libro mayor y respeta la idempotencia. La firma es un SHA-256 con
/// un secreto de demo; sirve para detectar alteraciones, no es la firma del
/// servidor (esa llega con la API #77).
class MemoryQrRepository implements QrRepository {
  MemoryQrRepository({
    required TransferActions transfer,
    DateTime Function()? clock,
    Duration ttl = const Duration(minutes: 15),
  })  : _transfer = transfer,
        _now = clock ?? DateTime.now,
        _ttl = ttl;

  final TransferActions _transfer;
  final DateTime Function() _now;
  final Duration _ttl;

  /// Secreto compartido por las instancias de demo: un QR generado en un
  /// teléfono se puede leer en otro con el mismo flavor.
  static const _secret = 'cuycash-demo-qr-v1';

  static const _nombreDemo = 'J*** M*** R***';

  @override
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) async {
    final expira = _now().toUtc().add(_ttl);
    final campos = <String, String>{
      'cuenta': cuentaId,
      'monto': '${monto.centimos}',
      'moneda': monto.currency.code,
      'concepto': concepto,
      'expira': expira.toIso8601String(),
      'nombre': _nombreDemo,
    };
    final payload = Uri(
      scheme: 'cuycash',
      host: 'qr',
      queryParameters: {...campos, 'firma': _firmar(campos)},
    ).toString();

    return right(
      QrCharge(
        id: 'qr-${_now().microsecondsSinceEpoch}',
        payload: payload,
        monto: monto,
        concepto: concepto,
        expira: expira,
        cuentaId: cuentaId,
      ),
    );
  }

  @override
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) async {
    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme != 'cuycash' || uri.host != 'qr') {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }
    final q = uri.queryParameters;
    final firma = q['firma'];
    if (firma == null) {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }
    final campos = Map<String, String>.of(q)..remove('firma');
    if (_firmar(campos) != firma) {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }

    final centimos = int.tryParse(q['monto'] ?? '');
    final expira = DateTime.tryParse(q['expira'] ?? '');
    final moneda = Currency.fromCode(q['moneda'] ?? '');
    final cuenta = q['cuenta'];
    final nombre = q['nombre'];
    final concepto = q['concepto'];
    if (centimos == null ||
        expira == null ||
        moneda == null ||
        cuenta == null ||
        nombre == null ||
        concepto == null) {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }
    if (!_now().toUtc().isBefore(expira.toUtc())) {
      return left(const GlobalFailure.server(QrFailure.expired()));
    }

    return right(
      QrPaymentPreview(
        payload: payload,
        nombreEnmascarado: nombre,
        monto: Money(centimos, moneda),
        concepto: concepto,
        cuentaDestinoId: cuenta,
        expira: expira,
      ),
    );
  }

  @override
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
  }) async {
    final lectura = await leer(payload);
    return lectura.match(
      (failure) async => left(failure),
      (preview) async {
        final result = await _transfer.enviar(
          cuentaOrigenId: cuentaOrigenId,
          cuentaDestinoId: preview.cuentaDestinoId,
          monto: preview.monto,
          motivo: preview.concepto,
          pin: pin,
          idempotencyKey: idempotencyKey,
        );
        return result.match(
          (failure) => left(GlobalFailure.server(_mapTransfer(failure))),
          (receipt) => right(
            QrReceipt(
              transactionId: receipt.transactionId,
              monto: receipt.monto,
              fecha: receipt.fecha,
            ),
          ),
        );
      },
    );
  }

  static QrFailure _mapTransfer(GlobalFailure<TransferFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: InsufficientFunds()) =>
          const QrFailure.insufficientFunds(),
        ServerFailure(failure: WrongPin(:final intentosRestantes)) =>
          QrFailure.wrongPin(intentosRestantes),
        ServerFailure(failure: TransferNetworkFailure()) =>
          const QrFailure.network(),
        _ => const QrFailure.unexpected(),
      };

  static String _firmar(Map<String, String> campos) {
    final claves = campos.keys.toList()..sort();
    final datos = claves.map((k) => '$k=${campos[k]}').join('&');
    final digest = sha256.convert(utf8.encode('$datos|$_secret'));
    return base64Url.encode(digest.bytes);
  }
}

/// Implementación para `local` y `production` mientras no exista la API #77:
/// devuelve un fallo explícito en vez de mover dinero falso.
class QrUnavailableRepository implements QrRepository {
  const QrUnavailableRepository();

  static const _failure = GlobalFailure<QrFailure>.server(QrFailure.unavailable());

  @override
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) async =>
      left(_failure);

  @override
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) async =>
      left(_failure);

  @override
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
  }) async =>
      left(_failure);
}
