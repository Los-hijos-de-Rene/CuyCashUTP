# Multicuenta — Entrega 3: App, envío por cuenta — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rehacer el envío: al escribir un DNI aparece una tarjeta por cada cuenta del destinatario; tocar una lleva al monto (sin botón "Continuar"); el monto muestra la cuenta elegida; un frecuente guarda la cuenta y lleva directo al monto; las cuentas de otra moneda aparecen apagadas.

**Architecture:** `feature/transfer` pasa de "destinatario = persona" a "destinatario = cuenta": `resolverDestinatario` devuelve un `RecipientDirectory` (persona + cuentas) y `enviar` recibe `cuentaDestinoId`. `feature/beneficiary` guarda una cuenta. En presentación, `TransferBloc` guarda el directorio hallado y la cuenta elegida (`recipientSelected`), con la clave de idempotencia ligada a esa cuenta.

**Tech Stack:** Flutter, flutter_bloc + freezed, fpdart, dio, go_router, bloc_test, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-06-multicuenta-y-envio-por-cuenta-design.md` (§2 `feature/transfer` y `feature/beneficiary`, §3 "Enviar", §4 "Idempotencia en el envío").

**Depende de:** entrega 1 (contrato `resolve`/`transfers`/`beneficiaries`) y entrega 2 (`Money` con moneda, `AccountType`, `accountTypeShort`, `MemoryLedger` multicuenta).

## Global Constraints

- Reglas duras de `CLAUDE.md` (las mismas de la entrega 2): `Either` + `GlobalFailure`, failures sellados, `switch` exhaustivo, prohibido `when`/`maybeWhen`/`!`, Bloc consume `application`, tokens de `design_system`, copy es-PE en ARB, un widget público por archivo, generados commiteados.
- Un envío solo va entre cuentas de la **misma moneda**. Se puede enviar entre cuentas propias. Nunca a la misma cuenta de origen.
- La clave de idempotencia **se regenera** al cambiar la cuenta destino (o la de origen) y **se conserva** al volver al monto tras un error.
- El nombre que un tercero le puso a su cuenta nunca se muestra; el de las cuentas propias sí.
- Mock: titular `70123456` con `acc-demo-1` (ahorros S/), `acc-demo-2` (sueldo S/), `acc-demo-3` (ahorros US$). Destinatario `87654321` `J*** M*** R***` con `acc-ext-1` ahorros S/ `••••7732`, `acc-ext-2` corriente S/ `••••5510`, `acc-ext-3` ahorros US$ `••••0419`. Destinatario `43219876` `C*** A*** N***` con `acc-ext-4` ahorros S/ `••••1908`. PIN `000000`.
- No reformatear archivos que no se tocan.

## Review Focus

1. **Volver del monto al destinatario y elegir OTRA cuenta del mismo DNI:** la clave cambia; un reintento posterior nunca puede ir a la cuenta anterior. → test en Task 3.
2. **Frecuente de otra moneda que la cuenta de origen:** aviso y se queda en la pantalla; no navega ni manda nada. → test en Task 4.
3. **Escribir el propio DNI:** lista mis otras cuentas con su nombre y excluye la de origen; si no queda ninguna de la misma moneda, aviso "No tienes otra cuenta en S/". → test en Task 4.
4. **Editar el DNI mientras la búsqueda vuela y tocar una tarjeta vieja:** la tarjeta ya no está; la respuesta tardía se descarta (contador `_search`). → test en Task 3.
5. **Frecuente cuya cuenta dejó de recibir (`cuenta: null`):** rellena el DNI y busca, no navega. → test en Task 4.

---

## Task 1: Dominio y repositorios de transferencias por cuenta

**Files:**
- Create: `apps/mobile/lib/feature/transfer/domain/recipient_account.dart`
- Create: `apps/mobile/lib/feature/transfer/domain/recipient_directory.dart`
- Modify: `apps/mobile/lib/feature/transfer/domain/recipient.dart`
- Modify: `apps/mobile/lib/feature/transfer/domain/transfer_failure.dart`
- Modify: `apps/mobile/lib/feature/transfer/domain/transfer_repository.dart`
- Modify: `apps/mobile/lib/feature/transfer/application/transfer_actions.dart`
- Modify: `apps/mobile/lib/feature/transfer/application/pending_transfer_actions.dart` (`huella`)
- Modify: `apps/mobile/lib/feature/transfer/infrastructure/http_transfer_repository.dart`
- Modify: `apps/mobile/lib/feature/transfer/infrastructure/memory_transfer_repository.dart`
- Modify: `apps/mobile/test/feature/transfer/transfer_repository_contract.dart`, `http_transfer_repository_test.dart`, `memory_transfer_repository_test.dart`, `pending_transfer_store_test.dart`
- Modify: `apps/mobile/test/presentation/transfer/fake_transfer_repositories.dart`
- Modify: `apps/mobile/lib/presentation/transfer/transfer_error_text.dart`, `apps/mobile/lib/presentation/topup/topup_error_text.dart` (casos nuevos y `SelfTransfer` borrado)

**Interfaces:**
- Produces:
  - `class RecipientAccount { const RecipientAccount({required String cuentaId, required AccountType tipo, required Currency moneda, required String numeroMasked, String? nombre}); }`
  - `class RecipientDirectory { const RecipientDirectory({required String dni, required String nombreEnmascarado, required List<RecipientAccount> cuentas}); }`
  - `class Recipient { const Recipient({required String dni, required String nombreEnmascarado, required RecipientAccount cuenta}); }` — la cuenta ELEGIDA. (Se quita `cuentaDestinoMasked`; se lee `cuenta.numeroMasked`.)
  - `TransferRepository.resolverDestinatario(String dni) → FutureResult<TransferFailure, RecipientDirectory>`.
  - `TransferRepository.enviar({required String cuentaOrigenId, required String cuentaDestinoId, required Money monto, String? motivo, required String pin, required String idempotencyKey})`.
  - `TransferFailure.currencyMismatch()` → `CurrencyMismatch`, `TransferFailure.sameAccount()` → `SameAccount`. Se BORRA `selfTransfer`/`SelfTransfer`.
  - `PendingTransferActions.huella({required String cuentaId, required String cuentaDestinoId, required Money monto, String? motivo})`.
  - `MemoryTransferRepository`: `static const dniPropio`, `cuentaId` (= `MemoryLedger.cuentaId`), `dniDestino`, `dniDestino2`, `cuentaDestinoId = 'acc-ext-1'`, `cuentaDestinoCorrienteId = 'acc-ext-2'`, `cuentaDestinoDolaresId = 'acc-ext-3'`, `cuentaDestino2Id = 'acc-ext-4'`, `nombrePropioEnmascarado = 'T*** C***'`; `static ({String dni, String nombreEnmascarado, RecipientAccount cuenta})? cuentaConocida(String cuentaId)` (para frecuentes en memoria; solo terceros).

- [ ] **Step 1: Contrato (tests primero)**

En `transfer_repository_contract.dart`:
- Parámetros de `probarContratoDeTransferencias`: reemplazar `required String dniDestino` por `required String dniDestino, required String cuentaDestinoId, required String cuentaOtraMonedaId` (una cuenta de `dniDestino` en otra moneda que la de origen).
- Helper `enviar`: `String? destino` en vez de `String? dni`, y `cuentaDestinoId: destino ?? cuentaDestinoId`. `Money.soles(centimos)` (la cuenta origen es en soles).
- Reemplazar el test de resolver y añadir:

```dart
      test('un DNI conocido devuelve su nombre enmascarado y sus cuentas', () async {
        final RecipientDirectory d = valorDe(
          await construir().resolverDestinatario(dniDestino),
        );

        expect(d.dni, dniDestino);
        expect(d.nombreEnmascarado, contains('***'));
        expect(d.cuentas, isNotEmpty);
        expect(d.cuentas.map((c) => c.cuentaId), contains(cuentaDestinoId));
        for (final c in d.cuentas) {
          expect(c.numeroMasked, startsWith('••••'));
          expect(c.nombre, isNull, reason: 'el nombre de un tercero no sale');
        }
      });

      test('el propio DNI lista mis cuentas, con su nombre si lo tienen', () async {
        final d = valorDe(await construir().resolverDestinatario(dniPropio));
        expect(d.cuentas.map((c) => c.cuentaId), contains(cuentaOrigenId));
      });
