# CuyCash — Cuentas reales, envío de dinero y recarga

- **Fecha:** 2026-10-05
- **Épicas:** 2 (cuentas y libro mayor, HU05/HU17/HU18) y parte de la 3 (transferencia entre personas, HU06).
- **Base:** identidad del Sprint 1 completa (DNI+PIN, OTP, KYC, bloqueo). Las tablas `accounts`,
  `transactions` y `ledger_entries` ya están modeladas en `services/auth/app/db/models.py`, pero
  **ninguna ruta las expone**: hoy solo existen los routers `auth`, `kyc` y `otp`.
- **Flavor foco:** `local` y `production` (contra el backend). `mock` debe seguir arrancando entero
  con `Memory*`.

## Objetivo

Que el dinero de la pantalla sea dinero del libro mayor.

- **Home real:** se borra `demo_wallet.dart` y con él el sello "datos de demostración". Saldo,
  movimientos y detalle salen del backend.
- **Enviar:** a otra persona de CuyCash, identificada por **DNI**, confirmando con PIN.
- **Recargar:** cash-in a la cuenta propia, contra una cuenta de sistema, para que la demo tenga
  saldo sin sembrar datos.
- **Frecuentes:** guardar destinatarios y ofrecerlos como atajo.
- **Constancia:** ficha del movimiento y compartirla.

**Fuera de alcance (no inventar código de esto):** transferencia interbancaria y CCI, cobro por QR,
préstamos, antifraude, pantalla de "tipos de transferencia", cuentas en USD, segunda cuenta por
titular.

## Decisiones

1. **El destinatario se identifica por DNI.** Es el único dato que hoy identifica sin ambigüedad:
   no existe el número de celular en el modelo, y el `alias` se deriva del primer nombre
   (`_alias()` en `routers/auth.py`) sin índice único, así que dos homónimos colisionan. Añadir
   celular y alias único es una mejora de búsqueda posterior que no toca el motor.
2. **Resolver un DNI devuelve el nombre enmascarado** (`J*** M*** R***`) y está limitado por
   sesión. Devolver el nombre completo sin tope convierte la app en un directorio de la población
   peruana.
3. **Una cuenta de sistema sostiene la partida doble de la recarga.** Una recarga crea dinero: sin
   contraparte, el asiento no cuadra y la épica 6 (conciliación) queda sin suelo. Esa cuenta es la
   única que puede tener saldo negativo, y su saldo es exactamente lo inyectado en la demo.
4. **Un solo módulo escribe en el libro: `app/services/ledger.py`.** Transferencia, recarga y lo
   que venga en sprints posteriores pasan por ahí. Ninguna ruta inserta `ledger_entries` por su
   cuenta.
5. **La idempotencia la arbitra la base**, vía el `UNIQUE` sobre `transactions.idempotency_key`,
   capturando `IntegrityError`. Comprobar antes con un `SELECT` deja una ventana entre consulta e
   inserción por la que se cuelan dos cobros.
6. **La clave de idempotencia se genera al abrir la pantalla de confirmación**, no al pulsar
   confirmar, y se reutiliza en cada reintento. Generarla al pulsar convierte un doble toque en dos
   cobros.
7. **El dinero es un `int` de céntimos de extremo a extremo**, envuelto en un `Money` de
   `core_kernel`. Ni un `double` en el dominio ni en la red.
8. **El PIN autoriza cada movimiento de dinero**, y sus fallos alimentan el `lockout` existente:
   cinco PIN errados al transferir bloquean igual que al entrar.
9. **Routers nuevos dentro del servicio existente**, que se renombra de `services/auth` a
   `services/api`. Un segundo servicio serían dos despliegues y validación de token duplicada sobre
   una base compartida, que es el antipatrón que luego habría que defender.
10. **El esquema se recrea, sin Alembic.** El proyecto no tiene datos reales todavía. Montar
    migraciones versionadas para un esquema que nadie necesita conservar es coste sin beneficio;
    entra en el sprint que lo necesite.
