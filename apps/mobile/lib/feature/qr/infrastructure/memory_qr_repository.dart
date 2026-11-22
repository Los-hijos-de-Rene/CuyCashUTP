import 'dart:convert';

import 'package:core_kernel/core_kernel.dart';
import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../../account/domain/account.dart';
import '../../transfer/application/transfer_actions.dart';
import '../../transfer/domain/transfer_failure.dart';
import '../domain/qr_charge.dart';
import '../domain/qr_failure.dart';
import '../domain/qr_limits.dart';
import '../domain/qr_payment_preview.dart';
import '../domain/qr_receipt.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_static.dart';

/// QR en memoria para el flavor `mock` y las pruebas.
///
/// El pago es un envío más: delega en `TransferActions.enviar`, así que mueve
/// el mismo libro mayor y respeta la idempotencia. La firma es un SHA-256 con
/// un secreto de demo; sirve para detectar alteraciones, no es la firma del
/// servidor. Como el backend: "Mi QR" (monto libre, revocable), cobro
/// dinámico (monto fijo, un solo pago) y límite diario de pagos con QR.
class MemoryQrRepository implements QrRepository {
  MemoryQrRepository({
    required TransferActions transfer,
    DateTime Function()? clock,
    Duration ttl = QrCharge.vigencia,
    Money Function(Currency)? limiteDiario,
  })  : _transfer = transfer,
        _now = clock ?? DateTime.now,
        _ttl = ttl,
        _limiteDiario = limiteDiario ?? QrLimits.diario;

  final TransferActions _transfer;
  final DateTime Function() _now;
  final Duration _ttl;
  final Money Function(Currency) _limiteDiario;

  /// Secreto compartido por las instancias de demo: un QR generado en un
  /// teléfono se puede leer en otro con el mismo flavor.
  static const _secret = 'cuycash-demo-qr-v1';

  static const _nombreDemo = 'J*** M*** R***';

  /// QR dinámicos ya pagados, con la clave con que se pagaron: como en el
  /// backend, un reintento con la misma clave pasa y otra clave es un segundo
  /// pago.
  final _pagados = <String, String>{};

  /// Versión vigente del "Mi QR" de cada cuenta. Regenerar la sube: los QR
  /// con una versión anterior quedan revocados.
  final _versiones = <String, int>{};

  /// Consumo del límite diario por `moneda|día de Lima`, y las claves que ya
  /// sumaron (un reintento no vuelve a sumar).
  final _consumo = <String, int>{};
  final _clavesQueSumaron = <String>{};

