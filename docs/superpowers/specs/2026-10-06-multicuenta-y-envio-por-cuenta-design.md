# Multicuenta y envío por cuenta — diseño

Fecha: 2026-10-06 · Estado: propuesto

## Por qué

El envío de dinero identifica al destinatario por DNI y le acredita "su" cuenta,
porque hoy cada titular tiene exactamente una. Se quiere:

1. Que un titular tenga varias cuentas, de distinto **tipo** (ahorros, corriente,
   sueldo), **moneda** (S/ o US$) y con un **nombre** propio.
2. Que al enviar dinero, tras escribir un DNI, aparezca **una tarjeta por cada
   cuenta** del destinatario; tocar una lleva directo al monto (sin botón
   "Continuar"), y la pantalla de monto muestra la cuenta elegida.
3. Que un frecuente guarde **la cuenta**, no solo el DNI, y tocarlo lleve
   directo al monto sin volver a consultar.

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Cómo se obtiene otra cuenta | El titular la abre desde la app (`POST /v1/accounts`). |
| Inicio con varias cuentas | Carrusel de tarjetas de saldo; lo visible es la cuenta activa para movimientos, "Enviar" y "Recargar". |
| Tipos | `ahorro`, `corriente`, `sueldo`. Fuera: CTS, plazo fijo. |
| Monedas | `PEN`, `USD`. |
| Reglas | Tope 5 cuentas por titular (cuentan las cerradas). Una sola `sueldo` por titular y solo en `PEN`. |
| Nombre | Opcional, ≤ 30 caracteres, editable, visible solo para el titular. Sin nombre se muestra el tipo. |
| Envío entre monedas | **No se permite.** Sin conversión ni tipo de cambio (proyecto aparte). |
| Envío entre cuentas propias | Permitido por el mismo flujo: escribir el propio DNI lista las otras cuentas. Solo se rechaza origen = destino. |
| Moneda en la app | `Money` lleva su `Currency`; operar monedas distintas es un error de programación. |

## Entregas

Tres entregas en una rama `feat/multicuenta-y-envio-por-cuenta`. Cada una deja
la app y la suite en verde.

1. **Backend** — modelo, rutas y reglas.
2. **App: cuentas** — `Money` con moneda, carrusel, abrir cuenta, renombrar.
3. **App: envío** — destinatario por cuenta, frecuentes por cuenta, monto con la
   cuenta destino.

---

## 1. Backend

### Modelo

**`accounts`**
- `CHECK tipo IN ('ahorro','corriente','sueldo','sistema')`.
- Nueva columna `nombre VARCHAR(30) NULL`.
- Índice único parcial `ux_accounts_un_sueldo (user_id) WHERE tipo = 'sueldo'`:
  lo que impide dos cuentas sueldo ante aperturas concurrentes.
- `CHECK (tipo <> 'sueldo' OR moneda = 'PEN')`.
- El tope de 5 lo aplica el servicio (cuenta filas del titular bajo
  `SELECT … FOR UPDATE` sobre la fila del `User`, para serializar aperturas del
  mismo titular).

**Cajas por moneda.** `NUMERO_SISTEMA` pasa a un mapa
`{"PEN": "19100000000000", "USD": "19100000000001"}`; ambos reservados en
`generar_numero`. `cuenta_de_sistema(session, moneda)` crea o devuelve la caja
de esa moneda con el mismo patrón de SAVEPOINT de hoy.

**`beneficiaries`**
- Nueva columna `cuenta_destino_id FK accounts.id NOT NULL`.
- `UNIQUE (user_id, cuenta_destino_id)` reemplaza a `UNIQUE (user_id, beneficiario_dni)`.
- `beneficiario_dni` se conserva (índice) para pintar y para resolver si la
  cuenta deja de estar activa.

Cambian CHECK y UNIQUE: se recrea el esquema (`scripts/reset_schema.py`), se
regenera `schema.sql` y se actualiza `docs/modelo-datos.md`.

### Contrato

**`POST /v1/accounts`** (nueva)
```json
{ "tipo": "ahorro|corriente|sueldo", "moneda": "PEN|USD",
  "nombre": "Viaje" | null, "pin": "000000", "idempotency_key": "…" }
```
→ `201` con la cuenta (forma de `GET /v1/accounts`). Mismo `idempotency_key`
del mismo titular → `200` con la cuenta ya creada (se guarda la clave en la
fila de la cuenta: columna `idempotency_key VARCHAR(64) NULL UNIQUE`).
PIN al final, como en `/transfers`. Errores: `ACCOUNT_LIMIT_REACHED`,
`SALARY_ACCOUNT_EXISTS`, `INVALID_ACCOUNT_CURRENCY`, `INVALID_ACCOUNT_NAME`,
los de PIN/bloqueo existentes.

**`PATCH /v1/accounts/{id}/nombre`** (nueva) — `{ "nombre": str | null }`.
Solo cuentas propias (ajena o inexistente → `ACCOUNT_NOT_FOUND`). Sin PIN: no
mueve dinero. Nombre se recorta; vacío equivale a `null`; > 30 →
`INVALID_ACCOUNT_NAME`.