11. **Tres features verticales en la app** (`account`, `transfer`, `beneficiary`), no una feature
    `banking`. Tres interfaces pequeñas en vez de un repositorio que mezcla consultar saldo con
    mover dinero.

## Reglas duras (heredadas)

Errores como valores (`Either` + failures sellados); todo contrato nace con su `Memory*` funcional;
estados sealed + `switch` exhaustivo (sin `when`/`maybeWhen`/`!`); el Bloc consume `application`,
nunca el repo; DI por constructor; tokens del `design_system` (cero hex sueltos); copy es-PE en ARB;
un widget público por archivo; generados se commitean.

---

# Backend

## Renombrado previo

`services/auth` → `services/api`. Ajustar `render.yaml`, el `Dockerfile`/`start` si los hay, los
imports (`app.*` no cambia) y las referencias en `CLAUDE.md`, `README.md` y los ADR. Se hace primero
y en un commit propio, para que el diff del motor no quede sepultado bajo movimientos de archivos.

## Cambios de modelo

`app/db/models.py`:

- `Account.user_id` pasa a **nullable** (la cuenta de sistema no tiene titular).
- `Account.tipo` admite `'sistema'`: `CheckConstraint("tipo IN ('ahorro','corriente','sistema')")`.
- El tope de saldo se condiciona:
  `CheckConstraint("tipo = 'sistema' OR saldo_disponible >= 0")`.
- `Transaction.tipo` admite `'recarga'`.
- Tabla nueva `beneficiaries`: `id`, `user_id` (FK), `beneficiario_dni`, `apodo` (≤ 40),
  `created_at`; único sobre `(user_id, beneficiario_dni)`.
- Tabla nueva `transfers` (la diseñada en `docs/modelo-datos.md`, recortada al alcance de hoy):
  `id`, `transaction_id` (FK), `cuenta_origen` (FK), `cuenta_destino` (FK), `monto`, `motivo`,
  `estado`. `destino_externo` y `canal` se añaden en el sprint 3; no se crean ahora.

**Las migraciones son un problema que hay que resolver aquí.** El servicio crea el esquema con
`Base.metadata.create_all` (`app/main.py:20`), que crea tablas que faltan pero **no altera las que
ya existen**. `beneficiaries` y `transfers` aparecerían solas; el `user_id` nullable y los tres
`CheckConstraint` modificados de `accounts` y `transactions`, no — el despliegue de Render seguiría
con las restricciones viejas y la recarga fallaría en producción pero pasaría en los tests locales,
que arrancan con la base vacía.

**Decisión: se recrea la base.** No hay datos reales que conservar —ni en local ni en Neon—, así
que se borra el esquema y `create_all` lo levanta entero con las restricciones nuevas. Introducir
Alembic hoy costaría una revisión inicial que refleje un esquema que nadie necesita conservar.

Esto es una **pérdida de datos deliberada**, y hay que ejecutarla a conciencia:

- Un script `scripts/reset_schema.py` que haga `drop_all` + `create_all`, y que **se niegue a correr
  si `ENV == 'production'` sin una variable `ALLOW_DESTRUCTIVE_RESET=1`**. Sin ese cerrojo, el día
  que haya datos reales alguien lo ejecutará por costumbre.
- Las cuentas registradas para probar el Sprint 1 desaparecen. Hay que volver a registrarse en la
  app tras el reset.

**Cuándo deja de valer esto:** en el momento en que una cuenta de la exposición, una demo grabada o
el sprint 4 (préstamos, que escribe contratos) dependa de datos previos. Ahí entra Alembic, y es
trabajo de ese sprint, no de este. Queda anotado para no redescubrirlo.

## Piezas transversales

