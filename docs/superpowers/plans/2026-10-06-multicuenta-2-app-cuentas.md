# Multicuenta — Entrega 2: App, cuentas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que la app maneje varias cuentas por titular: `Money` con moneda, un carrusel de cuentas en el inicio, abrir otra cuenta (tipo, moneda, nombre) con PIN, y ponerle nombre a una cuenta.

**Architecture:** `core_kernel` gana `Currency` y `Money` pasa a llevar su moneda (operar monedas distintas es un `StateError`). `feature/account` gana `AccountType`, `nombre`, `abrir` y `renombrar`, con su `Memory*` siguiendo las reglas del backend sobre un `MemoryLedger` multicuenta. En presentación, `AccountBloc` guarda la lista de cuentas y la seleccionada; el inicio muestra un `PageView`; un `OpenAccountBloc` nuevo maneja la apertura en dos pasos (datos, PIN).

**Tech Stack:** Flutter, flutter_bloc + freezed, fpdart (`Either`), dio, go_router, bloc_test, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-06-multicuenta-y-envio-por-cuenta-design.md` (§2 y §3 "Inicio", "Abrir cuenta", "Recarga").

**Depende de:** `2026-10-06-multicuenta-1-backend.md` (contrato de `POST /v1/accounts`, `PATCH /v1/accounts/{id}/nombre`, `nombre` y `moneda` en las respuestas). **Antes de la entrega 3.**

## Global Constraints

- Reglas duras de `CLAUDE.md`: errores como valores (`Either` + `GlobalFailure`), failures sellados con factory nombrado, estados sealed + `switch` exhaustivo (prohibido `when`/`maybeWhen`/`!`), el Bloc consume `application`, colores y tipografía solo de `design_system`, copy es-PE en `lib/l10n/arb/app_es.arb`, un widget público por archivo, `.freezed.dart` y l10n generados se commitean.
- Dinero: `int` de céntimos dentro de `Money`, que ahora lleva `Currency`. Ningún `double`.
- Monedas: `Currency.pen` (`PEN`, `S/`) y `Currency.usd` (`USD`, `US$`).
- Tipos: `AccountType.ahorro|corriente|sueldo`. Tope 5 cuentas. Una sola `sueldo`, solo en soles. Nombre ≤ 30, opcional.
- Mock: PIN válido `000000`; el titular `70123456` tiene tres cuentas: `acc-demo-1` ahorros S/ (`19100000004521`, S/ 1,250.40, con los tres movimientos de demo), `acc-demo-2` sueldo S/ (`19100000008830`, S/ 3,500.00), `acc-demo-3` ahorros US$ (`19100000002207`, US$ 120.00).
- Comandos (desde la raíz salvo indicación): `flutter analyze` sin issues, `flutter test` en verde, `dart run build_runner build --delete-conflicting-outputs` en `apps/mobile` tras tocar freezed, `flutter gen-l10n` en `apps/mobile` tras tocar el ARB.
- **No reformatear archivos que no se tocan.** Correr `dart format` solo sobre los archivos de cada task.

## Review Focus

1. **Deslizar a otra cuenta mientras un refresco está en vuelo:** la tarjeta visible y los movimientos de abajo deben ser de la misma cuenta al terminar. → test en Task 5.
2. **Respuesta tardía de movimientos de la cuenta anterior** (deslizar A→B rápido): los de A no deben aparecer bajo B. → test en Task 5.
3. **Movimiento con una moneda desconocida desde el backend** (`"moneda": "EUR"`): `unexpected`, nunca pintarlo como soles. → test en Task 3.
4. **Reintento de apertura tras perder la respuesta:** la misma clave debe devolver la misma cuenta y no abrir otra; cambiar tipo/moneda/nombre genera una clave nueva. → tests en Tasks 4 y 7.
5. **Llegar al tope con el carrusel abierto:** la tarjeta "Abrir otra cuenta" desaparece al llegar a 5. → test en Task 6.

---

## Task 1: `Currency` y `Money` con moneda (core_kernel)

**Files:**
- Create: `packages/core_kernel/lib/src/currency.dart`
- Modify: `packages/core_kernel/lib/src/money.dart`
- Modify: `packages/core_kernel/lib/core_kernel.dart` (export)
- Modify: `packages/core_kernel/test/money_test.dart`

**Interfaces:**
- Produces:
  - `enum Currency { pen, usd }` con `String code`, `String symbol`, `static Currency? fromCode(String code)`.
  - `final class Money implements Comparable<Money>`: `const Money(int centimos, Currency currency)`, `const Money.soles(int centimos)`, `const Money.dolares(int centimos)`, `static Money zero(Currency c)`, `static Money? parse(String texto, Currency currency)`, `int centimos`, `Currency currency`, `+ - < <= > >= compareTo` (lanzan `StateError` si las monedas difieren), `==`/`hashCode` por (centimos, currency).
  - Se ELIMINAN `Money.fromCentimos` y `Money.zero` (constante). El compilador encuentra cada uso.

- [ ] **Step 1: Reescribir el test de `Money`**

En `packages/core_kernel/test/money_test.dart`: reemplazar `Money.fromCentimos(` por `Money.soles(`, `Money.zero` por `Money.zero(Currency.pen)`, y cada `Money.parse(x)` por `Money.parse(x, Currency.pen)`:

```bash
cd packages/core_kernel
sed -i '' -E 's/Money\.fromCentimos\(/Money.soles(/g; s/Money\.zero([^(]|$)/Money.zero(Currency.pen)\1/g; s/Money\.parse\(([^)]*)\)/Money.parse(\1, Currency.pen)/g' test/money_test.dart
```

Revisa el diff (un `Money.parse` con paréntesis dentro del argumento rompería el sed). Añade al final del `group('Money', ...)`:

```dart
    test('la moneda es parte del valor', () {
      expect(Money.soles(100), isNot(Money.dolares(100)));
      expect(Money.soles(100), Money(100, Currency.pen));
      expect(Money.soles(100).hashCode, Money(100, Currency.pen).hashCode);
    });

    test('operar monedas distintas es un error de programación', () {
      expect(() => Money.soles(1) + Money.dolares(1), throwsStateError);
      expect(() => Money.soles(1) - Money.dolares(1), throwsStateError);
      expect(() => Money.soles(1) < Money.dolares(1), throwsStateError);
      expect(() => Money.soles(1).compareTo(Money.dolares(1)), throwsStateError);
    });

    test('parse lleva la moneda que se le pide', () {
      expect(Money.parse('20', Currency.usd), Money.dolares(2000));
    });

    test('Currency se lee por código y rechaza los desconocidos', () {
      expect(Currency.fromCode('PEN'), Currency.pen);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('EUR'), isNull);
      expect(Currency.pen.symbol, 'S/');
      expect(Currency.usd.symbol, r'US$');
    });
```

- [ ] **Step 2: Ver que falla**

Run: `cd packages/core_kernel && dart test`
Expected: FAIL de compilación (`Money.soles` no existe).

- [ ] **Step 3: Implementar**

Create `packages/core_kernel/lib/src/currency.dart`:

```dart
/// Monedas en las que CuyCash lleva cuentas. Espejo del `CHECK` de
/// `accounts.moneda` del backend.
enum Currency {
  pen('PEN', 'S/'),
  usd('USD', r'US$');

  const Currency(this.code, this.symbol);

  /// Código ISO 4217, como viaja en el JSON.
  final String code;

  /// Cómo se escribe delante del monto en Perú.
  final String symbol;

  /// `null` ante un código desconocido: quien parsea decide (normalmente, un
  /// fallo inesperado). Adivinar soles pintaría dólares como soles.
  static Currency? fromCode(String code) {
    for (final c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}
```

En `money.dart`, importar `currency.dart` y reemplazar la clase por:

```dart
final class Money implements Comparable<Money> {
  const Money(this.centimos, this.currency);
  const Money.soles(this.centimos) : currency = Currency.pen;
  const Money.dolares(this.centimos) : currency = Currency.usd;

  static Money zero(Currency currency) => Money(0, currency);

  // (conservar el comentario y la RegExp `_formato` existentes)
  static final RegExp _formato = RegExp(r'^(\d{1,12})(?:[.,](\d{1,2}))?$');

  /// Lee lo que el usuario escribe (`250`, `250.00`, `250,00`) en [currency].
  /// (conservar el resto del doc existente)
  static Money? parse(String texto, Currency currency) {
    final match = _formato.firstMatch(texto.trim());
    if (match == null) return null;

    final enteros = int.parse(match.group(1)!);
    final decimales = (match.group(2) ?? '').padRight(2, '0');
    return Money(enteros * 100 + int.parse(decimales), currency);
  }

  final int centimos;
  final Currency currency;

  /// Sumar soles con dólares no es un caso de negocio que el usuario pueda
  /// provocar: es un bug de quien armó la operación. Reventar es lo correcto;
  /// devolver un número sin sentido movería dinero equivocado.
  void _misma(Money other) {
    if (other.currency != currency) {
      throw StateError('Monedas mezcladas: ${currency.code} y ${other.currency.code}');
    }
  }

  Money operator +(Money other) {
    _misma(other);
    return Money(centimos + other.centimos, currency);
  }

  Money operator -(Money other) {
    _misma(other);
    return Money(centimos - other.centimos, currency);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _misma(other);
    return centimos.compareTo(other.centimos);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.centimos == centimos && other.currency == currency;

  @override
  int get hashCode => Object.hash(centimos, currency);

  @override
  String toString() => 'Money($centimos ${currency.code})';
}
```

En `core_kernel.dart`: `export 'src/currency.dart';`.

- [ ] **Step 4: Ver que pasa**

Run: `cd packages/core_kernel && dart test`
Expected: PASS.

- [ ] **Step 5: Commit** (la app aún no compila; se arregla en la Task 2, que va en el mismo PR)

```bash
git add packages/core_kernel
git commit -m "feat(core_kernel): Money lleva su moneda; operar monedas distintas es un error"
```

---

## Task 2: La app compila con `Money` con moneda (`formatMoney`, límites por moneda)

**Files:**
- Create: `apps/mobile/lib/core/format/money_format.dart`
- Delete: `apps/mobile/lib/core/format/soles.dart`
- Move: `apps/mobile/test/core/format/soles_test.dart` → `apps/mobile/test/core/format/money_format_test.dart`
- Modify: `apps/mobile/lib/feature/account/domain/account.dart` (`moneda: Currency`)
- Modify: `apps/mobile/lib/feature/account/domain/movement.dart` (sin cambio de forma; los `Money` ya traen moneda)
- Modify: `apps/mobile/lib/feature/account/infrastructure/http_account_repository.dart`
- Modify: `apps/mobile/lib/feature/account/infrastructure/memory_ledger.dart`, `memory_account_repository.dart`
- Modify: `apps/mobile/lib/feature/transfer/domain/transfer_limits.dart`
- Modify: `apps/mobile/lib/feature/transfer/infrastructure/http_transfer_repository.dart`, `memory_transfer_repository.dart`
- Modify: todos los `lib/presentation/**` que usan `formatSoles`, `Money.parse`, `Money.fromCentimos` o `TransferLimits.monto*` (lista en Step 1)
- Modify: los tests que usan `Money.fromCentimos`/`Money.zero`/`Money.parse`/`formatSoles`

**Interfaces:**
- Consumes: Task 1.
- Produces:
  - `String formatMoney(Money monto)` → `S/ 1,250.40`, `US$ 20.00`, `-S/ 1.50`.
  - `Account.moneda: Currency`.
  - `TransferLimits.montoMinimo(Currency)` y `TransferLimits.montoMaximo(Currency)` → `Money`.
  - `transferSubmitErrorText(l10n, failure, Currency moneda)` y `topUpErrorText(l10n, failure, Currency moneda)` (el texto de rango lleva el símbolo de la moneda).
  - `HttpTransferRepository`/`MemoryTransferRepository`: la constancia (`TransferReceipt.monto`) toma la moneda del monto enviado.

- [ ] **Step 1: Inventario**

Run: `cd /Users/jairconislla/Projects/cuycash && git grep -n "Money.fromCentimos\|Money.parse\|Money.zero\|formatSoles\|TransferLimits.monto" -- apps/mobile/lib apps/mobile/test`
Expected: la lista de sitios a cambiar (≈ 25 archivos de lib y ≈ 20 de test).

- [ ] **Step 2: `formatMoney` con su test primero**

`git mv apps/mobile/test/core/format/soles_test.dart apps/mobile/test/core/format/money_format_test.dart`, cambiar el import a `money_format.dart`, `formatSoles(` → `formatMoney(`, `Money.fromCentimos(` → `Money.soles(`, y añadir:

```dart
  test('los dólares llevan US\$ delante', () {
    expect(formatMoney(const Money.dolares(2000)), r'US$ 20.00');
    expect(formatMoney(const Money.dolares(123456789)), r'US$ 1,234,567.89');
    expect(formatMoney(const Money.dolares(-150)), r'-US$ 1.50');
  });
```

Create `lib/core/format/money_format.dart` copiando el doc de `soles.dart` (adaptado: "Formatea un monto con el símbolo de su moneda") y:

```dart
String formatMoney(Money monto) {
  final negativo = monto.centimos < 0;
  final abs = monto.centimos.abs();
  final enteros = NumberFormat('#,##0', 'en_US').format(abs ~/ 100);
  final decimales = (abs % 100).toString().padLeft(2, '0');
  return '${negativo ? '-' : ''}${monto.currency.symbol} $enteros.$decimales';
}
```

`git rm apps/mobile/lib/core/format/soles.dart`.

- [ ] **Step 3: Dominio y repos**

`account.dart`: `final Currency moneda;` con doc "Moneda de la cuenta; sus saldos vienen en ella." (quitar "Código ISO, hoy solo PEN").

`http_account_repository.dart`:

```dart
  Account _cuenta(Map<String, dynamic> j) {
    final moneda = _moneda(j['moneda']);
    return Account(
      id: j['id'] as String,
      numero: j['numero'] as String,
      tipo: j['tipo'] as String,
      moneda: moneda,
      estado: j['estado'] as String,
      saldoDisponible: Money(j['saldo_disponible'] as int, moneda),
      saldoContable: Money(j['saldo_contable'] as int, moneda),
    );
  }

  /// Una moneda desconocida NO se adivina: pintar dólares como soles es peor
  /// que fallar. La `FormatException` la recoge `_guard` como inesperado.
  Currency _moneda(Object? code) => switch (code) {
    final String c => Currency.fromCode(c) ?? (throw FormatException('Moneda desconocida: $c')),
    _ => throw const FormatException('Movimiento sin moneda'),
  };
```

En `_movimiento` y `_detalle`: `final moneda = _moneda(j['moneda']);` y `monto: Money(j['monto'] as int, moneda)`, `saldoPosterior: Money(j['saldo_posterior'] as int, moneda)`.

En `test/feature/account/http_account_repository_test.dart` (backend simulado): añadir `'moneda': 'PEN'` a cada movimiento de `_movimientos` y un test:

```dart
    test('un movimiento con moneda desconocida es inesperado, no soles', () async {
      backend.forced = (status: 200, body: {
        'movimientos': [
          {
            'transaction_id': 'tx-x', 'tipo': 'transferencia', 'estado': 'confirmada',
            'direccion': 'debito', 'monto': 100, 'moneda': 'EUR', 'contraparte': null,
            'motivo': null, 'saldo_posterior': 0, 'created_at': '2026-10-05T19:30:00.000000Z',
          },
        ],
        'next_cursor': null,
      });
      final r = await repo.movimientos('acc-demo-1');
      expect(r.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
```

(Ajusta `backend`/`repo` a los nombres del `setUp` del archivo y el `isA` al tipo que devuelve `_guard` para una `FormatException`: mira cómo prueba el archivo otros JSON malformados y usa lo mismo.)

`memory_ledger.dart` y `memory_account_repository.dart`: `const Money.fromCentimos(` → `const Money.soles(`; `moneda: 'PEN'` → `moneda: Currency.pen`.

`transfer_limits.dart`:

```dart
abstract final class TransferLimits {
  /// Mismo rango en cualquier moneda (espejo de `MONTO_MINIMO`/`MONTO_MAXIMO`).
  static Money montoMinimo(Currency moneda) => Money(1, moneda);
  static Money montoMaximo(Currency moneda) => Money(200000, moneda);
  // (motivo sin cambios)
```

`http_transfer_repository.dart` `_mover`: la constancia usa la moneda del monto pedido. Cambiar la firma interna a `_mover(String path, Map<String, Object?> body, Currency moneda)` y `monto: Money(j['monto_centimos'] as int, moneda)`; en `enviar`/`recargar` pasar `monto.currency`.

`memory_transfer_repository.dart`: `_validarMonto` usa `monto.centimos` (no cambia).

- [ ] **Step 4: Presentación**

Reglas para cada archivo del inventario:
- `formatSoles(x)` → `formatMoney(x)`; import `../../core/format/money_format.dart`.
- `Money.parse(texto)` → `Money.parse(texto, moneda)` donde `moneda` es la de la cuenta en pantalla: en `amount_screen.dart` `state.cuenta?.moneda ?? Currency.pen`; en `topup_screen.dart` `widget.cuenta.moneda`.
- Montos rápidos: `Money.fromCentimos(soles * 100)` → `Money(soles * 100, moneda)`.
- `const Money.fromCentimos(0)` en `amount_screen.dart` → `Money.zero(moneda)`.
- `TransferLimits.montoMinimo` → `TransferLimits.montoMinimo(moneda)` (igual el máximo).
- `movement_amount_label.dart`: `Money(movement.monto.centimos.abs(), movement.monto.currency)`.
- `topup_bloc.dart` (líneas ~91-92): `TransferLimits.montoMinimo(monto.currency)` / `montoMaximo(monto.currency)`.
- `transfer_error_text.dart` y `topup_error_text.dart`: añadir parámetro `Currency moneda` a `transferSubmitErrorText` / `topUpErrorText` y usar `formatMoney(TransferLimits.montoMaximo(moneda))`; en sus llamadas pasar `state.cuenta?.moneda ?? Currency.pen` (envío) o `widget.cuenta.moneda` (recarga).
- La etiqueta `transferAmountLabel` dice "Monto en soles": cámbiala en el ARB a `"Monto"` (el símbolo ya va en el texto de ayuda) y regenera l10n.

- [ ] **Step 5: Tests**

```bash
cd apps/mobile
grep -rl "Money.fromCentimos\|Money.zero\|formatSoles\|soles.dart" test | xargs sed -i '' -E 's/Money\.fromCentimos\(/Money.soles(/g; s/Money\.zero([^(]|$)/Money.zero(Currency.pen)\1/g; s/formatSoles\(/formatMoney(/g; s#core/format/soles.dart#core/format/money_format.dart#g'
grep -rn "Money.parse(" test   # ajustar a mano: añadir , Currency.pen
grep -rn "TransferLimits.monto" test   # ajustar a mano: (Currency.pen)
grep -rn "moneda: 'PEN'" test   # → moneda: Currency.pen (Account construido a mano)
```

En los backends simulados de los tests HTTP (`test/feature/**/http_*_test.dart`), añadir `'moneda': 'PEN'` a cada movimiento JSON servido.

- [ ] **Step 6: Analizar y probar**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: `No issues found!` y todos los tests en verde. Si un test de pantalla buscaba `'Monto en soles'`, actualízalo a `'Monto'`.

- [ ] **Step 7: Commit**

```bash
git add -A apps/mobile packages
git commit -m "refactor(app): Money con moneda en toda la app; formatMoney reemplaza a formatSoles"
```

---

## Task 3: Cuenta con tipo y nombre; libro en memoria con varias cuentas

**Files:**
- Create: `apps/mobile/lib/feature/account/domain/account_type.dart`
- Create: `apps/mobile/lib/feature/account/domain/account_limits.dart`
- Modify: `apps/mobile/lib/feature/account/domain/account.dart`
- Modify: `apps/mobile/lib/feature/account/infrastructure/http_account_repository.dart`
- Modify: `apps/mobile/lib/feature/account/infrastructure/memory_ledger.dart` (reescritura)
- Modify: `apps/mobile/lib/feature/account/infrastructure/memory_account_repository.dart`
- Modify: `apps/mobile/lib/feature/transfer/infrastructure/memory_transfer_repository.dart` (usa el libro por cuenta)
- Modify: `apps/mobile/test/feature/account/account_repository_contract.dart`, `http_account_repository_test.dart`, `memory_ledger_test.dart`

**Interfaces:**
- Produces:
  - `enum AccountType { ahorro, corriente, sueldo }` con `String code` y `static AccountType? fromCode(String)`.
  - `abstract final class AccountLimits { static const maxCuentas = 5; static const nombreMaxLength = 30; static String? normalizarNombre(String? crudo); }` (recorta; vacío → `null`; NO valida largo, eso lo hace quien llama).
  - `Account { id, numero, tipo: AccountType, moneda: Currency, estado, nombre: String?, saldoDisponible, saldoContable; numeroMasked }`.
  - `MemoryLedger`: `static const cuentaId = 'acc-demo-1'`, `cuentaSueldoId = 'acc-demo-2'`, `cuentaDolaresId = 'acc-demo-3'`; `List<Account> get cuentas`; `Account? cuenta(String id)`; `Money saldoDe(String id)`; `List<MovementDetail> movimientosDe(String id)`; `void registrar({required String cuentaId, ...})`; `Account abrir({required AccountType tipo, required Currency moneda, String? nombre})`; `Account? renombrar(String id, String? nombre)`.

- [ ] **Step 1: Tests primero**

En `account_repository_contract.dart`, añadir al grupo:

```dart
    test('cada cuenta trae tipo, moneda y nombre', () async {
      final c = await primeraCuenta(construir());

      expect(c.tipo, AccountType.ahorro);
      expect(c.moneda, Currency.pen);
      expect(c.nombre, isNull);
    });
```

Cambiar el test existente `expect(cuentas.first.moneda, 'PEN')` → `Currency.pen`.

En `http_account_repository_test.dart` (`FakeAccountsBackend._route` de `/v1/accounts`): añadir `'nombre': null` a la cuenta servida, y un test:

```dart
    test('un tipo de cuenta desconocido es inesperado', () async {
      backend.forced = (status: 200, body: {
        'cuentas': [
          {'id': 'x', 'numero': '19100000000099', 'tipo': 'cts', 'moneda': 'PEN',
           'estado': 'activa', 'nombre': null, 'saldo_disponible': 0, 'saldo_contable': 0},
        ],
      });
      expect((await repo.cuentas()).isLeft(), isTrue);
    });
```

En `memory_ledger_test.dart`, añadir:

```dart
  test('el titular de demo tiene tres cuentas y cada una su saldo', () async {
    final lista = (await cuentas.cuentas()).getRight().toNullable()!;
    expect(lista.map((c) => (c.id, c.tipo, c.moneda, c.saldoDisponible)), [
      ('acc-demo-1', AccountType.ahorro, Currency.pen, const Money.soles(125040)),
      ('acc-demo-2', AccountType.sueldo, Currency.pen, const Money.soles(350000)),
      ('acc-demo-3', AccountType.ahorro, Currency.usd, const Money.dolares(12000)),
    ]);
  });

  test('recargar una cuenta no toca el saldo de las otras', () async {
    await transferencias.recargar(
      cuentaId: MemoryLedger.cuentaDolaresId,
      monto: const Money.dolares(500),
      pin: MemoryTransferRepository.pinValido,
      idempotencyKey: 'recarga-usd-0001',
    );
    final lista = (await cuentas.cuentas()).getRight().toNullable()!;
    expect(lista[0].saldoDisponible, const Money.soles(125040));
    expect(lista[2].saldoDisponible, const Money.dolares(12500));
    final movs = (await cuentas.movimientos(MemoryLedger.cuentaDolaresId)).getRight().toNullable()!;
    expect(movs.items.single.monto, const Money.dolares(500));
  });

  test('las cuentas sin movimientos devuelven una página vacía', () async {
    final p = (await cuentas.movimientos(MemoryLedger.cuentaSueldoId)).getRight().toNullable()!;
    expect(p.items, isEmpty);
    expect(p.nextCursor, isNull);
  });
```

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/feature/account`
Expected: FAIL de compilación (`AccountType` no existe).

- [ ] **Step 3: Dominio**

`account_type.dart`:

```dart
/// Tipo de una cuenta de titular. Espejo del `CHECK` de `accounts.tipo`
/// (sin `sistema`, que nunca llega a la app).
enum AccountType {
  ahorro('ahorro'),
  corriente('corriente'),
  sueldo('sueldo');

  const AccountType(this.code);

  /// Como viaja en el JSON.
  final String code;

  /// `null` ante un tipo desconocido: quien parsea decide.
  static AccountType? fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}
```

`account_limits.dart`:

```dart
/// Reglas de cuentas que la UI aplica ANTES de pedir, espejo del backend.
abstract final class AccountLimits {
  /// Cuentas por titular, cerradas incluidas.
  static const maxCuentas = 5;

  /// Caracteres del nombre que el titular le pone a su cuenta.
  static const nombreMaxLength = 30;

  /// Recortado; vacío es `null`. No valida el largo: eso lo dice la pantalla.
  static String? normalizarNombre(String? crudo) {
    final limpio = (crudo ?? '').trim();
    return limpio.isEmpty ? null : limpio;
  }
}
```

`account.dart`: `final AccountType tipo;`, `final Currency moneda;`, `final String? nombre;` (con doc "Lo pone el titular; `null` si no le puso. Solo lo ve él."). Añadir `nombre` como parámetro opcional del constructor y un `copyWith({String? Function()? nombre, Money? saldoDisponible, Money? saldoContable})` mínimo:

```dart
  /// Copia con otro nombre (`() => null` lo quita) u otros saldos.
  Account copyWith({
    String? Function()? nombre,
    Money? saldoDisponible,
    Money? saldoContable,
  }) => Account(
    id: id,
    numero: numero,
    tipo: tipo,
    moneda: moneda,
    estado: estado,
    nombre: nombre == null ? this.nombre : nombre(),
    saldoDisponible: saldoDisponible ?? this.saldoDisponible,
    saldoContable: saldoContable ?? this.saldoContable,
  );
```

`http_account_repository.dart` `_cuenta`: `tipo: AccountType.fromCode(j['tipo'] as String) ?? (throw FormatException('Tipo desconocido: ${j['tipo']}'))`, `nombre: j['nombre'] as String?`.

- [ ] **Step 4: `MemoryLedger` multicuenta**

Reescribir `memory_ledger.dart`. Mantener el doc de clase (adaptado: "las cuentas del titular de demo y sus movimientos") y los ids de `tx1..tx3`:

```dart
class MemoryLedger {
  MemoryLedger({DateTime Function()? clock})
    : _filas = _sembrar((clock ?? DateTime.now)());

  static const cuentaId = 'acc-demo-1';
  static const cuentaSueldoId = 'acc-demo-2';
  static const cuentaDolaresId = 'acc-demo-3';
  static const tx1 = 'tx-demo-1';
  static const tx2 = 'tx-demo-2';
  static const tx3 = 'tx-demo-3';

  final List<_Fila> _filas;
  int _abiertas = 0;

  List<Account> get cuentas => [for (final f in _filas) f.cuenta];

  Account? cuenta(String id) => _fila(id)?.cuenta;

  /// Saldo de [id]; `StateError` si no existe (quien llama ya lo validó).
  Money saldoDe(String id) => _existente(id).cuenta.saldoDisponible;

  _Fila _existente(String id) => switch (_fila(id)) {
    final _Fila f => f,
    null => throw StateError('Cuenta desconocida en el libro: $id'),
  };

  /// Más reciente primero; vacía si la cuenta no existe.
  List<MovementDetail> movimientosDe(String id) =>
      List.unmodifiable(_fila(id)?.movimientos ?? const []);

  _Fila? _fila(String id) {
    for (final f in _filas) {
      if (f.cuenta.id == id) return f;
    }
    return null;
  }

  /// Aplica una operación al saldo de [cuentaId] y la pone al principio de su
  /// historial.
  void registrar({
    required String cuentaId,
    required String transactionId,
    required MovementKind tipo,
    required MovementDirection direccion,
    required Money monto,
    required DateTime fecha,
    String? contraparte,
    String? motivo,
    String? cuentaDestinoMasked,
  }) {
    final f = _existente(cuentaId);
    final saldo = direccion == MovementDirection.credito
        ? f.cuenta.saldoDisponible + monto
        : f.cuenta.saldoDisponible - monto;
    f.cuenta = f.cuenta.copyWith(saldoDisponible: saldo, saldoContable: saldo);
    f.movimientos.insert(
      0,
      MovementDetail(
        transactionId: transactionId,
        tipo: tipo,
        direccion: direccion,
        monto: monto,
        saldoPosterior: saldo,
        fecha: fecha.toUtc(),
        estado: 'confirmada',
        contraparte: contraparte,
        motivo: motivo,
        cuentaDestinoMasked: cuentaDestinoMasked,
      ),
    );
  }

  /// Abre una cuenta en cero. Las reglas (tope, sueldo única) las aplica el
  /// repositorio, como el router en el backend.
  Account abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
  }) {
    final n = ++_abiertas;
    final cuenta = Account(
      id: 'acc-mem-$n',
      numero: '1910000000${(9000 + n).toString().padLeft(4, '0')}',
      tipo: tipo,
      moneda: moneda,
      estado: 'activa',
      nombre: nombre,
      saldoDisponible: Money.zero(moneda),
      saldoContable: Money.zero(moneda),
    );
    _filas.add(_Fila(cuenta));
    return cuenta;
  }

  /// `null` si [id] no existe.
  Account? renombrar(String id, String? nombre) {
    final f = _fila(id);
    if (f == null) return null;
    f.cuenta = f.cuenta.copyWith(nombre: () => nombre);
    return f.cuenta;
  }

  static List<_Fila> _sembrar(DateTime ahora) {
    // `hoy`, `a(...)` y `ayer` como en el `_sembrar` actual.
    return [
      _Fila(
        const Account(
          id: cuentaId,
          numero: '19100000004521',
          tipo: AccountType.ahorro,
          moneda: Currency.pen,
          estado: 'activa',
          saldoDisponible: Money.soles(125040),
          saldoContable: Money.soles(125040),
        ),
        // Los tres `MovementDetail` (tx1, tx2, tx3) que hoy devuelve
        // `_sembrar`, copiados sin cambios salvo `Money.soles(...)`.
        [...],
      ),
      _Fila(
        const Account(
          id: cuentaSueldoId,
          numero: '19100000008830',
          tipo: AccountType.sueldo,
          moneda: Currency.pen,
          estado: 'activa',
          saldoDisponible: Money.soles(350000),
          saldoContable: Money.soles(350000),
        ),
      ),
      _Fila(
        const Account(
          id: cuentaDolaresId,
          numero: '19100000002207',
          tipo: AccountType.ahorro,
          moneda: Currency.usd,
          estado: 'activa',
          saldoDisponible: Money.dolares(12000),
          saldoContable: Money.dolares(12000),
        ),
      ),
    ];
  }
}

class _Fila {
  _Fila(this.cuenta, [List<MovementDetail>? movimientos])
    : movimientos = movimientos ?? [];

  Account cuenta;
  final List<MovementDetail> movimientos;
}
```

Los tres `MovementDetail` de demo se copian tal cual del `_sembrar` actual (con `Money.soles`) dentro de la lista de la primera fila.

`memory_account_repository.dart`: `cuentas()` → `right(_ledger.cuentas)`; `movimientos(cuentaId, ...)` → si `_ledger.cuenta(cuentaId) == null` → `accountNotFound`, si no pagina sobre `_ledger.movimientosDe(cuentaId)`; `movimiento(txId)` busca en todas las cuentas (`for (final c in _ledger.cuentas) for (final m in _ledger.movimientosDe(c.id))`). Quitar el getter `_cuenta`.

`memory_transfer_repository.dart`: `enviar` valida `_ledger.cuenta(cuentaOrigenId) == null → accountNotFound` (en vez de `!= cuentaId`); fondos con `_ledger.saldoDe(cuentaOrigenId) < monto`; `_postear` recibe `cuentaId` y lo pasa a `_ledger.registrar(cuentaId: ...)`. `recargar` igual con `cuentaId`. (El destino por cuenta llega en la entrega 3.)

- [ ] **Step 5: Probar**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: PASS. Los tests de pantalla del inicio siguen viendo la primera cuenta (S/ 1,250.40).

- [ ] **Step 6: Commit**

```bash
git add -A apps/mobile
git commit -m "feat(app): la cuenta trae tipo y nombre; el libro en memoria lleva tres cuentas"
```

---

## Task 4: Abrir y renombrar en el repositorio de cuentas

**Files:**
- Modify: `apps/mobile/lib/feature/account/domain/account_failure.dart`
- Modify: `apps/mobile/lib/feature/account/domain/account_repository.dart`
- Modify: `apps/mobile/lib/feature/account/application/account_actions.dart`
- Modify: `apps/mobile/lib/feature/account/infrastructure/http_account_repository.dart`
- Modify: `apps/mobile/lib/feature/account/infrastructure/memory_account_repository.dart`
- Modify: `apps/mobile/test/feature/account/account_repository_contract.dart`, `http_account_repository_test.dart`, `memory_account_repository_test.dart`
- Modify: los `implements AccountRepository` de test (`account_bloc_test.dart` `_CountingRepo`, `_GuionRepo`, `_RepoQueFalla`, y cualquier otro: `grep -rn "implements AccountRepository" apps/mobile/test`)

**Interfaces:**
- Produces:
  - `AccountFailure` gana: `limitReached()` → `AccountLimitReached`, `salaryAccountExists()` → `SalaryAccountExists`, `invalidCurrency()` → `InvalidAccountCurrency`, `invalidName()` → `InvalidAccountName`, `wrongPin(int intentosRestantes)` → `AccountWrongPin`, `locked(DateTime hasta)` → `AccountLocked`, `idempotencyKeyReused()` → `AccountKeyReused`.
  - `extension AccountFailureOutcome on AccountFailure { bool get outcomeUnknown; }` → `true` solo para `NetworkFailure` y `UnexpectedFailure`.
  - `AccountRepository.abrir({required AccountType tipo, required Currency moneda, String? nombre, required String pin, required String idempotencyKey}) → FutureResult<AccountFailure, Account>`.
  - `AccountRepository.renombrar(String cuentaId, String? nombre) → FutureResult<AccountFailure, Account>`.
  - `AccountActions.abrir(...)` y `AccountActions.renombrar(...)` (normalizan el nombre con `AccountLimits.normalizarNombre`).
  - `MemoryAccountRepository` acepta `int maxIntentosPin = LockoutPolicy.maxAttempts` y aplica: nombre > 30 → `invalidName`; sueldo no PEN → `invalidCurrency`; ≥ 5 cuentas → `limitReached`; sueldo repetida → `salaryAccountExists`; PIN ≠ `000000` → `wrongPin(restantes)`; misma clave = misma cuenta, otra intención → `idempotencyKeyReused`.

- [ ] **Step 1: Contrato compartido (tests primero)**

En `account_repository_contract.dart`, añadir (el backend simulado del test HTTP debe soportarlo en el Step 4):

```dart
    test('abrir una cuenta la agrega a la lista', () async {
      final repo = construir();
      final nueva = valorDe(await repo.abrir(
        tipo: AccountType.corriente,
        moneda: Currency.usd,
        nombre: 'Viaje',
        pin: '000000',
        idempotencyKey: 'abrir-contrato-01',
      ));

      expect(nueva.tipo, AccountType.corriente);
      expect(nueva.moneda, Currency.usd);
      expect(nueva.nombre, 'Viaje');
      expect(nueva.saldoDisponible, Money.zero(Currency.usd));
      final ids = valorDe(await repo.cuentas()).map((c) => c.id);
      expect(ids, contains(nueva.id));
    });

    test('reintentar la apertura con la misma clave devuelve la misma cuenta', () async {
      final repo = construir();
      Future<Account> abrir() async => valorDe(await repo.abrir(
        tipo: AccountType.ahorro,
        moneda: Currency.pen,
        pin: '000000',
        idempotencyKey: 'abrir-contrato-02',
      ));
      final a = await abrir();
      final b = await abrir();
      expect(b.id, a.id);
    });

    test('renombrar devuelve la cuenta con su nombre nuevo', () async {
      final repo = construir();
      final c = await primeraCuenta(repo);
      expect(valorDe(await repo.renombrar(c.id, 'Casa')).nombre, 'Casa');
      expect(valorDe(await repo.renombrar(c.id, null)).nombre, isNull);
    });

    test('renombrar una cuenta inexistente es accountNotFound', () async {
      expect(
        falloDe(await construir().renombrar('no-existe', 'X')),
        isA<AccountNotFound>(),
      );
    });
```

En `memory_account_repository_test.dart`, las reglas:

```dart
  group('abrir aplica las reglas del backend', () {
    late MemoryAccountRepository repo;
    setUp(() => repo = MemoryAccountRepository(clock: () => DateTime.utc(2026, 10, 6)));

    Future<AccountFailure> falla(Future<Result<AccountFailure, Account>> r) async =>
        ((await r).getLeft().toNullable()! as ServerFailure<AccountFailure>).failure;

    Future<Result<AccountFailure, Account>> abrir({
      AccountType tipo = AccountType.ahorro,
      Currency moneda = Currency.pen,
      String? nombre,
      String pin = '000000',
      required String clave,
    }) => repo.abrir(tipo: tipo, moneda: moneda, nombre: nombre, pin: pin, idempotencyKey: clave);

    test('sueldo en dólares', () async {
      expect(await falla(abrir(tipo: AccountType.sueldo, moneda: Currency.usd, clave: 'k-01')),
          isA<InvalidAccountCurrency>());
    });

    test('la demo ya tiene sueldo', () async {
      expect(await falla(abrir(tipo: AccountType.sueldo, clave: 'k-02')),
          isA<SalaryAccountExists>());
    });

    test('tope de cinco (la demo trae tres)', () async {
      expect((await abrir(clave: 'k-03')).isRight(), isTrue);
      expect((await abrir(clave: 'k-04')).isRight(), isTrue);
      expect(await falla(abrir(clave: 'k-05')), isA<AccountLimitReached>());
    });

    test('nombre de más de 30', () async {
      expect(await falla(abrir(nombre: 'x' * 31, clave: 'k-06')), isA<InvalidAccountName>());
    });

    test('PIN errado descuenta intentos', () async {
      final f = await falla(abrir(pin: '111111', clave: 'k-07'));
      expect(f, isA<AccountWrongPin>());
      expect((f as AccountWrongPin).intentosRestantes, LockoutPolicy.maxAttempts - 1);
    });

    test('misma clave con otro tipo', () async {
      await abrir(clave: 'k-08');
      expect(await falla(abrir(tipo: AccountType.corriente, clave: 'k-08')),
          isA<AccountKeyReused>());
    });
  });
```

En `http_account_repository_test.dart`, el mapeo de errores (con `backend.forced`):

```dart
  group('errores de abrir', () {
    Future<AccountFailure> falla(int status, Map<String, Object?> body) async {
      backend.forced = (status: status, body: body);
      final r = await repo.abrir(
        tipo: AccountType.ahorro, moneda: Currency.pen, pin: '1', idempotencyKey: 'k-000001');
      return (r.getLeft().toNullable()! as ServerFailure<AccountFailure>).failure;
    }

    test('mapea cada code', () async {
      expect(await falla(409, {'code': 'ACCOUNT_LIMIT_REACHED'}), isA<AccountLimitReached>());
      expect(await falla(409, {'code': 'SALARY_ACCOUNT_EXISTS'}), isA<SalaryAccountExists>());
      expect(await falla(400, {'code': 'INVALID_ACCOUNT_CURRENCY'}), isA<InvalidAccountCurrency>());
      expect(await falla(400, {'code': 'INVALID_ACCOUNT_NAME'}), isA<InvalidAccountName>());
      expect(await falla(409, {'code': 'IDEMPOTENCY_KEY_REUSED'}), isA<AccountKeyReused>());
      expect(
        await falla(403, {'code': 'INVALID_CREDENTIALS', 'intentos_restantes': 2}),
        isA<AccountWrongPin>().having((f) => f.intentosRestantes, 'restantes', 2),
      );
      expect(
        await falla(423, {'code': 'DEVICE_LOCKED', 'locked_until': '2026-10-06T15:00:00+00:00'}),
        isA<AccountLocked>(),
      );
    });

    test('abrir manda el body del contrato', () async {
      backend.forced = null;
      await repo.abrir(tipo: AccountType.sueldo, moneda: Currency.pen, nombre: 'Planilla',
          pin: '000000', idempotencyKey: 'k-000002');
      final req = backend.requests.last;
      expect(req.method, 'POST');
      expect(req.path, '/v1/accounts');
      expect(req.data, {'tipo': 'sueldo', 'moneda': 'PEN', 'nombre': 'Planilla',
          'pin': '000000', 'idempotency_key': 'k-000002'});
    });
  });
```

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/feature/account`
Expected: FAIL de compilación.

- [ ] **Step 3: Failures, contrato, acciones**

`account_failure.dart`: añadir los factories y subclases con doc de una línea cada una (mismo estilo del archivo), más:

```dart
extension AccountFailureOutcome on AccountFailure {
  /// El fallo deja DESCONOCIDO si la cuenta se abrió (red, inesperado): solo
  /// es seguro reintentar con la MISMA clave.
  bool get outcomeUnknown => switch (this) {
    NetworkFailure() || UnexpectedFailure() => true,
    AccountNotFound() ||
    Unauthenticated() ||
    AccountLimitReached() ||
    SalaryAccountExists() ||
    InvalidAccountCurrency() ||
    InvalidAccountName() ||
    AccountWrongPin() ||
    AccountLocked() ||
    AccountKeyReused() => false,
  };
}
```

`account_repository.dart`: añadir los dos métodos con doc ("Abre otra cuenta del titular. Pide PIN y una `idempotencyKey` de 8 a 64 caracteres generada UNA vez por intención." / "Pone o quita (`null`) el nombre. Sin PIN.").

`account_actions.dart`:

```dart
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _repo.abrir(
    tipo: tipo,
    moneda: moneda,
    nombre: AccountLimits.normalizarNombre(nombre),
    pin: pin,
    idempotencyKey: idempotencyKey,
  );

  FutureResult<AccountFailure, Account> renombrar(String cuentaId, String? nombre) =>
      _repo.renombrar(cuentaId, AccountLimits.normalizarNombre(nombre));
```

- [ ] **Step 4: HTTP**

```dart
  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) => _guard(() async {
    final response = await _dio.post<dynamic>('/v1/accounts', data: {
      'tipo': tipo.code,
      'moneda': moneda.code,
      'nombre': nombre,
      'pin': pin,
      'idempotency_key': idempotencyKey,
    });
    final failure = _failureFor(response);
    if (failure != null) return left(GlobalFailure.server(failure));
    return right(_cuenta(_cuerpo(response)));
  });

  @override
  FutureResult<AccountFailure, Account> renombrar(String cuentaId, String? nombre) =>
      _guard(() async {
        final response = await _dio.patch<dynamic>(
          '/v1/accounts/${Uri.encodeComponent(cuentaId)}/nombre',
          data: {'nombre': nombre},
        );
        final failure = _failureFor(response);
        if (failure != null) return left(GlobalFailure.server(failure));
        return right(_cuenta(_cuerpo(response)));
      });
```

`_failureFor` pasa a mapear por `code` (con `body` como en `HttpTransferRepository`):

```dart
    final data = response.data;
    final body = data is Map ? data : const <Object?, Object?>{};
    return switch (body['code']) {
      'ACCOUNT_NOT_FOUND' || 'MOVEMENT_NOT_FOUND' => const AccountFailure.accountNotFound(),
      'ACCOUNT_LIMIT_REACHED' => const AccountFailure.limitReached(),
      'SALARY_ACCOUNT_EXISTS' => const AccountFailure.salaryAccountExists(),
      'INVALID_ACCOUNT_CURRENCY' => const AccountFailure.invalidCurrency(),
      'INVALID_ACCOUNT_NAME' => const AccountFailure.invalidName(),
      'IDEMPOTENCY_KEY_REUSED' => const AccountFailure.idempotencyKeyReused(),
      'INVALID_CREDENTIALS' => switch (body['intentos_restantes']) {
        final int n => AccountFailure.wrongPin(n),
        _ => const AccountFailure.unexpected(),
      },
      'IDENTIFIER_LOCKED' || 'DEVICE_LOCKED' => switch (_instante(body['locked_until'])) {
        final DateTime hasta => AccountFailure.locked(hasta),
        _ => const AccountFailure.unexpected(),
      },
      _ => const AccountFailure.unexpected(),
    };
```

Copia `_instante` de `HttpTransferRepository` (UTC forzado). En `FakeAccountsBackend` del test: guardar las cuentas en una lista mutable, responder `POST /v1/accounts` (con clave ya vista → 200 con la misma cuenta; nueva → 201 con `id: 'acc-http-N'`, `numero: '191000000099NN'`, saldos 0, `nombre` del body) y `PATCH /v1/accounts/{id}/nombre` (200 con la cuenta y el nombre nuevo; id desconocido → 404 `ACCOUNT_NOT_FOUND`). El adaptador debe leer el body de `options.data`.

- [ ] **Step 5: Memory**

En `MemoryAccountRepository`: añadir campos `int _fallosPin = 0`, `final _aperturas = <String, ({String huella, Account cuenta})>{}` y:

```dart
  @override
  FutureResult<AccountFailure, Account> abrir({
    required AccountType tipo,
    required Currency moneda,
    String? nombre,
    required String pin,
    required String idempotencyKey,
  }) async {
    // Mismo orden que el router: nombre, reintento, reglas, PIN al final.
    if (nombre != null && nombre.length > AccountLimits.nombreMaxLength) {
      return _falla(const AccountFailure.invalidName());
    }
    final huella = '${tipo.code}|${moneda.code}|${nombre ?? ''}';
    if (_aperturas[idempotencyKey] case final previa?) {
      return previa.huella == huella
          ? right(_ledger.cuenta(previa.cuenta.id) ?? previa.cuenta)
          : _falla(const AccountFailure.idempotencyKeyReused());
    }
    if (tipo == AccountType.sueldo && moneda != Currency.pen) {
      return _falla(const AccountFailure.invalidCurrency());
    }
    final actuales = _ledger.cuentas;
    if (actuales.length >= AccountLimits.maxCuentas) {
      return _falla(const AccountFailure.limitReached());
    }
    if (tipo == AccountType.sueldo && actuales.any((c) => c.tipo == AccountType.sueldo)) {
      return _falla(const AccountFailure.salaryAccountExists());
    }
    if (pin != pinValido) {
      _fallosPin++;
      return _falla(AccountFailure.wrongPin(maxIntentosPin - _fallosPin));
    }
    _fallosPin = 0;
    final cuenta = _ledger.abrir(tipo: tipo, moneda: moneda, nombre: nombre);
    _aperturas[idempotencyKey] = (huella: huella, cuenta: cuenta);
    return right(cuenta);
  }

  @override
  FutureResult<AccountFailure, Account> renombrar(String cuentaId, String? nombre) async {
    if (nombre != null && nombre.length > AccountLimits.nombreMaxLength) {
      return _falla(const AccountFailure.invalidName());
    }
    return switch (_ledger.renombrar(cuentaId, nombre)) {
      final Account c => right(c),
      null => _falla(const AccountFailure.accountNotFound()),
    };
  }

  Result<AccountFailure, T> _falla<T>(AccountFailure f) => left(GlobalFailure.server(f));
```

con `static const pinValido = '000000';` y el parámetro de constructor `this.maxIntentosPin = LockoutPolicy.maxAttempts` (import de `lockout_policy.dart`). Documentar en el doc de clase que este mock no bloquea por tiempo (el de transferencias sí), y por qué basta: abrir cuenta no mueve dinero.

Actualizar los repos de prueba que implementan `AccountRepository` (delegan en `_inner.abrir(...)` / `_inner.renombrar(...)`; `_RepoQueFalla` devuelve `network`).

- [ ] **Step 6: Probar y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: PASS.

```bash
git add -A apps/mobile
git commit -m "feat(app): abrir otra cuenta y renombrarla en el repositorio de cuentas (HTTP y memoria)"
```

---

## Task 5: `AccountBloc` con varias cuentas

**Files:**
- Modify: `apps/mobile/lib/presentation/home/bloc/account_bloc.dart`, `account_event.dart`, `account_state.dart` (+ `.freezed.dart` regenerado)
- Modify: `apps/mobile/test/presentation/home/account_bloc_test.dart`
- Modify: `apps/mobile/test/presentation/home/home_screen_test.dart` (constructores de `AccountState` con `cuenta:`)

**Interfaces:**
- Produces:
  - `AccountState { status, List<Account> cuentas, int seleccionada, movimientos, nextCursor, loadingMore, refreshing, refreshFailed, failure, bool renaming, AccountFailure? renameFailure }` con getter `Account? cuenta` (la seleccionada) y `bool puedeAbrirOtra` (`cuentas.length < AccountLimits.maxCuentas`).
  - Eventos nuevos: `AccountEvent.selected(int indice)`, `AccountEvent.opened(Account cuenta)`, `AccountEvent.renameRequested({required String cuentaId, String? nombre})`.

- [ ] **Step 1: Tests**

En `account_bloc_test.dart` añadir (usa `MemoryAccountRepository` con sus 3 cuentas y los repos de prueba del archivo):

```dart
  group('varias cuentas', () {
    blocTest<AccountBloc, AccountState>(
      'arranca en la primera y trae sus movimientos',
      build: () => AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) => b.add(const AccountEvent.started()),
      verify: (b) {
        expect(b.state.cuentas, hasLength(3));
        expect(b.state.cuenta?.id, MemoryLedger.cuentaId);
        expect(b.state.movimientos, hasLength(3));
      },
    );

    blocTest<AccountBloc, AccountState>(
      'deslizar a otra cuenta trae los movimientos de esa',
      build: () => AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaSueldoId);
        expect(b.state.movimientos, isEmpty);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'una respuesta tardía de la cuenta anterior no se pinta en la nueva',
      build: () {
        final repo = _CountingRepo(MemoryAccountRepository(clock: _reloj)); // 20 ms por página
        return AccountBloc(AccountActions(repo));
      },
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(0 + 2)); // dólares
        b.add(const AccountEvent.selected(0));     // vuelve antes de que llegue
      },
      wait: const Duration(milliseconds: 100),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaId);
        expect(b.state.movimientos.map((m) => m.transactionId), [
          MemoryLedger.tx1, MemoryLedger.tx2, MemoryLedger.tx3,
        ]);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'deslizar mientras refresca: la cuenta visible y sus movimientos coinciden',
      build: () => AccountBloc(AccountActions(_CountingRepo(MemoryAccountRepository(clock: _reloj)))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.refreshed());
        b.add(const AccountEvent.selected(1));
      },
      wait: const Duration(milliseconds: 150),
      verify: (b) {
        expect(b.state.cuenta?.id, MemoryLedger.cuentaSueldoId);
        expect(b.state.movimientos, isEmpty); // los del sueldo, no los de ahorros
        expect(b.state.refreshing, isFalse);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'una cuenta recién abierta se agrega y queda seleccionada',
      build: () => AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(AccountEvent.opened(_cuentaNueva));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuentas.last.id, _cuentaNueva.id);
        expect(b.state.cuenta?.id, _cuentaNueva.id);
      },
    );

    blocTest<AccountBloc, AccountState>(
      'renombrar actualiza la tarjeta sin perder la selección',
      build: () => AccountBloc(AccountActions(MemoryAccountRepository(clock: _reloj))),
      act: (b) async {
        b.add(const AccountEvent.started());
        await b.stream.firstWhere((s) => s.status == AccountStatus.ready);
        b.add(const AccountEvent.selected(1));
        b.add(const AccountEvent.renameRequested(cuentaId: MemoryLedger.cuentaSueldoId, nombre: 'Planilla'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (b) {
        expect(b.state.cuenta?.nombre, 'Planilla');
        expect(b.state.seleccionada, 1);
        expect(b.state.renaming, isFalse);
        expect(b.state.renameFailure, isNull);
      },
    );
  });
```

con, al tope del archivo:

```dart
DateTime _reloj() => DateTime.utc(2026, 10, 6, 12);

const _cuentaNueva = Account(
  id: 'acc-nueva',
  numero: '19100000009999',
  tipo: AccountType.corriente,
  moneda: Currency.usd,
  estado: 'activa',
  saldoDisponible: Money.dolares(0),
  saldoContable: Money.dolares(0),
);
```

En `home_screen_test.dart`, los `AccountState(cuenta: x, ...)` pasan a `AccountState(cuentas: [x], ...)`.

- [ ] **Step 2: Ver que fallan**

Run: `cd apps/mobile && flutter test test/presentation/home/account_bloc_test.dart`
Expected: FAIL de compilación.

- [ ] **Step 3: Estado y eventos**

`account_state.dart`:

```dart
@freezed
abstract class AccountState with _$AccountState {
  const AccountState._();

  const factory AccountState({
    @Default(AccountStatus.loading) AccountStatus status,

    /// Todas las cuentas del titular, en el orden del servidor.
    @Default(<Account>[]) List<Account> cuentas,

    /// Índice en [cuentas] de la que se ve en el carrusel.
    @Default(0) int seleccionada,
    @Default(<Movement>[]) List<Movement> movimientos,
    String? nextCursor,
    @Default(false) bool loadingMore,
    @Default(false) bool refreshing,
    @Default(false) bool refreshFailed,
    AccountFailure? failure,

    /// Hay un cambio de nombre en vuelo.
    @Default(false) bool renaming,

    /// El último cambio de nombre falló; `null` si salió bien o no hubo.
    AccountFailure? renameFailure,
  }) = _AccountState;

  /// La cuenta visible; `null` sin cuentas.
  Account? get cuenta =>
      seleccionada < cuentas.length ? cuentas[seleccionada] : null;

  bool get puedeAbrirOtra => cuentas.length < AccountLimits.maxCuentas;
}
```

`account_event.dart`: añadir

```dart
  /// El carrusel se detuvo en otra cuenta.
  const factory AccountEvent.selected(int indice) = AccountSelected;

  /// Se abrió una cuenta: se agrega y queda a la vista.
  const factory AccountEvent.opened(Account cuenta) = AccountOpened;

  /// Poner o quitar (`null`) el nombre de una cuenta.
  const factory AccountEvent.renameRequested({
    required String cuentaId,
    String? nombre,
  }) = AccountRenameRequested;
```

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Bloc**

Registrar `on<AccountSelected>`, `on<AccountOpened>`, `on<AccountRenameRequested>`. Cambiar `_loadFirstPage` para elegir por id:

```dart
  Future<Either<AccountFailure, ({List<Account> cuentas, int indice, MovementPage page})>>
  _loadFirstPage({String? preferirId}) async {
    final cuentas = await _actions.cuentas();
    final elegida = cuentas.match<Either<AccountFailure, ({List<Account> lista, int i})>>(
      (failure) => left(_toAccountFailure(failure)),
      (lista) {
        if (lista.isEmpty) return left(const AccountFailure.accountNotFound());
        final i = lista.indexWhere((c) => c.id == preferirId);
        return right((lista: lista, i: i < 0 ? 0 : i));
      },
    );
    return switch (elegida) {
      Left(:final value) => left(value),
      Right(value: (:final lista, :final i)) =>
        (await _actions.movimientos(lista[i].id)).match(
          (failure) => left(_toAccountFailure(failure)),
          (page) => right((cuentas: lista, indice: i, page: page)),
        ),
    };
  }
```

`_onStarted`: `AccountState(status: ready, cuentas: data.cuentas, seleccionada: data.indice, movimientos: data.page.items, nextCursor: data.page.nextCursor)`.

`_onRefreshed`:

```dart
    final antes = state.cuenta?.id;
    final loaded = await _loadFirstPage(preferirId: antes);
    emit(
      loaded.match(
        (failure) => state.cuenta == null
            ? AccountState(status: AccountStatus.error, failure: failure)
            : state.copyWith(refreshing: false, refreshFailed: true),
        (data) {
          final ahora = state.cuenta?.id;
          if (ahora != antes) {
            // Deslizó mientras tanto: los movimientos que llegaron son de la
            // cuenta anterior. Se toman los saldos nuevos y se conserva lo que
            // `selected` ya trajo para la cuenta visible.
            final i = data.cuentas.indexWhere((c) => c.id == ahora);
            return state.copyWith(
              refreshing: false,
              refreshFailed: false,
              cuentas: data.cuentas,
              seleccionada: i < 0 ? 0 : i,
            );
          }
          _generation++;
          return AccountState(
            status: AccountStatus.ready,
            cuentas: data.cuentas,
            seleccionada: data.indice,
            movimientos: data.page.items,
            nextCursor: data.page.nextCursor,
          );
        },
      ),
    );
```

(quitar el `if (loaded.isRight()) _generation++;` previo: ahora se incrementa dentro).

`_onSelected`:

```dart
  Future<void> _onSelected(AccountSelected event, Emitter<AccountState> emit) async {
    if (event.indice == state.seleccionada ||
        event.indice < 0 ||
        event.indice >= state.cuentas.length) {
      return;
    }
    // Otra cuenta, otra lista: cualquier página en vuelo es de la anterior.
    final generation = ++_generation;
    emit(state.copyWith(
      seleccionada: event.indice,
      movimientos: const [],
      nextCursor: null,
      loadingMore: true,
    ));
    final result = await _actions.movimientos(state.cuentas[event.indice].id);
    if (generation != _generation) return;
    emit(result.match(
      (failure) => state.copyWith(loadingMore: false, refreshFailed: true),
      (page) => state.copyWith(
        loadingMore: false,
        movimientos: page.items,
        nextCursor: page.nextCursor,
      ),
    ));
  }
```

`_onMoreRequested`: además de `generation`, guardar `final cuentaId = cuenta.id;` y descartar si `state.cuenta?.id != cuentaId` tras el `await`. Condición de salida: `state.loadingMore` ya cubre la carga de `selected`.

`_onOpened`:

```dart
  Future<void> _onOpened(AccountOpened event, Emitter<AccountState> emit) async {
    final cuentas = [...state.cuentas, event.cuenta];
    emit(state.copyWith(cuentas: cuentas));
    add(AccountEvent.selected(cuentas.length - 1));
  }
```

`_onRenameRequested`:

```dart
  Future<void> _onRenameRequested(
    AccountRenameRequested event,
    Emitter<AccountState> emit,
  ) async {
    if (state.renaming) return;
    emit(state.copyWith(renaming: true, renameFailure: null));
    final result = await _actions.renombrar(event.cuentaId, event.nombre);
    emit(result.match(
      (failure) => state.copyWith(renaming: false, renameFailure: _toAccountFailure(failure)),
      (cuenta) => state.copyWith(
        renaming: false,
        cuentas: [for (final c in state.cuentas) c.id == cuenta.id ? cuenta : c],
      ),
    ));
  }
```

Actualizar el doc de clase: "Las cuentas del titular, la que se ve en el carrusel y sus movimientos."

- [ ] **Step 5: Probar y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: PASS.

```bash
git add -A apps/mobile
git commit -m "feat(app): el bloc del inicio lleva todas las cuentas y la seleccionada"
```

---

## Task 6: Inicio con carrusel de cuentas y cambio de nombre

**Files:**
- Create: `apps/mobile/lib/presentation/account/account_label.dart` (helpers de texto, sin widgets)
- Create: `apps/mobile/lib/presentation/home/widgets/account_carousel.dart`
- Create: `apps/mobile/lib/presentation/home/widgets/add_account_card.dart`
- Create: `apps/mobile/lib/presentation/home/widgets/rename_account_sheet.dart`
- Modify: `apps/mobile/lib/presentation/home/widgets/balance_card.dart`
- Modify: `apps/mobile/lib/presentation/home/home_screen.dart`
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb` (+ regenerado)
- Modify: `apps/mobile/lib/presentation/app/app_routes.dart` (`abrirCuenta`, usado en Task 7; el botón ya navega)
- Test: `apps/mobile/test/presentation/home/home_screen_test.dart`, Create `apps/mobile/test/presentation/home/account_carousel_test.dart`

**Interfaces:**
- Consumes: `AccountState.cuentas/seleccionada/puedeAbrirOtra`, eventos `selected`, `opened`, `renameRequested`.
- Produces:
  - `String accountTypeLabel(AppLocalizations l10n, AccountType t)` → "Cuenta de ahorros" | "Cuenta corriente" | "Cuenta sueldo".
  - `String accountTypeShort(AppLocalizations l10n, AccountType t)` → "Ahorros" | "Corriente" | "Sueldo".
  - `String accountLabel(AppLocalizations l10n, Account c)` → `c.nombre ?? accountTypeLabel(l10n, c.tipo)`.
  - `AccountCarousel({required List<Account> cuentas, required int seleccionada, required ValueChanged<int> onSelected, required ValueChanged<Account> onRename, VoidCallback? onOpenAccount})` (`onOpenAccount == null` → sin tarjeta de abrir).
  - `AppRoutes.abrirCuenta = '/cuentas/abrir'`.

- [ ] **Step 1: Copy en el ARB**

Añadir en `app_es.arb` (junto a los `home*`):

```json
  "accountTypeAhorroLong": "Cuenta de ahorros",
  "accountTypeCorrienteLong": "Cuenta corriente",
  "accountTypeSueldoLong": "Cuenta sueldo",
  "accountTypeAhorroShort": "Ahorros",
  "accountTypeCorrienteShort": "Corriente",
  "accountTypeSueldoShort": "Sueldo",
  "currencyPenName": "Soles",
  "currencyUsdName": "Dólares",
  "homeAccountPage": "Cuenta {actual} de {total}",
  "@homeAccountPage": {"placeholders": {"actual": {"type": "int"}, "total": {"type": "int"}}},
  "homeRenameTooltip": "Cambiar el nombre de la cuenta",
  "homeOpenAccountTitle": "Abrir otra cuenta",
  "homeOpenAccountHint": "Ahorros, corriente o sueldo, en soles o dólares",
  "renameAccountTitle": "Nombre de la cuenta",
  "renameAccountHint": "Ej. Viaje",
  "renameAccountSave": "Guardar",
  "renameAccountClear": "Quitar nombre",
  "renameAccountError": "No pudimos guardar el nombre. Inténtalo de nuevo.",
  "renameAccountTooLong": "Usa hasta 30 caracteres.",
```

Run: `cd apps/mobile && flutter gen-l10n`

- [ ] **Step 2: Tests de widget**

Create `test/presentation/home/account_carousel_test.dart`:

```dart
// imports: flutter_test, material, design_system, l10n, core_kernel, Account, AccountType,
// AccountCarousel.

Widget _app(Widget child) => MaterialApp(
  theme: CuyCashTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Account _c(String id, AccountType t, Currency m, int c, {String? nombre}) => Account(
  id: id, numero: '1910000000${id.hashCode.abs() % 10000}'.padRight(14, '0'),
  tipo: t, moneda: m, estado: 'activa', nombre: nombre,
  saldoDisponible: Money(c, m), saldoContable: Money(c, m),
);

void main() {
  final tres = [
    _c('a', AccountType.ahorro, Currency.pen, 125040),
    _c('b', AccountType.sueldo, Currency.pen, 350000, nombre: 'Planilla'),
    _c('c', AccountType.ahorro, Currency.usd, 12000),
  ];

  testWidgets('muestra la etiqueta y el saldo de la cuenta seleccionada', (t) async {
    await t.pumpWidget(_app(AccountCarousel(
      cuentas: tres, seleccionada: 0, onSelected: (_) {}, onRename: (_) {}, onOpenAccount: () {},
    )));
    expect(find.text('Cuenta de ahorros'), findsOneWidget);
    expect(find.text('S/ 1,250.40'), findsOneWidget);
    expect(find.bySemanticsLabel('Cuenta 1 de 3'), findsOneWidget);
  });

  testWidgets('deslizar avisa el índice nuevo', (t) async {
    int? elegido;
    await t.pumpWidget(_app(AccountCarousel(
      cuentas: tres, seleccionada: 0, onSelected: (i) => elegido = i, onRename: (_) {}, onOpenAccount: () {},
    )));
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    expect(elegido, 1);
    expect(find.text('Planilla'), findsOneWidget);
  });

  testWidgets('la última página es abrir otra cuenta', (t) async {
    var abrio = false;
    await t.pumpWidget(_app(AccountCarousel(
      cuentas: tres, seleccionada: 2, onSelected: (_) {}, onRename: (_) {}, onOpenAccount: () => abrio = true,
    )));
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    await t.tap(find.text('Abrir otra cuenta'));
    expect(abrio, isTrue);
  });

  testWidgets('sin onOpenAccount (tope alcanzado) no hay tarjeta de abrir', (t) async {
    await t.pumpWidget(_app(AccountCarousel(
      cuentas: tres, seleccionada: 2, onSelected: (_) {}, onRename: (_) {}, onOpenAccount: null,
    )));
    await t.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await t.pumpAndSettle();
    expect(find.text('Abrir otra cuenta'), findsNothing);
  });

  testWidgets('el saldo en dólares se pinta en dólares', (t) async {
    await t.pumpWidget(_app(AccountCarousel(
      cuentas: tres, seleccionada: 2, onSelected: (_) {}, onRename: (_) {}, onOpenAccount: () {},
    )));
    expect(find.text(r'US$ 120.00'), findsOneWidget);
  });
}
```

En `home_screen_test.dart`, añadir un test con el grafo `mock` (como `send_flow_test.dart`): tocar el lápiz de la primera tarjeta, escribir "Casa", "Guardar" → la tarjeta muestra "Casa". Y otro: con `AccountState` de 5 cuentas no aparece "Abrir otra cuenta" tras deslizar al final.

- [ ] **Step 3: Ver que fallan**

Run: `cd apps/mobile && flutter test test/presentation/home`
Expected: FAIL de compilación.

- [ ] **Step 4: Implementar**

`account_label.dart`:

```dart
import '../../feature/account/domain/account.dart';
import '../../feature/account/domain/account_type.dart';
import '../../l10n/app_localizations.dart';

/// "Cuenta de ahorros", para títulos.
String accountTypeLabel(AppLocalizations l10n, AccountType t) => switch (t) {
  AccountType.ahorro => l10n.accountTypeAhorroLong,
  AccountType.corriente => l10n.accountTypeCorrienteLong,
  AccountType.sueldo => l10n.accountTypeSueldoLong,
};

/// "Ahorros", para líneas compactas ("Ahorros · S/ · ••••1234").
String accountTypeShort(AppLocalizations l10n, AccountType t) => switch (t) {
  AccountType.ahorro => l10n.accountTypeAhorroShort,
  AccountType.corriente => l10n.accountTypeCorrienteShort,
  AccountType.sueldo => l10n.accountTypeSueldoShort,
};

/// Cómo llama el titular a su cuenta: su nombre, o el tipo.
String accountLabel(AppLocalizations l10n, Account c) =>
    c.nombre ?? accountTypeLabel(l10n, c.tipo);
```

`balance_card.dart`: cambiar la API a `BalanceCard({required Account cuenta, VoidCallback? onRename, super.key})`. Fila superior: `Text(accountLabel(l10n, cuenta))` en lugar de `homeBalanceLabel`, un `IconButton(icon: Icons.edit_outlined, tooltip: l10n.homeRenameTooltip, onPressed: onRename)` si `onRename != null`, y el ojo. Saldo: `formatMoney(cuenta.saldoDisponible)`. Línea inferior: `l10n.homeWalletMask(cuenta.numeroMasked)` precedida de `cuenta.moneda.symbol` (`'${cuenta.moneda.symbol} · ${l10n.homeWalletMask(...)}'`). Mantener colores y tipografía actuales.

`add_account_card.dart`:

```dart
/// Última página del carrusel: invita a abrir otra cuenta.
class AddAccountCard extends StatelessWidget {
  const AddAccountCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: CuyCashColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(CuyCashRadii.card + 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, size: 32, color: CuyCashColors.primary),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(l10n.homeOpenAccountTitle, style: CuyCashTypography.titleMd),
              const SizedBox(height: CuyCashSpacing.stackXs),
              Text(
                l10n.homeOpenAccountHint,
                textAlign: TextAlign.center,
                style: CuyCashTypography.bodyMd.copyWith(color: CuyCashColors.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

(Si `CuyCashColors.primary` o `surfaceContainerLow` no existen con ese nombre, usa los tokens equivalentes de `packages/design_system/lib/src/tokens/`; no pongas hex.)

`account_carousel.dart`:

```dart
/// Las cuentas del titular, una por página, y al final "Abrir otra cuenta".
///
/// La página visible la manda [seleccionada] (el bloc): si cambia desde
/// fuera (cuenta recién abierta), el carrusel salta a ella.
class AccountCarousel extends StatefulWidget {
  const AccountCarousel({
    required this.cuentas,
    required this.seleccionada,
    required this.onSelected,
    required this.onRename,
    this.onOpenAccount,
    super.key,
  });

  final List<Account> cuentas;
  final int seleccionada;
  final ValueChanged<int> onSelected;
  final ValueChanged<Account> onRename;

  /// `null` = ya no se puede abrir otra (tope): no hay última página.
  final VoidCallback? onOpenAccount;

  /// Alto fijo: un `PageView` necesita uno, y todas las tarjetas miden igual.
  static const height = 176.0;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  late final PageController _controller = PageController(initialPage: widget.seleccionada);
  late int _pagina = widget.seleccionada;

  @override
  void didUpdateWidget(AccountCarousel old) {
    super.didUpdateWidget(old);
    if (widget.seleccionada != _pagina && _controller.hasClients) {
      _pagina = widget.seleccionada;
      _controller.animateToPage(
        widget.seleccionada,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final abrir = widget.onOpenAccount;
    final paginas = widget.cuentas.length + (abrir == null ? 0 : 1);
    return Column(
      children: [
        SizedBox(
          height: AccountCarousel.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: paginas,
            onPageChanged: (i) {
              setState(() => _pagina = i);
              // La página de "abrir" no es una cuenta: no cambia la selección.
              if (i < widget.cuentas.length) widget.onSelected(i);
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: CuyCashSpacing.stackXs),
              child: i < widget.cuentas.length
                  ? BalanceCard(
                      cuenta: widget.cuentas[i],
                      onRename: () => widget.onRename(widget.cuentas[i]),
                    )
                  : switch (abrir) {
                      final VoidCallback f => AddAccountCard(onTap: f),
                      null => const SizedBox.shrink(),
                    },
            ),
          ),
        ),
        const SizedBox(height: CuyCashSpacing.stackSm),
        Semantics(
          label: l10n.homeAccountPage(
            (_pagina.clamp(0, widget.cuentas.length - 1)) + 1,
            widget.cuentas.length,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < paginas; i++)
                  Container(
                    width: i == _pagina ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _pagina ? CuyCashColors.primary : CuyCashColors.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

`BalanceCard` debe caber en 176 de alto: si desborda en el test de 400×1000, reduce `stackSm` entre filas, no el alto.

`rename_account_sheet.dart`:

```dart
/// Hoja para poner o quitar el nombre de una cuenta. Despacha al
/// [AccountBloc] y se cierra cuando el cambio se guardó; si falla, lo dice y
/// se queda.
class RenameAccountSheet extends StatefulWidget {
  const RenameAccountSheet({required this.cuenta, super.key});

  final Account cuenta;

  static Future<void> show(BuildContext context, Account cuenta) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<AccountBloc>(),
      child: RenameAccountSheet(cuenta: cuenta),
    ),
  );

  @override
  State<RenameAccountSheet> createState() => _RenameAccountSheetState();
}

class _RenameAccountSheetState extends State<RenameAccountSheet> {
  late final _controller = TextEditingController(text: widget.cuenta.nombre ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _guardar(String? nombre) => context.read<AccountBloc>().add(
    AccountEvent.renameRequested(cuentaId: widget.cuenta.id, nombre: nombre),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (a, b) => a.renaming && !b.renaming,
      listener: (context, state) {
        if (state.renameFailure == null) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final largo = _controller.text.trim().length > AccountLimits.nombreMaxLength;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            CuyCashSpacing.marginMobile,
            CuyCashSpacing.stackMd,
            CuyCashSpacing.marginMobile,
            MediaQuery.viewInsetsOf(context).bottom + CuyCashSpacing.stackMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.renameAccountTitle, style: CuyCashTypography.titleMd),
              const SizedBox(height: CuyCashSpacing.stackMd),
              CuyCashTextField(
                label: l10n.renameAccountTitle,
                hint: l10n.renameAccountHint,
                controller: _controller,
                autofocus: true,
                maxLength: AccountLimits.nombreMaxLength,
                onChanged: (_) => setState(() {}),
                errorText: largo
                    ? l10n.renameAccountTooLong
                    : (state.renameFailure == null ? null : l10n.renameAccountError),
              ),
              const SizedBox(height: CuyCashSpacing.stackMd),
              PrimaryButton(
                label: l10n.renameAccountSave,
                loading: state.renaming,
                onPressed: largo || state.renaming ? null : () => _guardar(_controller.text),
              ),
              if (widget.cuenta.nombre != null) ...[
                const SizedBox(height: CuyCashSpacing.stackSm),
                SecondaryButton(
                  label: l10n.renameAccountClear,
                  onPressed: state.renaming ? null : () => _guardar(null),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
```

`home_screen.dart` `_ReadyView`: reemplazar el bloque `if (cuenta != null) ...[BalanceCard(...)]` por

```dart
        if (state.cuentas.isNotEmpty) ...[
          AccountCarousel(
            cuentas: state.cuentas,
            seleccionada: state.seleccionada,
            onSelected: (i) =>
                context.read<AccountBloc>().add(AccountEvent.selected(i)),
            onRename: (c) => RenameAccountSheet.show(context, c),
            onOpenAccount: state.puedeAbrirOtra ? () => _openAccount(context) : null,
          ),
          const SizedBox(height: CuyCashSpacing.stackMd),
        ],
```

con

```dart
  Future<void> _openAccount(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    final nueva = await context.push<Account>(
      AppRoutes.abrirCuenta,
      extra: bloc.state.cuentas,
    );
    if (nueva != null) bloc.add(AccountEvent.opened(nueva));
  }
```

`app_routes.dart`: `static const abrirCuenta = '/cuentas/abrir';`. (La ruta se registra en la Task 7; hasta entonces el botón de abrir no debe tocarse en tests de esta task.)

- [ ] **Step 5: Probar y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: PASS.

```bash
git add -A apps/mobile
git commit -m "feat(app): carrusel de cuentas en el inicio y cambio de nombre"
```

---

## Task 7: Abrir otra cuenta (dos pasos: datos y PIN)

**Files:**
- Create: `apps/mobile/lib/presentation/account_open/bloc/open_account_bloc.dart`, `open_account_event.dart`, `open_account_state.dart` (+ `.freezed.dart`)
- Create: `apps/mobile/lib/presentation/account_open/open_account_screen.dart`
- Create: `apps/mobile/lib/presentation/account_open/open_account_error_text.dart`
- Modify: `apps/mobile/lib/presentation/app/router.dart` (ruta `abrirCuenta`)
- Modify: `apps/mobile/lib/feature/transfer/application/pending_transfer_actions.dart` (`huellaApertura`)
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Create: `apps/mobile/test/presentation/account_open/open_account_bloc_test.dart`, `open_account_flow_test.dart`

**Interfaces:**
- Consumes: `AccountActions.abrir`, `AccountFailure` + `outcomeUnknown`, `PendingTransferActions` (`recover`/`remember`/`forget`), `AccountLimits`, `accountTypeLabel`.
- Produces:
  - `static String PendingTransferActions.huellaApertura({required AccountType tipo, required Currency moneda, String? nombre})` → `'abrir|${tipo.code}|${moneda.code}|${nombre ?? ''}'`.
  - `OpenAccountBloc(AccountActions, {required PendingTransferActions pending, required String userId, required List<Account> cuentas, String Function()? newKey})`.
  - Eventos: `opened()`, `tipoChanged(AccountType)`, `monedaChanged(Currency)`, `nombreChanged(String)`, `submitted({required String pin})`.
  - Estado: `{status: editing|submitting|done, tipo, moneda, nombre, idempotencyKey, failure: AccountFailure?, outcomeUnknown, keyUnsaved, cuenta: Account?}` + getters `bool sueldoDisponible` (no hay sueldo entre las cuentas iniciales), `bool monedaFija` (`tipo == sueldo`).
  - La pantalla hace `context.pop(cuenta)` al terminar (el inicio la recibe y emite `opened`).

- [ ] **Step 1: Copy**

```json
  "openAccountTitle": "Abrir cuenta",
  "openAccountHeadline": "¿Qué cuenta quieres abrir?",
  "openAccountTypeLabel": "Tipo de cuenta",
  "openAccountCurrencyLabel": "Moneda",
  "openAccountNameLabel": "Nombre (opcional)",
  "openAccountNameHint": "Ej. Viaje",
  "openAccountSalaryOnlyPen": "La cuenta sueldo es solo en soles.",
  "openAccountSalaryTaken": "Ya tienes una cuenta sueldo.",
  "openAccountContinue": "Continuar",
  "openAccountPinHeadline": "Confirma con tu PIN",
  "openAccountPinSubtitle": "Vas a abrir: {cuenta} en {moneda}",
  "@openAccountPinSubtitle": {"placeholders": {"cuenta": {"type": "String"}, "moneda": {"type": "String"}}},
  "openAccountCta": "Abrir cuenta",
  "openAccountRetryCta": "Reintentar",
  "openAccountErrorLimit": "Ya tienes 5 cuentas, el máximo.",
  "openAccountErrorSalary": "Ya tienes una cuenta sueldo.",
  "openAccountErrorCurrency": "La cuenta sueldo es solo en soles.",
  "openAccountErrorName": "El nombre puede tener hasta 30 caracteres.",
  "openAccountErrorKeyReused": "Esa apertura ya se pidió con otros datos. Vuelve a empezar.",
  "openAccountErrorNetwork": "No pudimos confirmar si se abrió. Reintenta: no se abrirá dos veces.",
  "openAccountErrorUnexpected": "No pudimos confirmar si se abrió. Reintenta: no se abrirá dos veces.",
```

`flutter gen-l10n`.

- [ ] **Step 2: Tests del bloc**

Create `test/presentation/account_open/open_account_bloc_test.dart` (patrón de `topup_bloc_test.dart`; `pendientesDePrueba` está en `test/presentation/transfer/fake_transfer_repositories.dart`):

```dart
void main() {
  late MemoryAccountRepository repo;
  late List<Account> iniciales;
  var n = 0;
  String clave() => 'clave-apertura-${n++}';

  setUp(() async {
    n = 0;
    repo = MemoryAccountRepository(clock: () => DateTime.utc(2026, 10, 6));
    iniciales = (await repo.cuentas()).getRight().toNullable()!;
  });

  OpenAccountBloc build({AccountRepository? r}) => OpenAccountBloc(
    AccountActions(r ?? repo),
    pending: pendientesDePrueba(),
    userId: 'u1',
    cuentas: iniciales,
    newKey: clave,
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'abrir: la clave nace al abrir y no cambia entre reintentos',
    build: build,
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
      b.add(const OpenAccountEvent.monedaChanged(Currency.usd));
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.status, OpenAccountStatus.done);
      expect(b.state.cuenta?.tipo, AccountType.corriente);
      expect(b.state.cuenta?.moneda, Currency.usd);
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'cambiar el tipo, la moneda o el nombre genera otra clave',
    build: build,
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
      b.add(const OpenAccountEvent.nombreChanged('Viaje'));
    },
    verify: (b) => expect(b.state.idempotencyKey, 'clave-apertura-2'),
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'elegir sueldo fija la moneda en soles',
    build: build,
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.monedaChanged(Currency.usd));
      b.add(const OpenAccountEvent.tipoChanged(AccountType.sueldo));
    },
    verify: (b) {
      expect(b.state.moneda, Currency.pen);
      expect(b.state.monedaFija, isTrue);
    },
  );

  test('la demo ya tiene sueldo: no está disponible', () {
    expect(build().state.sueldoDisponible, isFalse);
  });

  blocTest<OpenAccountBloc, OpenAccountState>(
    'PIN errado vuelve a editar con el fallo y la misma clave',
    build: build,
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '111111'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.status, OpenAccountStatus.editing);
      expect(b.state.failure, isA<AccountWrongPin>());
      expect(b.state.idempotencyKey, 'clave-apertura-0');
      expect(b.state.outcomeUnknown, isFalse);
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'un fallo de red sella la intención: no se puede cambiar el tipo',
    build: () => build(r: _RepoSinRed(repo)),
    act: (b) async {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      b.add(const OpenAccountEvent.tipoChanged(AccountType.corriente));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) {
      expect(b.state.outcomeUnknown, isTrue);
      expect(b.state.tipo, AccountType.ahorro);
      expect(b.state.idempotencyKey, 'clave-apertura-0');
    },
  );

  blocTest<OpenAccountBloc, OpenAccountState>(
    'dos toques en abrir mandan una sola petición',
    build: () => build(r: _RepoContador(repo)),
    act: (b) {
      b.add(const OpenAccountEvent.opened());
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
      b.add(const OpenAccountEvent.submitted(pin: '000000'));
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) => expect(_RepoContador.llamadas, 1),
  );
}
```

`_RepoSinRed` delega todo en `repo` salvo `abrir`, que devuelve `left(GlobalFailure.server(AccountFailure.network()))`. `_RepoContador` cuenta las llamadas a `abrir` en un `static int llamadas` (reiniciado en `setUp`).

- [ ] **Step 3: Ver que fallan**

Run: `cd apps/mobile && flutter test test/presentation/account_open`
Expected: FAIL de compilación.

- [ ] **Step 4: Bloc**

Estado (`open_account_state.dart`):

```dart
part of 'open_account_bloc.dart';

enum OpenAccountStatus { editing, submitting, done }

@freezed
abstract class OpenAccountState with _$OpenAccountState {
  const OpenAccountState._();

  const factory OpenAccountState({
    @Default(OpenAccountStatus.editing) OpenAccountStatus status,
    @Default(AccountType.ahorro) AccountType tipo,
    @Default(Currency.pen) Currency moneda,
    @Default('') String nombre,

    /// Identifica la INTENCIÓN (tipo + moneda + nombre). Nace al abrir,
    /// cambia solo si cambia la intención y jamás entre reintentos.
    @Default('') String idempotencyKey,
    AccountFailure? failure,

    /// Falló sin saberse si se abrió: la intención queda sellada.
    @Default(false) bool outcomeUnknown,
    @Default(false) bool keyUnsaved,

    /// ¿Hay ya una sueldo entre las cuentas del titular?
    @Default(false) bool tieneSueldo,
    Account? cuenta,
  }) = _OpenAccountState;

  bool get sueldoDisponible => !tieneSueldo;
  bool get monedaFija => tipo == AccountType.sueldo;
}
```

Bloc (patrón de `TopUpBloc`, mismo doc de garantías adaptado):

```dart
class OpenAccountBloc extends Bloc<OpenAccountEvent, OpenAccountState> {
  OpenAccountBloc(
    this._actions, {
    required PendingTransferActions pending,
    required String userId,
    required List<Account> cuentas,
    String Function()? newKey,
  }) : _pending = pending,
       _userId = userId,
       _newKey = newKey ?? IdempotencyKey.generate,
       super(OpenAccountState(
         tieneSueldo: cuentas.any((c) => c.tipo == AccountType.sueldo),
       )) {
    on<OpenAccountOpened>(_onOpened);
    on<OpenAccountTipoChanged>(_onTipo);
    on<OpenAccountMonedaChanged>(_onMoneda);
    on<OpenAccountNombreChanged>(_onNombre);
    on<OpenAccountSubmitted>(_onSubmitted);
  }

  final AccountActions _actions;
  final PendingTransferActions _pending;
  final String _userId;
  final String Function() _newKey;

  bool get _sealed =>
      state.status != OpenAccountStatus.editing || state.outcomeUnknown;

  void _onOpened(OpenAccountOpened e, Emitter<OpenAccountState> emit) {
    if (state.idempotencyKey.isNotEmpty) return;
    emit(state.copyWith(idempotencyKey: _newKey()));
  }

  void _cambiar(Emitter<OpenAccountState> emit, OpenAccountState nuevo) {
    final cambio = (nuevo.tipo, nuevo.moneda, nuevo.nombre.trim()) !=
        (state.tipo, state.moneda, state.nombre.trim());
    emit(nuevo.copyWith(
      failure: null,
      idempotencyKey: cambio ? _newKey() : state.idempotencyKey,
    ));
  }

  void _onTipo(OpenAccountTipoChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed) return;
    _cambiar(emit, state.copyWith(
      tipo: e.tipo,
      // La sueldo solo existe en soles: elegirla fija la moneda.
      moneda: e.tipo == AccountType.sueldo ? Currency.pen : state.moneda,
    ));
  }

  void _onMoneda(OpenAccountMonedaChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed || state.monedaFija) return;
    _cambiar(emit, state.copyWith(moneda: e.moneda));
  }

  void _onNombre(OpenAccountNombreChanged e, Emitter<OpenAccountState> emit) {
    if (_sealed) return;
    _cambiar(emit, state.copyWith(nombre: e.nombre));
  }

  Future<void> _onSubmitted(OpenAccountSubmitted e, Emitter<OpenAccountState> emit) async {
    if (state.status != OpenAccountStatus.editing || state.idempotencyKey.isEmpty) return;
    // Síncrono, antes del primer await: el segundo toque ya ve `submitting`.
    emit(state.copyWith(status: OpenAccountStatus.submitting, failure: null));
    final nombre = AccountLimits.normalizarNombre(state.nombre);
    final huella = PendingTransferActions.huellaApertura(
      tipo: state.tipo, moneda: state.moneda, nombre: nombre,
    );
    final pendiente = await _pending.recover(_userId, huella);
    if (pendiente != null && pendiente != state.idempotencyKey) {
      emit(state.copyWith(idempotencyKey: pendiente, outcomeUnknown: true));
    }
    final key = state.idempotencyKey;
    if (!await _pending.remember(_userId, huella, key)) {
      emit(state.copyWith(keyUnsaved: true));
    }
    final result = await _actions.abrir(
      tipo: state.tipo, moneda: state.moneda, nombre: nombre, pin: e.pin, idempotencyKey: key,
    );
    final definitivo = result.match((f) {
      final plano = _plano(f);
      return plano is AccountKeyReused || (!plano.outcomeUnknown && !state.outcomeUnknown);
    }, (_) => true);
    if (definitivo) await _pending.forget(_userId, huella);
    emit(result.match(
      (f) {
        final plano = _plano(f);
        return state.copyWith(
          status: OpenAccountStatus.editing,
          failure: plano,
          outcomeUnknown: state.outcomeUnknown || plano.outcomeUnknown,
        );
      },
      (cuenta) => state.copyWith(status: OpenAccountStatus.done, cuenta: cuenta),
    ));
  }

  AccountFailure _plano(GlobalFailure<AccountFailure> f) => switch (f) {
    ServerFailure(:final failure) => failure,
    NoConnection() || Timeout() => const AccountFailure.network(),
    _ => const AccountFailure.unexpected(),
  };
}
```

`pending_transfer_actions.dart`: añadir `huellaApertura` (con doc: "Huella de una APERTURA de cuenta: comparte almacén con envíos y recargas porque el riesgo es el mismo (no saber si se ejecutó)").

`open_account_error_text.dart`:

```dart
String openAccountErrorText(AppLocalizations l10n, AccountFailure f) => switch (f) {
  AccountWrongPin(:final intentosRestantes) => l10n.transferErrorWrongPin(intentosRestantes),
  AccountLocked(:final hasta) => l10n.transferErrorLocked(DateFormat('HH:mm').format(hasta.toLocal())),
  AccountLimitReached() => l10n.openAccountErrorLimit,
  SalaryAccountExists() => l10n.openAccountErrorSalary,
  InvalidAccountCurrency() => l10n.openAccountErrorCurrency,
  InvalidAccountName() => l10n.openAccountErrorName,
  AccountKeyReused() => l10n.openAccountErrorKeyReused,
  NetworkFailure() => l10n.openAccountErrorNetwork,
  Unauthenticated() => l10n.transferErrorUnauthenticated,
  AccountNotFound() || UnexpectedFailure() => l10n.openAccountErrorUnexpected,
};
```

- [ ] **Step 5: Pantalla y ruta**

`open_account_screen.dart`: misma estructura que `TopUpScreen` (enum `_Step { datos, pin }`, `PopScope`, `SecureScreenScope`, `PinEntryView`, el PIN se borra tras un fallo que no es de resultado desconocido, con la intención sellada solo quedan "Reintentar" o salir). Paso datos:

```dart
// Tipo: tres ChoiceChip (Ahorros / Corriente / Sueldo). Sueldo deshabilitado
// si !state.sueldoDisponible, con el texto l10n.openAccountSalaryTaken debajo.
// Moneda: dos ChoiceChip (Soles / Dólares); deshabilitados si state.monedaFija,
// con l10n.openAccountSalaryOnlyPen debajo.
// Nombre: CuyCashTextField(maxLength: AccountLimits.nombreMaxLength).
// PrimaryButton(l10n.openAccountContinue) → paso pin.
```

Paso PIN: `PinEntryView(headline: l10n.openAccountPinHeadline, subtitle: l10n.openAccountPinSubtitle(accountTypeLabel(l10n, state.tipo), nombreMoneda), ...)` y `PrimaryButton(state.outcomeUnknown ? openAccountRetryCta : openAccountCta)` que despacha `submitted(pin: _pin)`. Con `status == done`: `WidgetsBinding.instance.addPostFrameCallback((_) => context.pop(state.cuenta))` desde un `BlocListener` (`listenWhen: (a, b) => b.status == OpenAccountStatus.done && a.status != b.status`).

`router.dart`, junto a `recargar`:

```dart
      GoRoute(
        path: AppRoutes.abrirCuenta,
        // Las cuentas actuales viajan como `extra` desde el inicio: sin ellas
        // (deep link) no se sabe si ya hay sueldo ni cuántas hay.
        redirect: (context, state) =>
            state.extra is List<Account> ? null : AppRoutes.home,
        builder: (context, state) => BlocProvider(
          create: (_) => OpenAccountBloc(
            AccountModule.create(deps),
            pending: TransferModule.pending(deps),
            userId: switch (authBloc.state) {
              AuthAuthenticated(:final session) => session.userId,
              AuthUnauthenticated() => '',
            },
            cuentas: state.extra as List<Account>,
          )..add(const OpenAccountEvent.opened()),
          child: const OpenAccountScreen(),
        ),
      ),
```

- [ ] **Step 6: Test del flujo completo**

Create `test/presentation/account_open/open_account_flow_test.dart` con el `pumpApp` de `send_flow_test.dart` (grafo `mock` real):

```dart
  testWidgets('abrir una cuenta en dólares desde el carrusel', (tester) async {
    await pumpApp(tester);
    // Deslizar hasta la última página (3 cuentas + abrir).
    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Abrir otra cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué cuenta quieres abrir?'), findsOneWidget);
    // Sueldo deshabilitada: la demo ya tiene una.
    expect(find.text('Ya tienes una cuenta sueldo.'), findsOneWidget);
    await tester.tap(find.text('Corriente'));
    await tester.tap(find.text('Dólares'));
    await tester.enterText(find.byType(TextField), 'Viaje');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    for (final d in '000000'.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.tap(find.widgetWithText(ElevatedButton, 'Abrir cuenta'));
    await tester.pumpAndSettle();

    // De vuelta en el inicio, con la cuenta nueva a la vista.
    expect(find.text('Viaje'), findsOneWidget);
    expect(find.text(r'US$ 0.00'), findsOneWidget);
  });
```

(Ajusta los finders a cómo `CuyCashTheme` renderiza `PrimaryButton`: mira `send_flow_test.dart`, que usa `find.widgetWithText(ElevatedButton, ...)`.)

- [ ] **Step 7: Probar y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test`
Expected: PASS.

```bash
git add -A apps/mobile
git commit -m "feat(app): abrir otra cuenta en dos pasos (tipo, moneda y nombre; luego PIN)"
```

---

## Task 8: Recarga en la moneda de la cuenta visible y cierre de la entrega

**Files:**
- Modify: `apps/mobile/lib/presentation/topup/topup_screen.dart` (montos rápidos y resumen con la moneda; ya migrado en Task 2, aquí se verifica en dólares)
- Modify: `apps/mobile/test/presentation/topup/topup_flow_test.dart`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Test de recarga en dólares**

En `topup_flow_test.dart` (grafo `mock`), añadir: deslizar a la tercera tarjeta (US$ 120.00), "Recargar", tocar el chip `US$ 20.00`, "Continuar", PIN `000000`, confirmar → constancia con `US$ 20.00`; volver al inicio → la tarjeta visible muestra `US$ 140.00` y la primera sigue en `S/ 1,250.40`.

- [ ] **Step 2: Ver que pasa (o arreglar)**

Run: `cd apps/mobile && flutter test test/presentation/topup`
Expected: PASS. Si el resumen o los chips salen en soles, falta pasar `widget.cuenta.moneda` en algún `Money(...)`/`formatMoney` de `topup_screen.dart`.

- [ ] **Step 3: CLAUDE.md**

En "Lo implementado hoy", cambiar "una cuenta de ahorro en soles por titular" por "hasta 5 cuentas por titular (ahorros, corriente o sueldo; soles o dólares; sueldo única y en soles), con nombre opcional; se abren desde el carrusel del inicio con PIN". En "Sigue sin existir", quitar "cuentas en USD ni más de una cuenta por titular" y añadir "conversión entre monedas (un envío solo va entre cuentas de la misma moneda)". En la lista de rutas del perfil/backend, añadir `POST /v1/accounts` y `PATCH /v1/accounts/{id}/nombre`. En "Concurrencia sin probar", añadir el test `postgres` de aperturas simultáneas de sueldo.

- [ ] **Step 4: Verificación completa y commit**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter analyze && flutter test && (cd services/api && .venv/bin/python -m pytest -q)`
Expected: `No issues found!`, Flutter en verde, pytest en verde.

```bash
git add -A apps/mobile CLAUDE.md
git commit -m "feat(app): recarga en la moneda de la cuenta; CLAUDE.md al día con la multicuenta"
```