  @override
  FutureResult<QrFailure, QrCharge> emitir({
    required String cuentaId,
    required Money monto,
    required String concepto,
    required String idempotencyKey,
  }) async {
    final expira = _now().toUtc().add(_ttl);
    final payload = _firmado({
      'cuenta': cuentaId,
      'monto': '${monto.centimos}',
      'moneda': monto.currency.code,
      'concepto': concepto,
      'expira': expira.toIso8601String(),
      'nombre': _nombreDemo,
    });
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
  FutureResult<QrFailure, QrStatic> miQr(Account cuenta) async {
    final version = _versiones.putIfAbsent(cuenta.id, () => 1);
    return right(_estatico(cuenta, version));
  }

  @override
  FutureResult<QrFailure, QrStatic> regenerarMiQr(Account cuenta) async {
    final version = (_versiones[cuenta.id] ?? 0) + 1;
    _versiones[cuenta.id] = version;
    return right(_estatico(cuenta, version));
  }

  QrStatic _estatico(Account cuenta, int version) => QrStatic(
        payload: _firmado({
          'tipo': 'libre',
          'cuenta': cuenta.id,
          'moneda': cuenta.moneda.code,
          'nombre': _nombreDemo,
          'v': '$version',
        }),
        cuentaId: cuenta.id,
        moneda: cuenta.moneda,
      );

  @override
  FutureResult<QrFailure, QrPaymentPreview> leer(String payload) async {
    if (_pagados.containsKey(payload)) {
      return left(const GlobalFailure.server(QrFailure.alreadyPaid()));
    }
    return _validar(payload);
  }

  FutureResult<QrFailure, QrPaymentPreview> _validar(String payload) async {
    final campos = _camposFirmados(payload);
    if (campos == null) {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }
    final moneda = Currency.fromCode(campos['moneda'] ?? '');
    final cuenta = campos['cuenta'];
    final nombre = campos['nombre'];
    if (moneda == null || cuenta == null || nombre == null) {
      return left(const GlobalFailure.server(QrFailure.tampered()));
    }

    final QrCobro cobro;
    if (campos['tipo'] == 'libre') {
      final version = int.tryParse(campos['v'] ?? '');
      if (version == null) {
        return left(const GlobalFailure.server(QrFailure.tampered()));
      }
      if (version != _versiones[cuenta]) {
        return left(const GlobalFailure.server(QrFailure.revoked()));
      }
      cobro = const QrCobroLibre();
    } else {
      final centimos = int.tryParse(campos['monto'] ?? '');
      final expira = DateTime.tryParse(campos['expira'] ?? '');
      final concepto = campos['concepto'];
      if (centimos == null || expira == null || concepto == null) {
        return left(const GlobalFailure.server(QrFailure.tampered()));
      }
      if (!_now().toUtc().isBefore(expira.toUtc())) {
        return left(const GlobalFailure.server(QrFailure.expired()));
      }
      cobro = QrCobroFijo(
        monto: Money(centimos, moneda),
        concepto: concepto,
        expira: expira,
      );
    }

    return right(
      QrPaymentPreview(
        payload: payload,
        nombreEnmascarado: nombre,
        cuentaDestinoId: cuenta,
        moneda: moneda,
        cobro: cobro,
        disponibleHoy: _disponible(moneda),
      ),
    );
  }

  @override
  FutureResult<QrFailure, QrReceipt> pagar({
    required String payload,
    required String cuentaOrigenId,
    required String pin,
    required String idempotencyKey,
    Money? monto,
    String? mensaje,
  }) async {
    final pagadoCon = _pagados[payload];
    if (pagadoCon != null && pagadoCon != idempotencyKey) {
      return left(const GlobalFailure.server(QrFailure.alreadyPaid()));
    }
    final esReintento = _clavesQueSumaron.contains(idempotencyKey);
    final lectura = await _validar(payload);
    return lectura.match(
      (failure) async => left(failure),
      (preview) async {
        final (Money aPagar, String? motivo) = switch (preview.cobro) {
          QrCobroFijo(:final monto, :final concepto) => (monto, concepto),
          QrCobroLibre() => (monto ?? Money.zero(preview.moneda), mensaje),
        };
        if (aPagar.centimos <= 0) {
          return left(const GlobalFailure.server(QrFailure.amountOutOfRange()));
        }
        final disponible = _disponible(preview.moneda);
        if (!esReintento && aPagar > disponible) {
          return left(GlobalFailure.server(QrFailure.dailyLimit(disponible)));
        }
        final result = await _transfer.enviar(
          cuentaOrigenId: cuentaOrigenId,
          cuentaDestinoId: preview.cuentaDestinoId,
          monto: aPagar,
          motivo: motivo,
          pin: pin,
          idempotencyKey: idempotencyKey,
        );
        return result.match(
          (failure) => left(GlobalFailure.server(_mapTransfer(failure))),
          (receipt) {
            if (preview.cobro case QrCobroFijo()) {
              _pagados[payload] = idempotencyKey;
            }
            if (_clavesQueSumaron.add(idempotencyKey)) {
              _consumo.update(
                _claveDelDia(preview.moneda),
                (c) => c + aPagar.centimos,
                ifAbsent: () => aPagar.centimos,
              );
            }
            return right(
              QrReceipt(
                transactionId: receipt.transactionId,
                monto: receipt.monto,
                fecha: receipt.fecha,
              ),
            );
          },
        );
      },
    );
  }

  Money _disponible(Currency moneda) {
    final limite = _limiteDiario(moneda);
    final usado = _consumo[_claveDelDia(moneda)] ?? 0;
    final resta = limite.centimos - usado;
    return Money(resta < 0 ? 0 : resta, moneda);
  }

  /// El día es el calendario de Lima (UTC-5, sin horario de verano).
  String _claveDelDia(Currency moneda) {
    final lima = _now().toUtc().subtract(const Duration(hours: 5));
    return '${moneda.code}|${lima.year}-${lima.month}-${lima.day}';
  }

  static QrFailure _mapTransfer(GlobalFailure<TransferFailure> failure) =>
      switch (failure) {
        ServerFailure(failure: final f) => _mapNegocio(f),
        _ => const QrFailure.unexpected(),
      };

  static QrFailure _mapNegocio(TransferFailure failure) => switch (failure) {
        InsufficientFunds() => const QrFailure.insufficientFunds(),
        WrongPin(:final intentosRestantes) =>
          QrFailure.wrongPin(intentosRestantes),
        SameAccount() => const QrFailure.sameAccount(),
        CurrencyMismatch() => const QrFailure.currencyMismatch(),
        AmountOutOfRange() => const QrFailure.amountOutOfRange(),
        TransferNetworkFailure() => const QrFailure.network(),
        _ => const QrFailure.unexpected(),
      };

  String _firmado(Map<String, String> campos) => Uri(
        scheme: 'cuycash',
        host: 'qr',
        queryParameters: {...campos, 'firma': _firmar(campos)},
      ).toString();

  /// Los campos del QR si la firma cuadra; `null` si no es nuestro o fue
  /// alterado.
  Map<String, String>? _camposFirmados(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || uri.scheme != 'cuycash' || uri.host != 'qr') return null;
    final q = uri.queryParameters;
    final firma = q['firma'];
    if (firma == null) return null;
    final campos = Map<String, String>.of(q)..remove('firma');
    return _firmar(campos) == firma ? campos : null;
  }

  static String _firmar(Map<String, String> campos) {
    final claves = campos.keys.toList()..sort();
    final datos = claves.map((k) => '$k=${campos[k]}').join('&');
    final digest = sha256.convert(utf8.encode('$datos|$_secret'));
    return base64Url.encode(digest.bytes);
  }
}