```

Borrar el test que esperaba `selfTransfer` al resolver el propio DNI. En el grupo de `enviar`:

```dart
      test('a la misma cuenta de origen es sameAccount', () async {
        expect(
          falloDe(await enviar(construir(), destino: cuentaOrigenId)),
          isA<SameAccount>(),
        );
      });

      test('a una cuenta de otra moneda es currencyMismatch y no gasta PIN', () async {
        final repo = construir();
        expect(
          falloDe(await enviar(repo, destino: cuentaOtraMonedaId, pin: '999999')),
          isA<CurrencyMismatch>(),
        );
        // El PIN errado no se llegó a mirar: el siguiente envío correcto pasa.
        expect((await enviar(repo, clave: 'clave-0002')).isRight(), isTrue);
      });

      test('a una cuenta inexistente es recipientNotFound', () async {
        expect(
          falloDe(await enviar(construir(), destino: 'no-existe')),
          isA<RecipientNotFound>(),
        );
      });

      test('la misma clave hacia otra cuenta es idempotencyKeyReused', () async {
        final repo = construir();
        valorDe(await enviar(repo));
        // Otra cuenta destino válida del mismo DNI, en la misma moneda: la
        // tiene que dar el escenario (en memoria, `acc-ext-2`).
        final otra = valorDe(await repo.resolverDestinatario(dniDestino))
            .cuentas
            .firstWhere((c) => c.cuentaId != cuentaDestinoId && c.moneda == Currency.pen);
        expect(
          falloDe(await enviar(repo, destino: otra.cuentaId)),
          isA<IdempotencyKeyReused>(),
        );
      });
```

Las demás pruebas del contrato (fondos, PIN, bloqueo, presupuesto, idempotencia) se conservan cambiando `dni:` por `destino:` donde aparezca. La que usaba un DNI desconocido para gastar presupuesto pasa a usar `destino: 'no-existe'`.

En `memory_transfer_repository_test.dart` y `http_transfer_repository_test.dart`, la llamada a `probarContratoDeTransferencias` pasa `cuentaDestinoId: MemoryTransferRepository.cuentaDestinoId` y `cuentaOtraMonedaId: MemoryTransferRepository.cuentaDestinoDolaresId`. El backend simulado del test HTTP debe:
- responder `GET /v1/directory/resolve?dni=87654321` con `{dni, nombre_enmascarado, cuentas: [acc-ext-1 PEN, acc-ext-2 PEN, acc-ext-3 USD]}` (forma exacta de la entrega 1) y `dni=70123456` con las cuentas propias (`nombre` incluido);
- en `POST /v1/transfers`, leer `cuenta_destino_id` y aplicar `SAME_ACCOUNT` (400), `RECIPIENT_NOT_FOUND` (404), `CURRENCY_MISMATCH` (400) antes del PIN, e idempotencia por (clave → cuenta destino).

Test HTTP adicional:

```dart
    test('enviar manda cuenta_destino_id y no el DNI', () async {
      await repo.enviar(
        cuentaOrigenId: 'acc-demo-1', cuentaDestinoId: 'acc-ext-2',
        monto: const Money.soles(100), pin: '000000', idempotencyKey: 'clave-http-01',
      );
      final body = backend.requests.last.data as Map;
      expect(body['cuenta_destino_id'], 'acc-ext-2');
      expect(body.containsKey('destinatario_dni'), isFalse);
    });

    test('mapea CURRENCY_MISMATCH y SAME_ACCOUNT', () async {
      backend.forced = (status: 400, body: {'code': 'CURRENCY_MISMATCH'});
      expect(falloDe(await enviarCualquiera()), isA<CurrencyMismatch>());
      backend.forced = (status: 400, body: {'code': 'SAME_ACCOUNT'});
      expect(falloDe(await enviarCualquiera()), isA<SameAccount>());
    });

    test('una cuenta con moneda o tipo desconocidos en resolve es inesperado', () async {
      backend.forced = (status: 200, body: {
        'dni': '87654321', 'nombre_enmascarado': 'J***',
        'cuentas': [{'cuenta_id': 'x', 'tipo': 'ahorro', 'moneda': 'EUR', 'numero_masked': '••••1', 'nombre': null}],
      });
      expect((await repo.resolverDestinatario('87654321')).isLeft(), isTrue);
    });
```

(`enviarCualquiera`/`falloDe` son helpers locales del archivo; créalos si no existen.)

En `pending_transfer_store_test.dart`, `huella(..., destinatarioDni: ...)` → `cuentaDestinoId: ...`.

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/feature/transfer`
Expected: FAIL de compilación.

- [ ] **Step 3: Dominio**

`recipient_account.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';

import '../../account/domain/account_type.dart';

/// Una cuenta que puede recibir, tal como la informa el directorio.
///
/// Del número solo llegan los últimos cuatro dígitos. [nombre] es el que el
/// titular le puso a su cuenta, y solo viene cuando la cuenta es del que
/// pregunta (pasar dinero entre cuentas propias).
class RecipientAccount {
  const RecipientAccount({
    required this.cuentaId,
    required this.tipo,
    required this.moneda,
    required this.numeroMasked,
    this.nombre,
  });

  /// Id opaco: es lo que viaja en `POST /v1/transfers`.
  final String cuentaId;
  final AccountType tipo;
  final Currency moneda;

  /// `••••NNNN`.
  final String numeroMasked;
  final String? nombre;
}
```

`recipient_directory.dart`:

```dart
import 'recipient_account.dart';

/// Lo que devuelve buscar un DNI: la persona (nombre ENMASCARADO) y las
/// cuentas suyas que pueden recibir, en el orden del servidor.
class RecipientDirectory {
  const RecipientDirectory({
    required this.dni,
    required this.nombreEnmascarado,
    required this.cuentas,
  });

  final String dni;
  final String nombreEnmascarado;

  /// Nunca vacía en un éxito: sin cuentas activas el servidor responde 404.
  final List<RecipientAccount> cuentas;
}
```

`recipient.dart`: conservar el doc del nombre enmascarado y cambiar a:

```dart
/// El destino ELEGIDO de un envío: la persona y una de sus cuentas.
class Recipient {
  const Recipient({
    required this.dni,
    required this.nombreEnmascarado,
    required this.cuenta,
  });

  final String dni;
  final String nombreEnmascarado;
  final RecipientAccount cuenta;
}
```

`transfer_failure.dart`: borrar `selfTransfer`/`SelfTransfer`; añadir

```dart
  const factory TransferFailure.currencyMismatch() = CurrencyMismatch;
  const factory TransferFailure.sameAccount() = SameAccount;
```

```dart
/// La cuenta destino es de otra moneda que la de origen: no hay conversión.
final class CurrencyMismatch extends TransferFailure {
  const CurrencyMismatch();
}

/// La cuenta destino es la misma de origen.
final class SameAccount extends TransferFailure {
  const SameAccount();
}
```

y en `outcomeUnknown` añadirlos a la rama `=> false` (y quitar `SelfTransfer()`).

`transfer_repository.dart` y `transfer_actions.dart`: firmas de la sección Interfaces. Doc de `resolverDestinatario`: "Busca a la persona por DNI y lista sus cuentas que pueden recibir (el propio DNI lista las mías). Consume el presupuesto de consultas." Doc de `enviar`: "Envía [monto] desde [cuentaOrigenId] a [cuentaDestinoId]. Ambas deben ser de la misma moneda."

`pending_transfer_actions.dart`: `huella({required String cuentaId, required String cuentaDestinoId, required Money monto, String? motivo}) => '$cuentaId|$cuentaDestinoId|${monto.centimos}|${motivo ?? ''}'`; actualizar el doc ("cuenta + cuenta destino + monto + motivo").

- [ ] **Step 4: HTTP**

```dart
  @override
  FutureResult<TransferFailure, RecipientDirectory> resolverDestinatario(String dni) =>
      _guard(() async {
        final response = await _dio.get<dynamic>(
          '/v1/directory/resolve',
          queryParameters: {'dni': dni},
        );
        if (_failureFor(response) case final f?) {
          return left(GlobalFailure.server(f));
        }
        final j = _cuerpo(response);
        return right(RecipientDirectory(
          dni: j['dni'] as String,
          nombreEnmascarado: j['nombre_enmascarado'] as String,
          cuentas: [
            for (final c in j['cuentas'] as List)
              recipientAccountFromJson(c as Map<String, dynamic>),
          ],
        ));
      });
```

y una función de nivel superior en `recipient_account.dart` (la reutiliza el repo de frecuentes):

```dart
/// Lee la forma `{cuenta_id, tipo, moneda, numero_masked, nombre}` del
/// backend. Un tipo o una moneda desconocidos lanzan `FormatException`: quien
/// llama la convierte en fallo inesperado (nunca se adivina la moneda).
RecipientAccount recipientAccountFromJson(Map<String, dynamic> j) =>
    RecipientAccount(
      cuentaId: j['cuenta_id'] as String,
      tipo: AccountType.fromCode(j['tipo'] as String) ??
          (throw FormatException('Tipo desconocido: ${j['tipo']}')),
      moneda: Currency.fromCode(j['moneda'] as String) ??
          (throw FormatException('Moneda desconocida: ${j['moneda']}')),
      numeroMasked: j['numero_masked'] as String,
      nombre: j['nombre'] as String?,
    );
```

`enviar`: body con `'cuenta_destino_id': cuentaDestinoId` (sin `destinatario_dni`). `_failureFor`: quitar `'SELF_TRANSFER'`, añadir `'CURRENCY_MISMATCH' => const TransferFailure.currencyMismatch()`, `'SAME_ACCOUNT' => const TransferFailure.sameAccount()`.

- [ ] **Step 5: Memoria**

En `MemoryTransferRepository`:

```dart
  static const dniPropio = '70123456';
  static const nombrePropioEnmascarado = 'T*** C***';
  static const cuentaId = MemoryLedger.cuentaId;
  static const dniDestino = '87654321';
  static const dniDestino2 = '43219876';
  static const cuentaDestinoId = 'acc-ext-1';
  static const cuentaDestinoCorrienteId = 'acc-ext-2';
  static const cuentaDestinoDolaresId = 'acc-ext-3';
  static const cuentaDestino2Id = 'acc-ext-4';

  /// Padrón de terceros de la demo: por DNI, su nombre y sus cuentas.
  static const _directorio = <String, RecipientDirectory>{
    dniDestino: RecipientDirectory(
      dni: dniDestino,
      nombreEnmascarado: 'J*** M*** R***',
      cuentas: [
        RecipientAccount(cuentaId: cuentaDestinoId, tipo: AccountType.ahorro,
            moneda: Currency.pen, numeroMasked: '••••7732'),
        RecipientAccount(cuentaId: cuentaDestinoCorrienteId, tipo: AccountType.corriente,
            moneda: Currency.pen, numeroMasked: '••••5510'),
        RecipientAccount(cuentaId: cuentaDestinoDolaresId, tipo: AccountType.ahorro,
            moneda: Currency.usd, numeroMasked: '••••0419'),
      ],
    ),
    dniDestino2: RecipientDirectory(
      dni: dniDestino2,
      nombreEnmascarado: 'C*** A*** N***',
      cuentas: [
        RecipientAccount(cuentaId: cuentaDestino2Id, tipo: AccountType.ahorro,
            moneda: Currency.pen, numeroMasked: '••••1908'),
      ],
    ),
  };

  /// Una cuenta de un TERCERO de la demo por su id, con su titular; `null` si
  /// no existe. La usan los frecuentes en memoria.
  static ({String dni, String nombreEnmascarado, RecipientAccount cuenta})? cuentaConocida(
    String cuentaId,
  ) {
    for (final d in _directorio.values) {
      for (final c in d.cuentas) {
        if (c.cuentaId == cuentaId) {
          return (dni: d.dni, nombreEnmascarado: d.nombreEnmascarado, cuenta: c);
        }
      }
    }
    return null;
  }

  /// El directorio del propio titular sale del libro: sus cuentas, con nombre.
  RecipientDirectory get _propio => RecipientDirectory(
    dni: dniPropio,
    nombreEnmascarado: nombrePropioEnmascarado,
    cuentas: [
      for (final c in _ledger.cuentas)
        RecipientAccount(cuentaId: c.id, tipo: c.tipo, moneda: c.moneda,
            numeroMasked: c.numeroMasked, nombre: c.nombre),
    ],
  );

  /// Cuenta destino por id: propia (del libro) o de un tercero.
  RecipientAccount? _destino(String cuentaId) {
    for (final c in _propio.cuentas) {
      if (c.cuentaId == cuentaId) return c;
    }
    return cuentaConocida(cuentaId)?.cuenta;
  }

  @override
  FutureResult<TransferFailure, RecipientDirectory> resolverDestinatario(String dni) async {
    if (_consumirConsulta() case final f?) return _falla(f);
    if (dni == dniPropio) return right(_propio);
    return switch (_directorio[dni]) {
      final RecipientDirectory d => right(d),
      _ => _falla(const TransferFailure.recipientNotFound()),
    };
  }
```

`enviar` (orden del router de la entrega 1):

