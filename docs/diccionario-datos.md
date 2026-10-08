# Diccionario de datos — CuyCash

Descripción de cada columna de las **14 tablas que existen hoy** en la base de
producción (PostgreSQL 16 en Neon, esquema `public`). Los tipos salen de
`services/api/app/db/models.py`, que es también lo que genera
`services/api/schema.sql` y lo que el servicio usa para crear las tablas, así
que este documento describe la base real. Las tablas diseñadas y no creadas
(préstamos, QR, antifraude, conciliación) están en
[`modelo-datos.md`](modelo-datos.md), no aquí.

**Convenciones que valen para todas las tablas**

- `id`: `VARCHAR(36)` con un UUID v4 que genera la aplicación, no la base. Se
  usa texto y no el tipo `uuid` para que el mismo modelo corra en SQLite (tests
  y desarrollo).
- Fechas: `TIMESTAMP WITH TIME ZONE`, siempre en UTC.
- Dinero: `BIGINT` en **céntimos** (S/ 12.50 = `1250`). Ningún importe es de
  coma flotante.
- Secretos (PIN, tokens, códigos OTP, credencial biométrica): solo se guarda su
  hash, nunca el valor.
- Columna **Clave**: PK = clave primaria, FK = clave foránea, UK = única,
  IX = con índice.
- Los valores por defecto los pone la aplicación (SQLAlchemy), no la base.

| Grupo | Tablas |
|---|---|
| Clientes e identidad | `users`, `kyc_verifications` |
| Acceso y sesiones | `devices`, `sessions`, `biometric_credentials` |
| Protección contra fuerza bruta | `login_attempts`, `lockouts`, `otp_challenges`, `otp_tickets` |
| Dinero | `accounts`, `transactions`, `ledger_entries`, `transfers`, `beneficiaries` |

---

## 1. Clientes e identidad

### `users` — clientes de CuyCash

Una fila por cliente registrado. Solo clientes: no hay empleados ni
administradores en esta tabla ni en ninguna otra.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del cliente. |
| `dni` | VARCHAR(8) | No | UK, IX | 8 dígitos (validado en la API) | DNI peruano. Es el identificador de login. |
| `nombres` | VARCHAR(120) | No | | | Nombres, tal como se registraron. |
| `apellidos` | VARCHAR(120) | No | | | Apellidos. |
| `email` | VARCHAR(255) | No | IX | | Correo. Recibe los códigos OTP de recuperación de PIN. |
| `alias` | VARCHAR(60) | No | UK, IX | Al menos una letra | Nombre público para recibir dinero (`@jenny`). La letra obligatoria evita confundirlo con un DNI. |
| `pin_hash` | VARCHAR(255) | No | | argon2id | Hash del PIN de 6 dígitos. El PIN nunca se guarda ni se registra en claro. |
| `pin_updated_at` | TIMESTAMPTZ | No | | Defecto: ahora | Último cambio de PIN. |
| `kyc_status` | VARCHAR(20) | No | | Defecto: `pending` | Estado de verificación de identidad. **Brecha conocida:** nada lo actualiza hoy; siempre queda en `pending`. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Fecha de registro. |

### `kyc_verifications` — resultado de la verificación facial

Veredicto del KYC (documento + prueba de vida + coincidencia de rostro).
**Nunca guarda imágenes**: la foto del DNI y el rostro son datos biométricos
sensibles.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador de la verificación. |
| `user_id` | VARCHAR(36) | No | FK → `users.id`, IX | | Cliente verificado. |
| `verdict` | VARCHAR(20) | No | | | Veredicto global del servicio de KYC. |
| `document_valid` | BOOLEAN | No | | Defecto: `false` | El documento pasó las validaciones (nitidez, OCR). |
| `is_live` | BOOLEAN | No | | Defecto: `false` | La prueba de vida (gestos) confirmó una persona real. |
| `face_match` | BOOLEAN | No | | Defecto: `false` | El rostro coincide con la foto del DNI. |
| `face_distance` | FLOAT | Sí | | | Distancia entre los dos rostros; menor es más parecido. No es dinero, por eso admite coma flotante. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Momento de la verificación. |

> **Estado real:** la tabla existe en la base, pero hoy ninguna ruta la llena.
> El veredicto llega a la app y es la app la que continúa el registro (ver la
> brecha de KYC en `CLAUDE.md`).

---

## 2. Acceso y sesiones

### `devices` — teléfonos vinculados