**`app/core/deps.py` — `current_user`.** Dependencia FastAPI que lee `Authorization: Bearer`, llama a
`sessions.resolve` y devuelve el `User`, o lanza `UNAUTHENTICATED` (401). Todos los endpoints nuevos
cuelgan de ella, y `routers/auth.py:204` se reescribe para usarla en lugar de validar a mano.

**`app/services/accounts.py` — apertura y numeración.**

- `generar_numero()`: `'191'` + 11 dígitos aleatorios, reintentando ante colisión con el índice
  único. No se deriva del DNI: un número de cuenta no debe filtrar el documento del titular.
- `abrir_cuenta(session, user_id)`: crea `ahorro / PEN / activa / saldo 0`.
- `cuenta_de_sistema(session)`: devuelve la cuenta `tipo='sistema'`, creándola si no existe.
- `POST /v1/auth/register` llama a `abrir_cuenta` **en el mismo COMMIT**. Si la apertura falla, no se
  crea el usuario: una identidad sin cuenta es un estado que nadie sabría reparar después.

## `app/services/ledger.py` — el motor

Una función pública:

```python
async def post(
    session: AsyncSession,
    *,
    tipo: str,                     # 'transferencia' | 'recarga' | ...
    asientos: list[Asiento],       # (account_id, direccion, monto)
    idempotency_key: str,
    referencia: str | None = None,
) -> Transaction:
```

Dentro de una transacción de base de datos:

1. Valida que la suma de débitos iguale la de créditos. Si no, `AssertionError` — es un error de
   programación, no de negocio.
2. Bloquea las cuentas implicadas con `SELECT ... FOR UPDATE` **ordenadas por `id`**. El orden fijo
   es lo que evita el abrazo mortal entre dos envíos cruzados simultáneos.
3. Valida fondos en cada cuenta debitada, salvo la de sistema. Si falta, `INSUFFICIENT_FUNDS`.
4. Inserta la `Transaction`. Si choca el `UNIQUE` de `idempotency_key`, hace rollback, recupera la
   transacción existente y la devuelve sin cobrar de nuevo.
5. Inserta los `LedgerEntry` con `saldo_posterior` calculado, y actualiza `saldo_disponible` y
   `saldo_contable`.

El SLA de 200 ms se sostiene porque el saldo es columna (no suma del historial) y porque la
operación entera es un `COMMIT` con las filas ya bloqueadas.

## Contrato HTTP

Prefijo `/v1`. Todos exigen `current_user`. **Todos los montos son enteros en céntimos.**

### `GET /v1/accounts`

```json
{"cuentas": [{"id": "...", "numero": "19100000004521", "tipo": "ahorro",
              "moneda": "PEN", "estado": "activa",
              "saldo_disponible": 425080, "saldo_contable": 425080}]}
```

### `GET /v1/accounts/{id}/movements?cursor=&limit=20`

Paginación por cursor (`created_at` + `id` del último asiento), no por `offset`: con `offset`, un
movimiento nuevo durante el scroll duplica o salta filas.

```json
{"movimientos": [{"transaction_id": "...", "tipo": "transferencia",
                  "direccion": "debito", "monto": 25000,
                  "contraparte": "Jenny Marisol Ruiz", "motivo": "Cena compartida",
                  "saldo_posterior": 400080, "created_at": "..."}],
 "next_cursor": "..."}
```

El nombre de la contraparte **sí va completo** aquí: ya hubo una operación entre ambos, el dato
dejó de ser privado entre ellos.

### `GET /v1/movements/{transaction_id}`

Ficha completa para la constancia: monto, tipo, estado, contraparte, número de cuenta destino
enmascarado, motivo, referencia, fecha. 404 si la transacción no tiene ningún asiento sobre una
cuenta del solicitante.

### `GET /v1/directory/resolve?dni=`

```json
{"dni": "71234567", "nombre_enmascarado": "J*** M*** R***",
 "cuenta_destino_numero_masked": "••••7743"}
```