```dart
    final origen = _ledger.cuenta(cuentaOrigenId);
    if (origen == null) return _falla(const TransferFailure.accountNotFound());
    if (cuentaDestinoId == cuentaOrigenId) {
      return _falla(const TransferFailure.sameAccount());
    }
    final nota = (motivo ?? '').trim();
    final huella = 'transferencia|$cuentaOrigenId|$cuentaDestinoId|${monto.centimos}|$nota';
    final reintento = _operaciones.containsKey(idempotencyKey);
    // Un reintento no vuelve a buscar el destino ni gasta presupuesto.
    final destino = _destino(cuentaDestinoId);
    if (!reintento) {
      if (_consumirConsulta() case final f?) return _falla(f);
      if (destino == null) return _falla(const TransferFailure.recipientNotFound());
      if (destino.moneda != origen.moneda) {
        return _falla(const TransferFailure.currencyMismatch());
      }
    }
    if (_validarMonto(monto) case final f?) return _falla(f);
    if (_exigirPin(pin) case final f?) return _falla(f);
    if (!reintento && _ledger.saldoDe(cuentaOrigenId) < monto) {
      return _falla(const TransferFailure.insufficientFunds());
    }
    final esPropia = _ledger.cuenta(cuentaDestinoId) != null;
    final r = _postear(
      cuentaId: cuentaOrigenId,
      huella: huella,
      idempotencyKey: idempotencyKey,
      monto: monto,
      direccion: MovementDirection.debito,
      contraparte: esPropia
          ? nombrePropioEnmascarado
          : cuentaConocida(cuentaDestinoId)?.nombreEnmascarado,
      motivo: nota.isEmpty ? null : nota,
      cuentaDestinoMasked: destino?.numeroMasked,
    );
    // Entre cuentas propias el dinero también LLEGA: se acredita en el libro.
    if (r case Right(value: final constancia) when esPropia && !reintento) {
      _ledger.registrar(
        cuentaId: cuentaDestinoId,
        transactionId: constancia.transactionId,
        tipo: MovementKind.transferencia,
        direccion: MovementDirection.credito,
        monto: monto,
        fecha: _clock().toUtc(),
        contraparte: nombrePropioEnmascarado,
        motivo: nota.isEmpty ? null : nota,
        cuentaDestinoMasked: destino?.numeroMasked,
      );
    }
    return r;
```

`_postear` debe validar el reintento (`previa.huella != huella → idempotencyKeyReused`) ANTES de cualquier otra cosa del reintento: con huella que incluye `cuentaDestinoId`, "misma clave hacia otra cuenta" da 409 como en el backend. Actualiza el doc de la clase (datos de demo, orden de validación).

- [ ] **Step 6: Textos y fakes**

`transfer_error_text.dart`: quitar `SelfTransfer()`; en `transferResolveErrorText` añadir `CurrencyMismatch() || SameAccount()` a la rama inesperada; en `transferSubmitErrorText` añadir `CurrencyMismatch() => l10n.transferErrorCurrencyMismatch`, `SameAccount() => l10n.transferErrorSameAccount`. `topup_error_text.dart`: quitar `SelfTransfer()`, añadir los dos nuevos a la rama `topUpErrorUnexpected`. ARB:

```json
  "transferErrorCurrencyMismatch": "Solo puedes enviar entre cuentas de la misma moneda.",
  "transferErrorSameAccount": "Elige una cuenta distinta a la de origen.",
```

Borrar `transferErrorSelfTransfer` del ARB si queda sin uso. `flutter gen-l10n`.

`fake_transfer_repositories.dart`:

```dart
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
    RecipientAccount(cuentaId: 'acc-ext-2', tipo: AccountType.corriente,
        moneda: Currency.pen, numeroMasked: '••••5510'),
    RecipientAccount(cuentaId: 'acc-ext-3', tipo: AccountType.ahorro,
        moneda: Currency.usd, numeroMasked: '••••0419'),
  ],
);

const destinatarioDePrueba = Recipient(
  dni: '87654321',
  nombreEnmascarado: 'J*** M*** R***',
  cuenta: cuentaDeDestinoDePrueba,
);
```

`FakeTransferRepository`: `alResolver` devuelve `FutureResult<TransferFailure, RecipientDirectory>` (por defecto `right(directorioDePrueba)`); `enviar` con `cuentaDestinoId` (anotar también `cuentasDestino.add(cuentaDestinoId)` para que los tests del bloc lo verifiquen). `sembrarPendiente` usa la huella `'acc-demo-1|acc-ext-1|5000|Cena'`.