Un teléfono de confianza de un cliente. Desde un teléfono no vinculado, entrar
exige un OTP.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del vínculo. |
| `user_id` | VARCHAR(36) | No | FK → `users.id`, IX | UK junto con `device_id` | Cliente dueño del vínculo. |
| `device_id` | VARCHAR(128) | No | IX | UK junto con `user_id` | Identificador del teléfono que envía la app. |
| `trusted_at` | TIMESTAMPTZ | No | | Defecto: ahora | Cuándo se vinculó. |
| `last_seen_at` | TIMESTAMPTZ | No | | Defecto: ahora | Último uso. |
| `nombre` | VARCHAR(80) | Sí | | ASCII imprimible | Modelo declarado por el teléfono (`Samsung SM-A546E`). Solo se muestra; no decide nada de seguridad. |
| `plataforma` | VARCHAR(20) | Sí | | | `android` o `ios`, declarado por el teléfono. Solo se muestra. |

### `sessions` — sesiones abiertas

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador de la sesión. |
| `user_id` | VARCHAR(36) | No | FK → `users.id`, IX | | Cliente de la sesión. |
| `device_id` | VARCHAR(128) | No | | | Teléfono desde el que se abrió. |
| `token_hash` | VARCHAR(64) | No | UK, IX | SHA-256 | Hash del token de sesión (256 bits aleatorios). Un volcado de la base no permite entrar como nadie. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Apertura. |
| `expires_at` | TIMESTAMPTZ | No | | | Vencimiento. |
| `revoked_at` | TIMESTAMPTZ | Sí | | | Cierre anticipado (logout, cambio de PIN que cierra los otros teléfonos). Nulo = vigente. |

### `biometric_credentials` — acceso con huella

Secreto que la huella libera en el teléfono para abrir sesión sin teclear el
PIN. La huella nunca sale del teléfono.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador de la credencial. |
| `user_id` | VARCHAR(36) | No | FK → `users.id`, IX | | Cliente que la enroló. |
| `device_id` | VARCHAR(128) | No | IX | | Teléfono al que queda ligada; desde otro no sirve. |
| `secret_hash` | VARCHAR(64) | No | UK, IX | SHA-256 | Hash del secreto de 256 bits que emitió el servidor. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Enrolamiento. |
| `revoked_at` | TIMESTAMPTZ | Sí | | | Revocación (al desvincular el teléfono o cambiar el PIN). Una fila revocada no vuelve a valer. |

---

## 3. Protección contra fuerza bruta

Estas tablas no tienen FK a `users` a propósito: registran intentos **antes**
de saber si el usuario existe o de que se autentique.

### `login_attempts` — cada intento de login

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del intento. |
| `dni` | VARCHAR(8) | No | IX | | DNI con el que se intentó entrar (exista o no). |
| `device_id` | VARCHAR(128) | No | IX | | Teléfono del intento. |
| `succeeded` | BOOLEAN | No | | Defecto: `false` | Si el PIN fue correcto. |
| `created_at` | TIMESTAMPTZ | No | IX | Defecto: ahora | Momento del intento. Permite contar los fallos de los últimos N minutos (ventana deslizante). |

### `lockouts` — bloqueos vigentes

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del bloqueo. |
| `subject_type` | VARCHAR(10) | No | IX | UK junto con `subject_value`; `dni`, `device` u `otp` | Qué se bloquea: una cuenta en cualquier teléfono (`dni`), un teléfono que barre cuentas (`device`) o un flujo OTP agotado (`otp`). |
| `subject_value` | VARCHAR(128) | No | IX | | El DNI, el id del teléfono o el identificador del OTP. |
| `level` | INTEGER | No | | Defecto: `0` | Nivel de escalado: cada bloqueo repetido dura más. |
| `locked_until` | TIMESTAMPTZ | Sí | | | Fin del bloqueo. Nulo o pasado = no bloqueado. |
| `updated_at` | TIMESTAMPTZ | No | | Defecto: ahora | Última actualización; marca el inicio de la ventana de conteo. |

### `otp_challenges` — códigos de un solo uso enviados

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del reto. |
| `purpose` | VARCHAR(20) | No | | `recovery` o `device` (validado en la API) | Para qué es: recuperar el PIN o vincular un teléfono nuevo. |
| `identifier` | VARCHAR(255) | No | IX | | Correo (`recovery`) o DNI (`device`) con el que se pidió. |
| `user_id` | VARCHAR(36) | Sí | | Sin FK | Cliente encontrado. Nulo si no existe: el reto se crea igual para no revelar qué cuentas hay. |
| `code_hash` | VARCHAR(64) | No | | SHA-256 | Hash del código de 6 dígitos. |
| `expires_at` | TIMESTAMPTZ | No | | | Vencimiento del código. |
| `cooldown_until` | TIMESTAMPTZ | No | | | Antes de esta hora no se puede pedir un reenvío. |
| `attempts_left` | INTEGER | No | | | Intentos de verificación restantes. |
| `resends_left` | INTEGER | No | | | Reenvíos restantes. |
| `consumed_at` | TIMESTAMPTZ | Sí | | | Cuándo se verificó correctamente. |
| `cancelled_reason` | VARCHAR(20) | Sí | | `attempts` o `resends` | Por qué se anuló: se agotaron los intentos o los reenvíos. Anularlo también crea un bloqueo `otp`. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Creación. |