- `RECIPIENT_NOT_FOUND` (404) si no existe o no tiene cuenta activa.
- `SELF_TRANSFER` (400) si el DNI es el del solicitante.
- `RATE_LIMITED` (429) pasadas 20 consultas en 10 minutos por sesión.

### `POST /v1/transfers`

```json
{"cuenta_origen_id": "...", "destinatario_dni": "71234567",
 "monto_centimos": 25000, "motivo": "Cena compartida",
 "pin": "······", "idempotency_key": "uuid-v4"}
```

Orden de validación: cuenta propia y activa → destinatario existe y no es uno mismo → monto en rango
(`1` … `2_000_00` céntimos) → **PIN** → `ledger.post`. El PIN se verifica el último, para no gastar
intentos de bloqueo en peticiones que iban a fallar igual.

Un PIN errado devuelve `INVALID_CREDENTIALS` con `intentos_restantes`, y registra el fallo en
`lockout` bajo el mismo sujeto `dni` que usa el login. Al quinto, `IDENTIFIER_LOCKED` con
`locked_until`.

Responde `201` con la transacción creada, o `200` con la original si la `idempotency_key` se repite.

### `POST /v1/topups`

```json
{"cuenta_id": "...", "monto_centimos": 10000, "pin": "······",
 "idempotency_key": "uuid-v4"}
```

Débito a la cuenta de sistema, crédito a la del titular. Mismo rango y mismas reglas de PIN. Nunca
puede fallar por fondos.

### `/v1/beneficiaries`

- `GET` → `{"beneficiarios": [{"id", "dni", "apodo", "nombre_enmascarado"}]}`
- `POST` `{"dni", "apodo"}` → 201. Repetir un DNI ya guardado actualiza el apodo.
- `DELETE /v1/beneficiaries/{id}` → 204.

### Códigos de error nuevos

`INSUFFICIENT_FUNDS`, `RECIPIENT_NOT_FOUND`, `SELF_TRANSFER`, `ACCOUNT_BLOCKED`,
`AMOUNT_OUT_OF_RANGE`, `RATE_LIMITED`. Se añaden a `ErrorCode` en `app/core/errors.py`.

---

# App

## `core_kernel` — `Money`

```dart
final class Money implements Comparable<Money> {
  const Money.fromCentimos(this.centimos);
  static Money? parse(String texto);   // '250.00' | '250' | '250,00'
  final int centimos;
  Money operator +(Money other); Money operator -(Money other);
  bool operator <(Money other); // ...
}
```

`formatSoles` (en `apps/mobile/lib/core/format/soles.dart`) pasa a recibir `Money` en lugar de
`double`. El formato en sí no cambia: `S/ 1,250.40`, símbolo delante, separadores peruanos.

Un `double` que representa S/ 0.10 no vale 0.10, y tres sumas después el saldo de la pantalla ya no
es el del libro mayor. Como es un tipo propio, el compilador impide pasar un número crudo donde va
dinero.

## `Dio` autenticado compartido

En `core/injection`: un `Dio` con un interceptor que adjunta `Authorization: Bearer` leyendo la
sesión vigente y que, ante un 401, revoca la sesión local y navega al login. Las tres features
reciben ese `Dio` ya configurado; ninguna sabe qué es un token.
`HttpAuthRepository` deja de adjuntar la cabecera a mano.

## `feature/account`

**domain**
- `Account { id, numero, tipo, moneda, estado, Money saldoDisponible, Money saldoContable }` con
  `numeroMasked` derivado.
- `Movement { transactionId, MovementKind tipo, MovementDirection direccion, Money monto,
  String? contraparte, String? motivo, DateTime fecha }`.
- `MovementDetail` — `Movement` más estado, cuenta destino enmascarada y referencia.
- `MovementPage { List<Movement> items, String? nextCursor }`.
- `AccountRepository`: `cuentas()`, `movimientos(cuentaId, {cursor})`, `movimiento(transactionId)`.
- `AccountFailure`: `accountNotFound`, `unauthenticated`, `network`, `unexpected`.