**`GET /v1/accounts`** — agrega `nombre` a cada cuenta.

**`GET /v1/directory/resolve?dni=`** — cambia la forma:
```json
{ "dni": "71234567", "nombre_enmascarado": "L*** A*** Q***",
  "cuentas": [ { "cuenta_id": "…", "tipo": "ahorro", "moneda": "PEN",
                 "numero_masked": "••••1234", "nombre": null } ] }
```
- Solo cuentas `activa` y no `sistema`, ordenadas por `created_at, id`.
- `nombre` solo se llena si el DNI es del propio solicitante; para un tercero
  siempre `null`.
- Sin cuentas activas → `RECIPIENT_NOT_FOUND` (igual que un DNI inexistente).
- El DNI propio ya **no** da `SELF_TRANSFER`. Sigue descontando presupuesto de
  consultas.
- `cuenta_id` es el `id` (UUID) de la cuenta: no revela el número completo ni
  el DNI.

**`POST /v1/transfers`** — `destinatario_dni` se reemplaza por
`cuenta_destino_id`. Orden de validación: cuenta origen propia → reintento
idempotente → cuenta destino existe, activa, no sistema (si no,
`RECIPIENT_NOT_FOUND`) → `SAME_ACCOUNT` → `CURRENCY_MISMATCH` → monto → PIN →
`ledger.post`. Descuenta presupuesto de consultas como hoy. `SELF_TRANSFER` se
elimina del código de errores.

**`POST /v1/topups`** — sin cambio de contrato; contraparte =
`cuenta_de_sistema(session, cuenta.moneda)`.

**`GET /v1/beneficiaries`**
```json
{ "beneficiarios": [ { "id": "…", "dni": "…", "apodo": "Mamá",
  "nombre_enmascarado": "…" | null,
  "cuenta": { "cuenta_id": "…", "tipo": "ahorro", "moneda": "PEN",
              "numero_masked": "••••1234", "nombre": null } | null } ] }
```
`cuenta: null` si la cuenta guardada ya no está activa.

**`POST /v1/beneficiaries`** — `{ "cuenta_destino_id": "…", "apodo": "…" }`.
Valida que la cuenta exista, esté activa y no sea de sistema (si no,
`RECIPIENT_NOT_FOUND`). Puede ser una cuenta propia: guardar "Mi sueldo" es
válido. Comparte presupuesto de consultas como hoy.

**Montos.** Mismo rango (1–200 000 céntimos) por moneda; el mensaje usa el
símbolo de la moneda de la cuenta origen.

### Errores nuevos (`ErrorCode`)
`ACCOUNT_LIMIT_REACHED`, `SALARY_ACCOUNT_EXISTS`, `INVALID_ACCOUNT_CURRENCY`,
`INVALID_ACCOUNT_NAME`, `CURRENCY_MISMATCH`, `SAME_ACCOUNT`. Se elimina
`SELF_TRANSFER`.

El `assert` de monedas de `ledger.py` se queda como defensa interna; el router
valida antes.

---

## 2. App: dominio

### `core_kernel`
- `enum Currency { pen, usd }` con `code` y `symbol` (`S/`, `US$`);
  `Currency.fromCode(String) → Currency?`.
- `Money(int centimos, Currency currency)`. `+`, `-`, `compareTo` y `==` entre
  monedas distintas: `+`/`-`/`compareTo` lanzan `StateError` (bug, no caso de
  negocio); `==` devuelve `false`.
- `Money.parse(String, Currency)`; `Money.zero(Currency)`.
- `formatMoney(Money)` reemplaza a `formatSoles` en todas sus llamadas.

### `feature/account`
- `Account`: `+ tipo: AccountType {ahorro, corriente, sueldo}`, `moneda: Currency`,
  `nombre: String?`. Saldos pasan a `Money` con la moneda de la cuenta.
- `AccountRepository`: `+ abrir({tipo, moneda, nombre, pin, idempotencyKey})`,
  `+ renombrar(cuentaId, nombre)`.
- `AccountFailure`: `+ limitReached`, `salaryAccountExists`, `invalidCurrency`,
  `invalidName`.
- `MemoryAccountRepository` aplica las mismas reglas; contrato compartido con
  HTTP.

### `feature/transfer`
- `RecipientDirectory { dni, nombreEnmascarado, cuentas: List<RecipientAccount> }`.
- `RecipientAccount { cuentaId, tipo, moneda, numeroMasked, nombre? }`.
- `resolverDestinatario(dni) → RecipientDirectory`.
- `enviar({cuentaOrigenId, cuentaDestinoId, monto, motivo, pin, idempotencyKey})`.
- `TransferFailure`: `+ currencyMismatch`, `sameAccount`; `− selfTransfer`.
- Mock: el DNI propio `70123456` tiene ahorros S/, sueldo S/ y ahorros US$; un
  destinatario conocido tiene dos cuentas S/ y una US$.