### `otp_tickets` — prueba de que un OTP se verificó

Separa "verifiqué el código" de "cambio el PIN": restablecer el PIN exige este
ticket.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del ticket. |
| `token_hash` | VARCHAR(64) | No | UK, IX | SHA-256 | Hash del ticket que recibe la app. |
| `purpose` | VARCHAR(20) | No | | | Propósito del OTP que lo originó. |
| `identifier` | VARCHAR(255) | No | | | Correo o DNI del flujo. |
| `user_id` | VARCHAR(36) | Sí | | Sin FK | Cliente del flujo. |
| `expires_at` | TIMESTAMPTZ | No | | | Vencimiento. |
| `used_at` | TIMESTAMPTZ | Sí | | | Cuándo se consumió; un solo uso. |
| `checks_left` | INTEGER | No | | Defecto: `5` | Comprobaciones de PIN restantes con este ticket. Sin tope, el ticket serviría para adivinar el PIN. |

---

## 4. Dinero

Reglas comunes: importes en céntimos (`BIGINT`), toda escritura pasa por
`app/services/ledger.py` y ningún asiento se borra.

### `accounts` — cuentas

Cuentas de los clientes, más **dos cuentas internas de CuyCash** (la caja en
soles y la caja en dólares). La caja es la contraparte de cada recarga y existe
por la partida doble: el dinero que entra a una cuenta tiene que salir de otra.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador de la cuenta. |
| `user_id` | VARCHAR(36) | Sí | FK → `users.id`, IX | Nulo **si y solo si** `tipo = 'sistema'` | Titular. |
| `numero` | VARCHAR(14) | No | UK, IX | 14 dígitos con prefijo `191` | Número de cuenta. Las cajas tienen números fijos y reservados: `19100000000000` (PEN) y `19100000000001` (USD). |
| `tipo` | VARCHAR(10) | No | | `ahorro`, `corriente`, `sueldo`, `sistema`; defecto `ahorro` | Producto. `sistema` = caja interna de CuyCash. |
| `moneda` | VARCHAR(3) | No | | `PEN` o `USD`; defecto `PEN` | Moneda. La cuenta sueldo solo puede ser `PEN`. |
| `estado` | VARCHAR(10) | No | | `activa`, `bloqueada`, `cerrada`; defecto `activa` | Solo una cuenta activa recibe dinero. |
| `nombre` | VARCHAR(30) | Sí | | | Nombre que le pone el titular ("Viaje"). Solo lo ve él. |
| `idempotency_key` | VARCHAR(64) | Sí | UK junto con `user_id` | | Clave de la petición que abrió la cuenta: reintentar no abre una segunda. Nula en la cuenta del registro y en las cajas. |
| `saldo_disponible` | BIGINT | No | | ≥ 0 salvo en `sistema`; defecto `0` | Saldo usable, en céntimos. Se actualiza en el mismo COMMIT que los asientos. |
| `saldo_contable` | BIGINT | No | | Defecto `0` | Saldo contable, en céntimos. Hoy coincide con el disponible porque no existen retenciones. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Apertura. |

Restricciones de tabla:

| Nombre | Regla | Por qué |
|---|---|---|
| `ck_accounts_sistema_sin_titular` | `(tipo = 'sistema') = (user_id IS NULL)` | Una caja no tiene titular y una cuenta de cliente siempre lo tiene. |
| `ck_accounts_saldo_no_negativo` | `tipo = 'sistema' OR saldo_disponible >= 0` | Última defensa contra el doble gasto. La caja queda en negativo por diseño: su saldo es el dinero inyectado por las recargas. |
| `ck_accounts_sueldo_en_soles` | `tipo <> 'sueldo' OR moneda = 'PEN'` | La planilla en Perú se paga en soles. |
| `ux_accounts_un_sueldo` | Índice único parcial `(user_id) WHERE tipo = 'sueldo'` | Una cuenta sueldo por titular, también ante dos aperturas simultáneas. |
| `uq_accounts_clave_apertura` | `UNIQUE (user_id, idempotency_key)` | Abrir una cuenta es idempotente. |
| Regla del servicio (no de la base) | Máximo 5 cuentas por titular | Se serializa con `SELECT … FOR UPDATE` sobre la fila de `users`. |

### `transactions` — operaciones