- [ ] **Step 7: Probar**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze`
Expected: errores SOLO en `lib/presentation/transfer/**` y `lib/feature/beneficiary/**` (los arreglan las Tasks 2–5). `flutter test test/feature/transfer` → PASS.

> Para no dejar la rama sin compilar entre commits, las Tasks 1–3 se commitean juntas al final de la Task 3. Si se ejecuta con subagentes, el revisor de la Task 1 revisa con `flutter test test/feature/transfer`.

---

## Task 2: Frecuentes por cuenta

**Files:**
- Modify: `apps/mobile/lib/feature/beneficiary/domain/beneficiary.dart`
- Modify: `apps/mobile/lib/feature/beneficiary/domain/beneficiary_failure.dart` (borrar `selfTransfer`)
- Modify: `apps/mobile/lib/feature/beneficiary/domain/beneficiary_repository.dart`
- Modify: `apps/mobile/lib/feature/beneficiary/application/beneficiary_actions.dart`
- Modify: `apps/mobile/lib/feature/beneficiary/infrastructure/http_beneficiary_repository.dart`
- Modify: `apps/mobile/lib/feature/beneficiary/infrastructure/memory_beneficiary_repository.dart`
- Modify: `apps/mobile/test/feature/beneficiary/*`

**Interfaces:**
- Consumes: `RecipientAccount`, `recipientAccountFromJson`, `MemoryTransferRepository.cuentaConocida`, `MemoryLedger` (cuentas propias).
- Produces:
  - `Beneficiary { id, dni, apodo, String? nombreEnmascarado, RecipientAccount? cuenta }`.
  - `BeneficiaryRepository.guardar({required String cuentaDestinoId, required String apodo})`.
  - `BeneficiaryActions.guardar({required String cuentaDestinoId, required String apodo})`.
  - `MemoryBeneficiaryRepository({..., MemoryLedger? ledger})` (para reconocer cuentas propias).

- [ ] **Step 1: Contrato**

En `beneficiary_repository_contract.dart`: parámetros `dniConocido`/`dniConocido2` → `cuentaConocida` (de `dniConocido`), `cuentaConocida2` (otra cuenta del MISMO `dniConocido`, misma moneda), `dniConocido` (para comprobar). Tests:

```dart
    test('guardar crea el frecuente con su cuenta', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'Carlos'));

      final b = valorDe(await repo.listar()).single;
      expect(b.dni, dniConocido);
      expect(b.apodo, 'Carlos');
      expect(b.nombreEnmascarado, contains('***'));
      expect(b.cuenta?.cuentaId, cuentaConocida);
      expect(b.cuenta?.numeroMasked, startsWith('••••'));
    });

    test('dos cuentas de la misma persona son dos frecuentes', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'A'));
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida2, apodo: 'B'));
      expect(valorDe(await repo.listar()).map((b) => b.apodo), ['B', 'A']);
    });

    test('guardar dos veces la misma cuenta actualiza el apodo', () async {
      final repo = construir();
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'A'));
      valorDe(await repo.guardar(cuentaDestinoId: cuentaConocida, apodo: 'B'));
      expect(valorDe(await repo.listar()).single.apodo, 'B');
    });

    test('una cuenta inexistente es recipientNotFound', () async {
      expect(
        falloDe(await construir().guardar(cuentaDestinoId: 'no-existe', apodo: 'X')),
        isA<BeneficiaryRecipientNotFound>(),
      );
    });
```

Borrar el test de `selfTransfer`. El resto (presupuesto, eliminar, apodo tal cual) cambia `guardar(dni, apodo)` → `guardar(cuentaDestinoId: cuentaConocida, apodo: ...)`. En el HTTP, el backend simulado sirve la forma de `GET /v1/beneficiaries` de la entrega 1 (`cuenta: {...} | null`) y acepta `{cuenta_destino_id, apodo}`; añadir un test de que `cuenta: null` se lee como `null` y uno de que una moneda desconocida en `cuenta` es fallo inesperado.

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/feature/beneficiary`
Expected: FAIL de compilación.

- [ ] **Step 3: Implementar**

`beneficiary.dart`:

```dart
/// Un frecuente: una CUENTA que el titular ya validó y guardó con un apodo.
class Beneficiary {
  const Beneficiary({
    required this.id,
    required this.dni,
    required this.apodo,
    this.nombreEnmascarado,
    this.cuenta,
  });

  final String id;
  final String dni;
  final String apodo;

  /// `null` si esa persona ya no figura como cliente.
  final String? nombreEnmascarado;

  /// La cuenta guardada; `null` si dejó de poder recibir (bloqueada o
  /// cerrada). Sin ella, tocar el frecuente vuelve a buscar por DNI.
  final RecipientAccount? cuenta;
}
```

HTTP `listar`: `cuenta: switch (b['cuenta']) { final Map<String, dynamic> c => recipientAccountFromJson(c), _ => null }`. `guardar`: body `{'cuenta_destino_id': cuentaDestinoId, 'apodo': apodo}`. `_failureFor`: quitar `'SELF_TRANSFER'`.

Memoria: filas `({String id, String cuentaId, String apodo})`; `guardar` valida formato de apodo, consume presupuesto, busca la cuenta (`_ledger?.cuenta(id)` como propia → dni `MemoryTransferRepository.dniPropio`, nombre `nombrePropioEnmascarado`, cuenta con `nombre`; o `MemoryTransferRepository.cuentaConocida(id)`), y si no existe → `recipientNotFound`; upsert por `cuentaId`. `listar` reconstruye `Beneficiary` con esos datos. Actualizar el doc de la clase.

`mock_dependencies.dart`: `MemoryBeneficiaryRepository(clock: DateTime.now, ledger: ledger)`.

- [ ] **Step 4: Probar**

Run: `cd apps/mobile && flutter test test/feature/beneficiary`
Expected: PASS.

---

## Task 3: `TransferBloc` con directorio y cuenta elegida

**Files:**
- Modify: `apps/mobile/lib/presentation/transfer/bloc/transfer_bloc.dart`, `transfer_event.dart`, `transfer_state.dart` (+ `.freezed.dart`)
- Modify: `apps/mobile/test/presentation/transfer/transfer_bloc_test.dart`, `transfer_bloc_frequent_test.dart`

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces:
  - `TransferState.directorio: RecipientDirectory?` (lo hallado al buscar), `TransferState.destinatario: Recipient?` (lo elegido).
  - `TransferEvent.recipientSelected(Recipient destinatario)`.
  - Al buscar (`recipientRequested`) se limpian `directorio` y `destinatario` y se borra la clave. Al elegir: si la moneda difiere de la de origen → `failure: CurrencyMismatch`, no cambia el destinatario; si es la cuenta de origen → `failure: SameAccount`; si cambia `cuenta.cuentaId` respecto al anterior → clave `''` (nace de nuevo al abrir la confirmación); si es la misma → clave intacta.
  - `_saveFrequent` llama `guardar(cuentaDestinoId: d.cuenta.cuentaId, apodo: ...)`.

- [ ] **Step 1: Tests**

En `transfer_bloc_test.dart` (adaptar los existentes: `TransferState.destinatario` ahora se fija con `recipientSelected`, no con `recipientRequested`; `huella` con cuenta destino; `FakeTransferRepository.cuentasDestino`). Nuevos:

```dart
  blocTest<TransferBloc, TransferState>(
    'buscar un DNI guarda sus cuentas, sin elegir ninguna',
    build: () => _bloc(FakeTransferRepository()),
    act: (b) {
      b.add(TransferEvent.started(_cuentaOrigen));
      b.add(const TransferEvent.recipientRequested('87654321'));
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.directorio?.cuentas, hasLength(3));
      expect(b.state.destinatario, isNull);
    },
  );

  blocTest<TransferBloc, TransferState>(
    'elegir otra cuenta del mismo DNI tras abrir la confirmación cambia la clave',
    build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
    act: (b) async {
      b.add(TransferEvent.started(_cuentaOrigen));
      b.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
      b.add(const TransferEvent.amountEntered(monto: Money.soles(5000)));
      b.add(const TransferEvent.confirmationOpened());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(TransferEvent.recipientSelected(Recipient(
        dni: '87654321', nombreEnmascarado: 'J*** M*** R***',
        cuenta: directorioDePrueba.cuentas[1],
      )));
      b.add(const TransferEvent.confirmationOpened());
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.destinatario?.cuenta.cuentaId, 'acc-ext-2');
      expect(b.state.idempotencyKey, 'k-2'); // k-1 era de la cuenta anterior
    },
  );

  blocTest<TransferBloc, TransferState>(
    'elegir la misma cuenta otra vez conserva la clave',
    build: () => _bloc(FakeTransferRepository(), newKey: _claves()),
    act: (b) async {
      b.add(TransferEvent.started(_cuentaOrigen));
      b.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
      b.add(const TransferEvent.amountEntered(monto: Money.soles(5000)));
      b.add(const TransferEvent.confirmationOpened());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const TransferEvent.recipientSelected(destinatarioDePrueba));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) => expect(b.state.idempotencyKey, 'k-1'),
  );

  blocTest<TransferBloc, TransferState>(
    'una cuenta de otra moneda no se elige',
    build: () => _bloc(FakeTransferRepository()),
    act: (b) {
      b.add(TransferEvent.started(_cuentaOrigen)); // soles
      b.add(TransferEvent.recipientSelected(Recipient(
        dni: '87654321', nombreEnmascarado: 'J*** M*** R***',
        cuenta: directorioDePrueba.cuentas[2], // dólares
      )));
    },
    verify: (b) {
      expect(b.state.destinatario, isNull);
      expect(b.state.failure, isA<CurrencyMismatch>());
    },
  );

  blocTest<TransferBloc, TransferState>(
    'enviar manda la cuenta elegida',
    build: () => _bloc(_repo = FakeTransferRepository()),
    act: (b) async {
      b.add(TransferEvent.started(_cuentaOrigen));
      b.add(TransferEvent.recipientSelected(Recipient(
        dni: '87654321', nombreEnmascarado: 'J*** M*** R***',
        cuenta: directorioDePrueba.cuentas[1],
      )));
      b.add(const TransferEvent.amountEntered(monto: Money.soles(5000)));
      b.add(const TransferEvent.confirmationOpened());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const TransferEvent.submitted(pin: '000000'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (_) => expect(_repo.cuentasDestino, ['acc-ext-2']),
  );

  blocTest<TransferBloc, TransferState>(
    'una respuesta tardía de un DNI anterior se descarta',
    build: () => _bloc(FakeTransferRepository(alResolver: (dni) async {
      if (dni == '11111111') await Future<void>.delayed(const Duration(milliseconds: 30));
      return right(directorioDePrueba);
    })),
    act: (b) async {
      b.add(TransferEvent.started(_cuentaOrigen));
      b.add(const TransferEvent.recipientRequested('11111111'));
      b.add(const TransferEvent.recipientCleared());
    },
    wait: const Duration(milliseconds: 60),
    verify: (b) => expect(b.state.directorio, isNull),
  );
```

con helpers locales `_cuentaOrigen` (una `Account` en soles `acc-demo-1`), `_claves()` (genera `k-1`, `k-2`, ...), `late FakeTransferRepository _repo;`, y `_bloc(repo, {newKey})` que arma el `TransferBloc` como los tests existentes.

`transfer_bloc_frequent_test.dart`: el frecuente se guarda con `cuentaDestinoId: 'acc-ext-1'` (verificarlo en el fake de `BeneficiaryRepository`).

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs; flutter test test/presentation/transfer/transfer_bloc_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

`transfer_state.dart`: añadir

```dart
    /// Lo que devolvió buscar el DNI: la persona y sus cuentas. La pantalla
    /// pinta una tarjeta por cuenta.
    RecipientDirectory? directorio,

    /// La cuenta destino ELEGIDA (al tocar una tarjeta o un frecuente).
    Recipient? destinatario,
```

y actualizar el doc del enum (`ready`: "hay directorio hallado o destino elegido").

`transfer_event.dart`: añadir

```dart
  /// El usuario tocó una cuenta (de la búsqueda o un frecuente que ya la trae).
  const factory TransferEvent.recipientSelected(Recipient destinatario) =
      TransferRecipientSelected;
```

`transfer_bloc.dart`:
- `_onRecipientRequested`: emitir `resolving` con `directorio: null, destinatario: null, failure: null, idempotencyKey: ''`; al responder, `ready` + `directorio: d` (o `idle` + `failure`).
- `_onRecipientCleared`: también `directorio: null`.
- Nuevo:

```dart
  void _onRecipientSelected(
    TransferRecipientSelected event,
    Emitter<TransferState> emit,
  ) {
    if (_intentSealed) return;
    final elegido = event.destinatario;
    final origen = state.cuenta;
    if (origen != null && elegido.cuenta.cuentaId == origen.id) {
      emit(state.copyWith(failure: const TransferFailure.sameAccount()));
      return;
    }
    if (origen != null && elegido.cuenta.moneda != origen.moneda) {
      emit(state.copyWith(failure: const TransferFailure.currencyMismatch()));
      return;
    }
    final cambio = state.destinatario?.cuenta.cuentaId != elegido.cuenta.cuentaId;
    emit(state.copyWith(
      status: TransferStatus.ready,
      destinatario: elegido,
      failure: null,
      // Otra cuenta, otra intención: la clave anterior quedó ligada a otro
      // destino y reutilizarla daría 409 (o, peor, un reintento hacia la
      // cuenta equivocada si el servidor no comparara el destino).
      idempotencyKey: cambio ? '' : state.idempotencyKey,
    ));
  }
```

- `_huella`: `cuentaDestinoId: destinatario.cuenta.cuentaId`.
- `_onSubmitted`: `cuentaDestinoId: destinatario.cuenta.cuentaId`.
- `_saveFrequent`: `beneficiaries.guardar(cuentaDestinoId: destinatario.cuenta.cuentaId, apodo: ...)`.
- Doc de la clase, garantía 1: "Solo cambia si cambia la intención (otra cuenta destino, monto o motivo)."

- [ ] **Step 4: Probar y commit (Tasks 1–3 juntas)**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter test test/feature/transfer test/feature/beneficiary test/presentation/transfer/transfer_bloc_test.dart test/presentation/transfer/transfer_bloc_frequent_test.dart`
Expected: PASS. (`flutter analyze` aún marca las pantallas: Task 4.)

```bash
git add -A apps/mobile
git commit -m "feat(app): el envío apunta a una cuenta; los frecuentes guardan la cuenta"
```

---

## Task 4: Pantalla de destinatario: tarjetas por cuenta, sin "Continuar", frecuentes directos

**Files:**
- Create: `apps/mobile/lib/presentation/transfer/widgets/recipient_account_card.dart`
- Modify: `apps/mobile/lib/presentation/transfer/recipient_screen.dart`
- Modify: `apps/mobile/lib/presentation/transfer/widgets/frequent_row.dart`, `frequent_section.dart`
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Modify: `apps/mobile/test/presentation/transfer/send_flow_test.dart`, `frequent_and_detail_flow_test.dart`
- Create: `apps/mobile/test/presentation/transfer/recipient_screen_test.dart`

**Interfaces:**
- Consumes: `TransferState.directorio/destinatario/cuenta/failure`, `recipientSelected`, `accountTypeShort`.
- Produces:
  - `RecipientAccountCard({required RecipientAccount cuenta, required String titulo, VoidCallback? onTap, String? motivoDeshabilitada})` — `onTap == null` = apagada, con `motivoDeshabilitada` debajo.
  - `RecipientScreen.frecuentes: Widget Function(ValueChanged<Beneficiary> onSelected)?`.
  - `FrequentRow.onSelected` / `FrequentSection.onSelected`: `ValueChanged<Beneficiary>`.

- [ ] **Step 1: Copy**

```json
  "transferRecipientAccountLine": "{tipo} · {simbolo} · {masked}",
  "@transferRecipientAccountLine": {"placeholders": {"tipo": {"type": "String"}, "simbolo": {"type": "String"}, "masked": {"type": "String"}}},
  "transferRecipientChooseAccount": "Elige la cuenta que recibe",
  "transferRecipientOnlyReceives": "Solo recibe {simbolo}",
  "@transferRecipientOnlyReceives": {"placeholders": {"simbolo": {"type": "String"}}},
  "transferRecipientNoEligible": "No tiene cuentas en {simbolo} para recibir desde esta cuenta.",
  "@transferRecipientNoEligible": {"placeholders": {"simbolo": {"type": "String"}}},
  "transferRecipientNoOwnEligible": "No tienes otra cuenta en {simbolo}.",
  "@transferRecipientNoOwnEligible": {"placeholders": {"simbolo": {"type": "String"}}},
  "transferFrequentOtherCurrency": "Ese frecuente recibe en {simbolo}. Envía desde una cuenta en {simbolo}.",
  "@transferFrequentOtherCurrency": {"placeholders": {"simbolo": {"type": "String"}}},
  "transferRecipientAccountSemantics": "Enviar a {linea}",
  "@transferRecipientAccountSemantics": {"placeholders": {"linea": {"type": "String"}}},
```

`flutter gen-l10n`. (`transferRecipientAccount` y `transferContinue` siguen en uso en otras pantallas; no se borran.)

- [ ] **Step 2: Tests de pantalla**

Create `test/presentation/transfer/recipient_screen_test.dart` montando `RecipientScreen` con un `TransferBloc` sobre `FakeTransferRepository` y un `GoRouter` mínimo con las rutas `enviar` y `enviarMonto` (la de monto puede ser un `Text('MONTO')`):

```dart
  testWidgets('al completar el DNI aparece una tarjeta por cuenta y no hay Continuar', (t) async {
    await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text('J*** M*** R***'), findsOneWidget);
    expect(find.text('Ahorros · S/ · ••••7732'), findsOneWidget);
    expect(find.text('Corriente · S/ · ••••5510'), findsOneWidget);
    expect(find.text(r'Ahorros · US$ · ••••0419'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Continuar'), findsNothing);
  });

  testWidgets('tocar una tarjeta lleva al monto con esa cuenta', (t) async {
    final bloc = await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    await t.tap(find.text('Corriente · S/ · ••••5510'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsOneWidget);
    expect(bloc.state.destinatario?.cuenta.cuentaId, 'acc-ext-2');
  });

  testWidgets('la cuenta de otra moneda está apagada y dice por qué', (t) async {
    await pump(t);
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text(r'Solo recibe US$'), findsOneWidget);
    await t.tap(find.text(r'Ahorros · US$ · ••••0419'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsNothing);
  });

  testWidgets('el propio DNI lista mis otras cuentas con nombre y sin la de origen', (t) async {
    await pump(t, resolver: (_) async => right(_miDirectorio)); // acc-demo-1 (origen), acc-demo-2 'Planilla', acc-demo-3 USD
    await t.enterText(find.byType(TextField), '70123456');
    await t.pumpAndSettle();
    expect(find.textContaining('••••4521'), findsNothing); // la de origen
    expect(find.text('Planilla'), findsOneWidget);
  });

  testWidgets('sin cuentas elegibles, aviso', (t) async {
    await pump(t, resolver: (_) async => right(_soloDolares));
    await t.enterText(find.byType(TextField), '87654321');
    await t.pumpAndSettle();
    expect(find.text('No tiene cuentas en S/ para recibir desde esta cuenta.'), findsOneWidget);
  });

  testWidgets('un frecuente con cuenta lleva directo al monto, sin buscar', (t) async {
    final repo = FakeTransferRepository();
    await pump(t, repo: repo, frecuentes: [_frecuente(cuenta: cuentaDeDestinoDePrueba)]);
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(find.text('MONTO'), findsOneWidget);
    expect(repo.busquedas, isEmpty);
  });

  testWidgets('un frecuente de otra moneda avisa y se queda', (t) async {
    await pump(t, frecuentes: [_frecuente(cuenta: directorioDePrueba.cuentas[2])]);
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(find.text(r'Ese frecuente recibe en US$. Envía desde una cuenta en US$.'), findsOneWidget);
    expect(find.text('MONTO'), findsNothing);
  });

  testWidgets('un frecuente sin cuenta rellena el DNI y busca', (t) async {
    final repo = FakeTransferRepository();
    await pump(t, repo: repo, frecuentes: [_frecuente(cuenta: null)]);
    await t.tap(find.text('Mamá'));
    await t.pumpAndSettle();
    expect(repo.busquedas, ['87654321']);
    expect(find.text('Ahorros · S/ · ••••7732'), findsOneWidget);
  });
```

`pump(t, {repo, resolver, frecuentes})` arma el árbol y devuelve el bloc; `FakeTransferRepository` gana `final busquedas = <String>[]` (anota cada `resolverDestinatario`). `_frecuente({RecipientAccount? cuenta})` = `Beneficiary(id: 'b1', dni: '87654321', apodo: 'Mamá', nombreEnmascarado: 'J*** M*** R***', cuenta: cuenta)`; `frecuentes:` se pasa como `(onSelected) => FrequentRow(beneficiarios: lista, onSelected: onSelected)`.

`send_flow_test.dart` (recorrido completo con el grafo `mock`): tras escribir el DNI, en vez de "Continuar" tocar `find.text('Ahorros · S/ · ••••7732')`; en el monto verificar `find.text('Ahorros · ••••7732')` (Task 5). `frequent_and_detail_flow_test.dart`: igual para frecuentes.

- [ ] **Step 3: Ver que fallan**

Run: `cd apps/mobile && flutter test test/presentation/transfer/recipient_screen_test.dart`
Expected: FAIL.

- [ ] **Step 4: Implementar**

`recipient_account_card.dart`:

```dart
/// Una cuenta del destinatario. Tocarla elige esa cuenta; apagada (sin
/// [onTap]) dice por qué no puede recibir.
class RecipientAccountCard extends StatelessWidget {
  const RecipientAccountCard({
    required this.cuenta,
    required this.titulo,
    this.onTap,
    this.motivoDeshabilitada,
    super.key,
  });

  final RecipientAccount cuenta;

  /// El nombre de la cuenta si es propia; si no, la línea de tipo y moneda.
  final String titulo;
  final VoidCallback? onTap;
  final String? motivoDeshabilitada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final linea = l10n.transferRecipientAccountLine(
      accountTypeShort(l10n, cuenta.tipo),
      cuenta.moneda.symbol,
      cuenta.numeroMasked,
    );
    final activa = onTap != null;
    return Semantics(
      button: activa,
      enabled: activa,
      label: l10n.transferRecipientAccountSemantics(linea),
      excludeSemantics: true,
      child: Opacity(
        opacity: activa ? 1 : 0.5,
        child: Material(
          color: CuyCashColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(CuyCashRadii.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(CuyCashRadii.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined),
                  const SizedBox(width: CuyCashSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: CuyCashTypography.titleMd),
                        if (titulo != linea)
                          Text(linea, style: CuyCashTypography.bodyMd.copyWith(
                            color: CuyCashColors.secondaryText)),
                        if (motivoDeshabilitada case final m?)
                          Text(m, style: CuyCashTypography.bodyMd.copyWith(
                            color: CuyCashColors.secondaryText)),
                      ],
                    ),
                  ),
                  if (activa) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

(Se usa `Material` + `InkWell` en lugar de envolver `SurfaceCard` para que el efecto del toque se vea: un `InkWell` por fuera de una tarjeta con fondo queda tapado. Si `SurfaceCard` acepta `onTap`, úsalo en su lugar.)

`recipient_screen.dart`:
- Doc: "Paso 1 del envío: a qué cuenta. Al completar el DNI se listan sus cuentas; tocar una pasa al monto. Un frecuente con cuenta pasa directo."
- `body`: `SingleChildScrollView` (ya no hay `Spacer` ni `PrimaryButton`).
- Debajo del campo, si `state.directorio case final d?`:

```dart
  List<Widget> _cuentas(BuildContext context, TransferState state, RecipientDirectory d) {
    final l10n = AppLocalizations.of(context);
    final origen = state.cuenta;
    final propio = d.cuentas.any((c) => c.cuentaId == origen?.id);
    final visibles = [for (final c in d.cuentas) if (c.cuentaId != origen?.id) c];
    final elegibles = visibles.where((c) => c.moneda == origen?.moneda);
    final simbolo = origen?.moneda.symbol ?? '';
    return [
      Text(d.nombreEnmascarado, style: CuyCashTypography.titleMd),
      const SizedBox(height: CuyCashSpacing.stackXs),
      Text(l10n.transferRecipientChooseAccount, style: CuyCashTypography.bodyMd.copyWith(
        color: CuyCashColors.secondaryText)),
      const SizedBox(height: CuyCashSpacing.stackSm),
      if (elegibles.isEmpty)
        InfoStrip(
          icon: Icons.info_outline,
          text: propio
              ? l10n.transferRecipientNoOwnEligible(simbolo)
              : l10n.transferRecipientNoEligible(simbolo),
        ),
      for (final c in visibles) ...[
        RecipientAccountCard(
          cuenta: c,
          titulo: c.nombre ?? l10n.transferRecipientAccountLine(
            accountTypeShort(l10n, c.tipo), c.moneda.symbol, c.numeroMasked),
          onTap: c.moneda == origen?.moneda
              ? () => _elegir(Recipient(dni: d.dni, nombreEnmascarado: d.nombreEnmascarado, cuenta: c))
              : null,
          motivoDeshabilitada: c.moneda == origen?.moneda
              ? null
              : l10n.transferRecipientOnlyReceives(c.moneda.symbol),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
      ],
    ];
  }

  void _elegir(Recipient r) {
    context.read<TransferBloc>().add(TransferEvent.recipientSelected(r));
    context.push(AppRoutes.enviarMonto);
  }
```

- Frecuentes:

```dart
  /// Un frecuente que ya trae su cuenta pasa directo al monto, sin consultar
  /// (no gasta presupuesto). Sin cuenta (dejó de recibir), es teclear su DNI.
  void _onFrequentSelected(Beneficiary b) {
    final origen = context.read<TransferBloc>().state.cuenta;
    switch (b.cuenta) {
      case final RecipientAccount c when origen != null && c.moneda != origen.moneda:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(
            AppLocalizations.of(context).transferFrequentOtherCurrency(c.moneda.symbol))));
      case final RecipientAccount c:
        _elegir(Recipient(
          dni: b.dni,
          nombreEnmascarado: b.nombreEnmascarado ?? b.apodo,
          cuenta: c,
        ));
      case null:
        _controller.value = TextEditingValue(
          text: b.dni,
          selection: TextSelection.collapsed(offset: b.dni.length),
        );
        _onChanged(b.dni);
    }
  }
```

- Borrar `_RecipientCard`.

`frequent_row.dart` / `frequent_section.dart`: `ValueChanged<Beneficiary>` y `onTap: () => onSelected(b)`; actualizar sus docs. `router.dart` no cambia (ya pasa `onSelected`).

- [ ] **Step 5: Probar**

Run: `cd apps/mobile && flutter test test/presentation/transfer`
Expected: PASS salvo los asserts de la pantalla de monto (Task 5).

---

## Task 5: Monto, confirmación y constancia muestran la cuenta destino

**Files:**
- Modify: `apps/mobile/lib/presentation/transfer/amount_screen.dart`
- Modify: `apps/mobile/lib/presentation/transfer/confirm_screen.dart`
- Modify: `apps/mobile/lib/presentation/transfer/receipt_screen.dart` (si pinta destino)
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Modify: `apps/mobile/test/presentation/transfer/amount_screen_test.dart`, `confirm_screen_test.dart`

**Interfaces:**
- Produces: `String recipientAccountShort(AppLocalizations l10n, RecipientAccount c)` en `presentation/account/account_label.dart` → `c.nombre ?? '${accountTypeShort(l10n, c.tipo)} · ${c.numeroMasked}'` ("Ahorros · ••••7732").

- [ ] **Step 1: Tests**

`amount_screen_test.dart`:

```dart
  testWidgets('debajo del nombre muestra la cuenta que recibe', (t) async {
    await pumpConDestinatario(t, destinatarioDePrueba);
    expect(find.text('Para J*** M*** R***'), findsOneWidget);
    expect(find.text('Ahorros · ••••7732'), findsOneWidget);
  });

  testWidgets('el campo y los montos rápidos usan la moneda de origen', (t) async {
    await pumpConDestinatario(t, _destinatarioDolares, origen: _cuentaDolares);
    expect(find.text(r'US$ 20.00'), findsOneWidget);
    expect(find.textContaining(r'Disponible: US$'), findsOneWidget);
  });
```

`confirm_screen_test.dart`: la fila "Para" muestra `J*** M*** R*** · Ahorros · ••••7732` y la fila "Desde" muestra `Cuenta de ahorros · ••••4521` (etiqueta de la cuenta origen).

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/presentation/transfer/amount_screen_test.dart test/presentation/transfer/confirm_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

`amount_screen.dart`, bajo `transferAmountTo(...)`:

```dart
                Text(
                  recipientAccountShort(l10n, destinatario.cuenta),
                  style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.secondaryText,
                  ),
                ),
```

`confirm_screen.dart` `_Summary`:

```dart
          if (state.destinatario case final d?)
            _Row(
              label: l10n.transferSummaryTo,
              value: '${d.nombreEnmascarado} · ${recipientAccountShort(l10n, d.cuenta)}',
            ),
          if (state.cuenta case final c?)
            _Row(
              label: l10n.transferSummaryFrom,
              value: '${accountLabel(l10n, c)} · ${c.numeroMasked}',
            ),
```

`receipt_screen.dart`: si pinta `cuentaDestinoMasked` del `Recipient`, cambiar a `recipientAccountShort(l10n, d.cuenta)`.

- [ ] **Step 4: Probar todo y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: `No issues found!` y todo en verde.

```bash
git add -A apps/mobile
git commit -m "feat(app): destinatario por cuenta, sin Continuar; frecuentes directos al monto; el monto muestra la cuenta"
```

---

## Task 6: Cierre de la iniciativa

**Files:**
- Modify: `CLAUDE.md`
- Modify: `docs/verificacion-manual.md`

- [ ] **Step 1: CLAUDE.md**

En "Lo implementado hoy", reemplazar "Envío de dinero entre titulares de CuyCash, identificando al destinatario por DNI..." por: "Envío de dinero a una cuenta de CuyCash: se busca por DNI, se elige una de sus cuentas (misma moneda que la de origen) y se confirma con PIN; también entre cuentas propias. Resolver un DNI devuelve el nombre enmascarado y sus cuentas (`••••NNNN`, tipo, moneda)." y "Beneficiarios frecuentes" → "Frecuentes por cuenta (tocar uno va directo al monto)". En "Sigue sin existir", confirmar "conversión entre monedas".

- [ ] **Step 2: Guion de verificación manual**

En `docs/verificacion-manual.md`, añadir una sección "Multicuenta y envío por cuenta" con los pasos (marcados como inferidos del código, igual que el resto del guion): abrir una cuenta en dólares; enviar entre dos cuentas propias en soles; buscar un DNI con varias cuentas y ver la de dólares apagada; guardar un frecuente y comprobar que tocarlo va directo al monto; recargar la cuenta en dólares.

- [ ] **Step 3: Verificación final**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test && (cd services/api && .venv/bin/python -m pytest -q) && git status --short`
Expected: `No issues found!`, Flutter y pytest en verde, árbol limpio salvo los dos archivos de este task.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md docs/verificacion-manual.md
git commit -m "docs: CLAUDE.md y guion manual con la multicuenta y el envío por cuenta"
```