### `feature/beneficiary`
- `Beneficiary { id, dni, apodo, nombreEnmascarado?, cuenta: RecipientAccount? }`.
- `guardar({cuentaDestinoId, apodo})`.

---

## 3. App: pantallas

### Inicio
- `PageView` de `BalanceCard`, una por cuenta: etiqueta (nombre o tipo),
  moneda, `••••NNNN`, saldo. Última página: "Abrir otra cuenta" (oculta con 5
  cuentas). Indicador de puntos.
- `AccountBloc`: `cuentas` + `seleccionada` (índice). `accountSelected` recarga
  movimientos con el contador de generación existente. Tras abrir una cuenta,
  el carrusel queda en la nueva.
- "Enviar" y "Recargar" reciben la cuenta visible. Tocar la etiqueta abre la
  hoja "Cambiar nombre" (campo ≤ 30, "Guardar", "Quitar nombre").

### Abrir cuenta (`presentation/account_open/`, ruta `/cuentas/abrir`)
1. Tipo (ahorros / corriente / sueldo), moneda, nombre opcional. Sueldo fija
   S/; sueldo deshabilitado con motivo si ya existe.
2. PIN (`PinEntryView`). Éxito → inicio con la cuenta nueva visible.
Clave de idempotencia guardada como pendiente igual que el envío.

### Enviar — destinatario
- Sin botón "Continuar". Al completar 8 dígitos: cabecera con nombre
  enmascarado y una **tarjeta por cuenta** ("Ahorros · S/ · ••••1234"; para
  cuentas propias, su nombre).
- Tocar una tarjeta → `recipientSelected` → monto.
- Cuentas de otra moneda que la de origen: deshabilitadas con "Solo recibe
  US$". La cuenta de origen no se lista. Sin ninguna elegible: aviso.
- Frecuente con `cuenta` de la misma moneda → directo al monto, sin consultar.
  Otra moneda → aviso, se queda. `cuenta == null` → rellena DNI y busca.

### Enviar — monto, confirmación, constancia
- Monto: bajo el nombre, la cuenta destino ("Ahorros · ••••1234"); campo con
  el símbolo de la moneda de origen.
- Confirmación y constancia: origen y destino con etiqueta y `••••NNNN`.
- "Guardar como frecuente" guarda la cuenta destino.

### Recarga
Recibe la cuenta visible; caja y símbolo según su moneda.

### Copy
Todo en ARB es-PE: "Ahorros", "Corriente", "Sueldo", "S/", "US$" y los textos
de error nuevos.

---

## 4. Errores, idempotencia y pruebas

### Idempotencia en el envío
La clave se regenera al cambiar cuenta destino o cuenta origen; se conserva
al volver al monto tras un error. Un reintento nunca puede apuntar a otra
cuenta.

### Pruebas backend (pytest, SQLite)
- Abrir: tope 5, sueldo única, sueldo solo PEN, nombre inválido, PIN errado,
  idempotencia.
- Renombrar: propia sí, ajena `ACCOUNT_NOT_FOUND`, vacío → `null`.
- Resolve: varias cuentas, propio DNI con nombres, ajeno sin nombres, excluye
  sistema e inactivas, sin activas → 404.
- Transfers: por `cuenta_destino_id`, `CURRENCY_MISMATCH`, `SAME_ACCOUNT`,
  envío entre cuentas propias, destino inactivo → 404, reintento idempotente.
- Topup USD contra su caja USD; libro cuadra por moneda.
- Beneficiaries: dos cuentas de la misma persona; `cuenta: null` al
  desactivarse.
- `postgres`: dos aperturas simultáneas de sueldo → una sola. **Sin ejecutar
  contra Postgres real**, como los otros dos.

### Pruebas app
- `Money`: operar monedas distintas lanza `StateError`; `formatMoney` por moneda.
- Contratos Memory/HTTP: `abrir`, `renombrar`, `resolverDestinatario`,
  `enviar`, beneficiarios.
- `AccountBloc`: carrusel, respuestas tardías tras cambiar de cuenta.
- `TransferBloc`: selección, regeneración de clave.
- Widgets: tarjeta → monto; frecuente → monto; otra moneda deshabilitada; monto
  muestra la cuenta; abrir cuenta en dos pasos.

Cierre de cada entrega: `flutter analyze` sin issues, `flutter test` y `pytest`
en verde.

---

## 5. Limpieza y documentación

- El trabajo sin commitear de una iteración anterior (rediseño parcial del
  envío + `dart format` sobre ~100 archivos ajenos) se guarda en un `git stash`
  y se descarta del árbol. Esta spec lo reemplaza.
- CLAUDE.md: quitar "USD y más de una cuenta" de lo que no existe; documentar
  rutas nuevas, reglas de cuentas y el test `postgres` nuevo sin ejecutar.
- `docs/modelo-datos.md` y `schema.sql` (vía `scripts/dump_schema.py`).

## Fuera de alcance
Conversión de moneda, CTS, plazo fijo, cierre de cuentas por el titular,
transferencias interbancarias, límites distintos por moneda o tipo.