**application** — `AccountActions` (delegación fina sobre el repo).

**infrastructure** — `HttpAccountRepository`, `MemoryAccountRepository` (una cuenta con saldo y un
puñado de movimientos verosímiles, que es lo que hoy hace `demo_wallet.dart`).

## `feature/transfer`

**domain**
- `Recipient { dni, nombreEnmascarado, cuentaDestinoMasked }`.
- `TransferReceipt { transactionId, Money monto, Recipient destinatario, String? motivo,
  DateTime fecha }`.
- `TransferRepository`:
  - `resolverDestinatario(String dni)`
  - `enviar({cuentaOrigenId, destinatarioDni, Money monto, String? motivo, String pin,
    String idempotencyKey})`
  - `recargar({cuentaId, Money monto, String pin, String idempotencyKey})`
- `TransferFailure` sellado, un caso por reacción distinta del usuario: `insufficientFunds`,
  `recipientNotFound`, `selfTransfer`, `wrongPin(int intentosRestantes)`, `locked(DateTime hasta)`,
  `rateLimited`, `amountOutOfRange`, `accountBlocked`, `network`, `unexpected`.

Enviar y recargar comparten el motor pero no el contrato: recargar no tiene destinatario y no puede
fallar por fondos. Fundirlos daría un método con la mitad de los parámetros nulos.

**infrastructure** — `HttpTransferRepository`, `MemoryTransferRepository` (PIN válido `000000`,
coherente con el resto del flavor `mock`; destinatarios inventados; respeta la idempotencia en
memoria).

## `feature/beneficiary`

`Beneficiary { id, dni, apodo, nombreEnmascarado }`, `BeneficiaryRepository` con `listar()`,
`guardar(dni, apodo)`, `eliminar(id)`, `BeneficiaryFailure`, y su `Memory*`.

## Inyección

`core/injection/modules/`: `account_module.dart`, `transfer_module.dart`, `beneficiary_module.dart`.
`envs/mock_dependencies.dart` enchufa los `Memory*`; `envs/shared/shared_backend_dependencies.dart`
los HTTP sobre el `Dio` autenticado.

## Presentación

**`HomeAction`.** `QuickActionsRow` notifica hoy con `onAction(String label)` — el copy traducido
como identificador. Pasa a `enum HomeAction { send, charge, topUp, withdraw }`: hoy, renombrar un
texto en el ARB rompería la navegación en silencio.

**Home — `AccountBloc`**
`AccountLoading | AccountReady(Account, MovementPage, bool cargandoMas) | AccountError(AccountFailure)`.
Pull-to-refresh y paginación al llegar al final del scroll. Se borra `demo_wallet.dart` y el sello
de demostración. `balance_card`, `movements_card` y `home_header` se alimentan del bloc.

**Envío — `TransferBloc`**, tres pantallas en pila sobre el shell, alcanzadas desde
`HomeAction.send`:

1. `recipient_screen` — campo de DNI (8 dígitos, teclado numérico) y fila de frecuentes. Al
   completar los 8 dígitos resuelve contra el backend.
   `RecipientIdle | RecipientSearching | RecipientFound(Recipient) | RecipientNotFound | RecipientRateLimited`.
2. `amount_screen` — monto con `Money.parse`, disponible real, montos sugeridos (S/ 20, 50, 100,
   200), motivo (≤ 40 car.) e interruptor "guardar como frecuente". Valida contra el saldo antes de
   dejar continuar.
3. `confirm_screen` — resumen. **Al construirse genera la `idempotency_key`** y la guarda en el
   estado del bloc. Confirmar abre el teclado de PIN existente; con el PIN, ejecuta.

Luego `receipt_screen`, con "compartir constancia" (render del comprobante a imagen + `share_plus`)
y "volver al inicio".