Una operación de dinero (un envío, una recarga). Agrupa sus asientos.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador de la operación; es el número de constancia. |
| `tipo` | VARCHAR(20) | No | | `transferencia`, `recarga`, `pago_qr`, `desembolso`, `cuota`, `ajuste` | Clase de operación. Hoy solo se usan `transferencia` y `recarga`; el resto queda listo para los sprints siguientes. |
| `estado` | VARCHAR(12) | No | | `pendiente`, `confirmada`, `revertida`; defecto `confirmada` | Estado de la operación. |
| `idempotency_key` | VARCHAR(64) | No | UK, IX | | Clave que genera la app y repite al reintentar. Un reintento devuelve la operación original en lugar de cobrar dos veces. |
| `referencia` | VARCHAR(60) | Sí | | | Texto de referencia de la operación. |
| `request_fingerprint` | VARCHAR(64) | No | | Defecto `''` | Huella de los datos de la petición. Si la misma clave llega con otros datos, se rechaza con 409. |
| `created_at` | TIMESTAMPTZ | No | IX | Defecto: ahora | Fecha de la operación. |

### `ledger_entries` — asientos del libro mayor (partida doble)

Cada movimiento de dinero contra una cuenta. Es la fuente de verdad contable:
el saldo de `accounts` se puede reconstruir sumando estos asientos.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del asiento. |
| `transaction_id` | VARCHAR(36) | No | FK → `transactions.id`, IX | | Operación a la que pertenece. Cada operación tiene al menos dos asientos. |
| `account_id` | VARCHAR(36) | No | FK → `accounts.id`, IX | | Cuenta afectada. |
| `direccion` | VARCHAR(8) | No | | `debito` o `credito` | `debito` = sale dinero de esa cuenta; `credito` = entra. |
| `monto` | BIGINT | No | | `> 0` | Importe en céntimos, siempre positivo; el signo lo da `direccion`. |
| `moneda` | VARCHAR(3) | No | | Defecto `PEN` | Moneda del asiento (la de la cuenta). |
| `saldo_posterior` | BIGINT | No | | | Saldo de la cuenta justo después del asiento; permite auditar la cadena sin recalcular toda la historia. |
| `created_at` | TIMESTAMPTZ | No | IX | Defecto: ahora | Momento del asiento. |

Reglas: en cada operación, la suma de los débitos es igual a la de los créditos
(lo verifica `ledger.py` antes de escribir) y todos los asientos entran en la
misma transacción de base de datos: o todos o ninguno. El índice
`ix_ledger_cuenta_fecha_id (account_id, created_at, id)` sirve para paginar el
historial de una cuenta.

### `transfers` — detalle de los envíos

Lo que un asiento no dice: desde dónde, hacia quién y por qué. El dinero está en
`ledger_entries`; esta fila es la intención. Una recarga no tiene fila aquí.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del envío. |
| `transaction_id` | VARCHAR(36) | No | FK → `transactions.id`, UK, IX | | Operación que lo materializa; una transferencia por operación. |
| `cuenta_origen` | VARCHAR(36) | No | FK → `accounts.id`, IX | | Cuenta que envía. |
| `cuenta_destino` | VARCHAR(36) | No | FK → `accounts.id`, IX | | Cuenta que recibe (de otro cliente o propia). Siempre de CuyCash y de la misma moneda. |
| `monto` | BIGINT | No | | | Importe en céntimos. |
| `motivo` | VARCHAR(40) | Sí | | | Concepto opcional que escribe quien envía. |
| `estado` | VARCHAR(12) | No | | Defecto `confirmada` | Estado del envío. |

### `beneficiaries` — frecuentes

Una cuenta de destino guardada por un cliente, con un apodo.

| Columna | Tipo | Nulo | Clave | Restricción / defecto | Descripción |
|---|---|---|---|---|---|
| `id` | VARCHAR(36) | No | PK | UUID | Identificador del frecuente. |
| `user_id` | VARCHAR(36) | No | FK → `users.id`, IX | UK junto con `cuenta_destino_id` | Cliente que lo guardó. |
| `beneficiario_dni` | VARCHAR(8) | No | IX | | DNI del destinatario; sirve para volver a buscarlo si esa cuenta deja de recibir. |
| `cuenta_destino_id` | VARCHAR(36) | No | FK → `accounts.id`, IX | UK junto con `user_id` | Cuenta concreta guardada ("la de ahorros en soles de Luis"), no solo la persona. |
| `apodo` | VARCHAR(40) | No | | | Nombre que le pone el cliente. |
| `created_at` | TIMESTAMPTZ | No | | Defecto: ahora | Fecha en que se guardó. |

Es lo único que se borra (`DELETE /v1/beneficiaries/{id}`), porque no es dinero.

---

## Mantener este documento

Si cambias un modelo en `app/db/models.py`, regenera `schema.sql`
(`.venv/bin/python scripts/dump_schema.py > schema.sql`) y actualiza aquí la
fila de la columna afectada. `test_consistencia_ddl.py` comprueba que
`schema.sql` y los modelos coinciden; este diccionario se mantiene a mano.