**Recarga** — `TopUpBloc`, una pantalla de monto + PIN, alcanzada desde `HomeAction.topUp`.

**Detalle** — `MovementDetailBloc`, abierto al tocar una fila del historial. Reutiliza el widget de
constancia.

`HomeAction.charge` y `HomeAction.withdraw` siguen mostrando el aviso de "próximamente" que ya
muestran.

## Errores en pantalla

Cada failure tiene su propio mensaje porque el usuario hace cosas distintas:

| Failure | Qué ve | Qué puede hacer |
|---|---|---|
| `insufficientFunds` | "No te alcanza el saldo disponible." | Ir a recargar |
| `wrongPin(n)` | "PIN incorrecto. Te quedan n intentos." | Reintentar |
| `locked(hasta)` | "Cuenta bloqueada hasta las HH:MM." | Nada; cuenta regresiva |
| `recipientNotFound` | "No encontramos a nadie con ese DNI en CuyCash." | Corregir el DNI |
| `selfTransfer` | "No puedes enviarte dinero a ti mismo." | Corregir el DNI |
| `rateLimited` | "Demasiadas búsquedas. Espera un momento." | Esperar |
| `network` | "No pudimos confirmar tu envío." | **Reintentar con la misma clave de idempotencia** |

El último es el importante: ante un fallo de red el envío pudo haberse ejecutado. Reintentar con la
clave original devuelve la transacción original en lugar de cobrar dos veces.

Todo el copy nuevo va al ARB es-PE.

---

# Pruebas

**Backend (`pytest`)**
- Dos `POST /v1/transfers` con la misma `idempotency_key` → un solo cargo, misma `transaction_id`,
  201 y luego 200.
- Dos envíos cruzados simultáneos (A→B y B→A) terminan ambos, sin abrazo mortal.
- Un envío que dejaría el saldo en negativo se rechaza con `INSUFFICIENT_FUNDS` y no escribe
  asientos.
- Tras cada transacción, `SUM(debitos) == SUM(creditos)`.
- Cinco PIN errados en `/v1/transfers` bloquean el DNI, verificable desde `/v1/auth`.
- `resolve` de un DNI ajeno devuelve nombre enmascarado; a la consulta 21 en 10 minutos,
  `RATE_LIMITED`.
- `register` deja usuario **y** cuenta; si la apertura falla, no queda usuario.
- Una recarga deja la cuenta de sistema en negativo sin violar el CHECK.

**App (`flutter test`)**
- `Money`: sumar diez veces S/ 0.10 da exactamente S/ 1.00; `parse` acepta `'250'`, `'250.00'` y
  `'250,00'` y rechaza `'abc'`, `'-5'` y `'1.234'`.
- **Batería de contrato compartida**: el mismo conjunto de casos corre contra el `Memory*` y contra
  el HTTP (con `DioAdapter` simulado) de cada repositorio, para que el flavor `mock` no mienta.
- `bloc_test` por cada failure sellada de `TransferBloc`, y por la paginación de `AccountBloc`.
- Un test que confirma que la `idempotency_key` **no cambia** entre un intento fallido por red y su
  reintento.

---

# Orden sugerido

1. Renombrar `services/auth` → `services/api` (commit propio).
2. Backend: modelo, `scripts/reset_schema.py` con su cerrojo, `current_user`, `accounts.py`,
   `ledger.py` con sus pruebas.
3. Backend: routers `accounts`, `directory`, `transfers`, `topups`, `beneficiaries`.
4. App: `Money` en `core_kernel` y `formatSoles`; `Dio` autenticado.
5. App: `feature/account` + home real (se borra `demo_wallet.dart`).
6. App: `feature/transfer` + flujo de envío + constancia.
7. App: recarga.
8. App: `feature/beneficiary` + frecuentes.
9. Detalle del movimiento y compartir constancia.

Los pasos 2 y 4 no dependen entre sí y pueden ir en paralelo.
