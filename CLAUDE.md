# CuyCash — app móvil (banca digital · Perú)

Monorepo Flutter. Proyecto universitario UTP 2026, "Banca Online Integral".
El producto completo son 22 historias de usuario en 6 épicas repartidas en 6
sprints: identidad/KYC, cuentas y motor transaccional, transferencias y
antifraude, préstamos digitales, billetera/QR, conciliación y cumplimiento.

**Lo implementado hoy** es el Sprint 1 (identidad y accesos) más la épica 2
(cuentas y libro mayor) y una parte de la 3 (transferencia entre cuentas CuyCash):

- Identidad: splash → onboarding → (login | registro con KYC) → home → perfil,
  más OTP, PIN y acceso rápido con bloqueo por intentos.
- Cuentas: hasta 5 cuentas por titular (ahorros, corriente o sueldo; soles o
  dólares; sueldo única y en soles), con nombre opcional; se abren desde el
  carrusel del inicio con PIN. Cada una con saldo y movimientos. Rutas:
  `POST /v1/accounts`, `PATCH /v1/accounts/{id}/nombre`.
- Libro mayor con partida doble: toda operación de dinero pasa por
  `services/api/app/services/ledger.py`, con idempotencia y bloqueo de fila.
- Envío de dinero entre titulares de CuyCash, identificando al destinatario por
  DNI y confirmando con PIN. Resolver un DNI devuelve el nombre enmascarado.
- Recarga de saldo: cash-in **simulado** contra una cuenta de sistema (la caja
  de CuyCash), la única que puede quedar en negativo.
- Beneficiarios frecuentes, detalle de movimiento y constancia compartible.
- Perfil: datos personales (solo lectura), alias, cambio de PIN con sesión
  abierta (cierra los otros teléfonos), dispositivos vinculados y acceso
  biométrico real: la huella libera una credencial emitida por el servidor
  (`/v1/auth/sessions/biometric`), revocable al desvincular o cambiar el PIN.
  Rutas: `GET /v1/me`, `PATCH /v1/me/alias`, `GET /v1/devices`,
  `DELETE /v1/devices/{id}`, `POST /v1/auth/pin/change`,
  `POST /v1/auth/biometric/enroll`, `DELETE /v1/auth/biometric/current`,
  `POST /v1/auth/sessions/biometric`. La app manda `X-Device-Name` como ASCII
  `plataforma|modelo` (p. ej. `android|Samsung SM-A546E`), saneado a ASCII
  imprimible (`formatDeviceName`, `core/env/device_name.dart`).

**Sigue sin existir** (no asumas que hay código de esto): transferencia
interbancaria y CCI, pagos y cobro por QR, préstamos, antifraude, conciliación
y cumplimiento (PLDFT). Tampoco hay conversión entre monedas (un envío solo va
entre cuentas de la misma moneda). El dashboard web está diferido.

**Lo que no se ha comprobado:** la app y el backend se probaron cada uno contra
su propio doble (la app contra `Memory*`, el backend por HTTP con su suite). La
verificación en un emulador del flavor `local` contra `services/api` **nunca se
ha ejecutado**; el guion está en `docs/verificacion-manual.md`, con los pasos de
pantalla marcados como inferidos del código.

El diálogo real de `local_auth` (Android/iOS) no se ha probado en un teléfono;
los tests usan `MemoryBiometricGate`.

**Brecha conocida: `kyc_status`.** Nada en el backend lo escribe: queda en
`pending`. La pantalla de datos personales muestra el sello "Identidad
verificada" solo si el servidor dice `verified`, así que hoy nunca aparece.

**Concurrencia sin probar.** Los tests marcados `postgres` (envíos cruzados,
misma clave en paralelo y, en `tests/test_concurrencia_multicuenta.py`, aperturas
simultáneas de sueldo) **nunca se han ejecutado contra un Postgres real**:
el orden de bloqueo del `FOR UPDATE` y la ventana de idempotencia están
razonados, no probados. Es la única garantía del sprint en ese estado.

Backlog, sprints, SLA y KPI: `docs/sla-kpi.md` (derivado de
`SLA_KPI_Banca_Online_Integral.xlsx`).

## Estructura
- `apps/mobile` — app Flutter (Bloc).
- `packages/core_kernel` — Result/Either, GlobalFailure, ExceptionMapper, ids (Dart puro).
- `packages/design_system` — tokens "Eucalipto y Ocre", theme, componentes.
- `services/api` — backend de identidad, cuentas y libro mayor (FastAPI +
  Postgres; SQLite para desarrollo y tests). Fuera del workspace de Flutter:
  `flutter analyze` y `flutter test` lo ignoran. Vive en este repo para poder
  cambiar app y contrato en un mismo commit.

Features-first vertical: `feature/<x>/{domain,application,infrastructure}` (sin
Flutter); UI + Bloc en `presentation/<x>/`. Features actuales: `auth`, `kyc`, `profile`, `security`, `biometric`,
`otp`, `device`, `lockout`, `account`, `transfer`, `beneficiary`. (La recarga
vive en `transfer`; su UI en `presentation/topup/`.)

Composición por flavor en `lib/core/injection/`: `modules/<x>.dart` arma cada
feature, `envs/<flavor>.dart` decide qué implementación recibe. Cada
`main_<flavor>.dart` solo construye ese grafo y se lo pasa a `AppRoot`.

## Flavors
- `mock` — repos en memoria (PIN válido `000000`). Default de desarrollo + tests.
  `MemorySecurityState` fija el DNI `70123456`: el acceso biométrico en mock
  solo funciona con ese DNI.
- `local` — contra `services/api` (`config.local.json`).
- `production` — contra el backend desplegado (`config.production.json`).

`AUTH_BASE_URL` es opcional: sin él se asume el PC anfitrión (`10.0.2.2` en
emulador Android, `127.0.0.1` en simulador iOS). En un teléfono FÍSICO hay que
ponerlo con la IP del PC en la red local.

## KYC facial (servicio externo)
`feature/kyc` consume el microservicio de documento + liveness guiado. El
teléfono NO ejecuta modelos: captura ráfagas y pregunta; el orden de las tareas
lo impone el servidor (anti-replay).

Config en `config.<env>.json`: `KYC_BASE_URL` (emulador Android: `10.0.2.2`;
teléfono físico: IP del PC) y `KYC_API_KEY`. Sin ellas se cae al
`MemoryKycRepository` en vez de romper el arranque.

Contrato, riesgos y acuerdos con el servicio: `docs/adr/0001-integracion-kyc-facial.md`.
Diseño del backend propio de auth: `docs/adr/0002-backend-de-autenticacion.md`.
Diseño de cuentas, envío y recarga: `docs/superpowers/specs/2026-10-05-cuentas-y-transferencias-design.md`.
Modelo de datos (tablas reales y las diseñadas): `docs/modelo-datos.md`.

**La `KYC_API_KEY` en la app es un atajo de demo.** Todo lo compilado en el
binario es extraíble, así que esa clave debe tratarse como pública. El destino
es un backend propio que la guarde y llame al servicio; hasta entonces, no
usarla contra un despliegue real.

## SLA comprometidos que condicionan el código
Números que no son adorno: si un cambio los pone en riesgo, dilo. Tabla
completa en `docs/sla-kpi.md`.

- Nitidez del documento (OCR/blur): ≤ 2 s por imagen.
- Un paso de liveness (`/liveness/evaluate`): < 1 s (solo MediaPipe).
- Token de desafío de liveness: 180 s de vigencia.
- `verify-full`: ≤ 5 s, y se llama **una sola vez al final**.
- Autenticación biométrica o por PIN: < 1.5 s, siempre con PIN de contingencia.
  La huella usa una sola petición con SHA-256; **sin medición automatizada**
  del 1.5 s.
- Bloqueo automático de cuenta al 5.º intento fallido. (El código bloquea al
  3.er intento: `IDENTIFIER_MAX_ATTEMPTS = 3` en el backend y
  `LockoutPolicy.maxAttempts` en la app.)
- Onboarding completo: < 5 min, con ≥ 85 % de finalización.
- Motor transaccional: < 200 ms por operación; libro mayor atómico (débito y
  crédito en la misma transacción de base de datos). La atomicidad está
  cubierta por tests; los 200 ms **no tienen medición automatizada** en el repo.
- Una sola autorización por operación (idempotencia): hoy la implementan el
  envío y la recarga con `idempotency_key` única; el pago QR aún no existe.

## Comandos
```sh
flutter pub get                       # en la raíz, resuelve el workspace
flutter analyze                       # cero issues antes de commit
flutter test                          # toda la suite
dart run build_runner build --delete-conflicting-outputs   # freezed
flutter gen-l10n                      # regenera ARB (en apps/mobile)

# Ejecutar (en apps/mobile)
flutter run --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json

# Backend (en services/api)
.venv/bin/python -m pytest -q         # suite sobre SQLite en memoria
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" .venv/bin/python -m uvicorn app.main:app --port 8001

# Recrear el esquema (DESTRUCTIVO: borra todas las tablas y las vuelve a crear)
.venv/bin/python scripts/reset_schema.py
```

**Por qué recrear el esquema:** el servicio crea tablas con `create_all`, que
no altera las que ya existen; un `CHECK` cambiado no llega a una base ya
creada. Mientras no haya datos reales se recrea en vez de migrar.
`scripts/reset_schema.py` lleva un cerrojo: sin `ALLOW_DESTRUCTIVE_RESET=1` solo
acepta SQLite y los hosts `localhost`/`127.0.0.1` (y rechaza `ENV=production`).
Contra una base remota hay que pasar esa variable a propósito.

**Tests que exigen Postgres** (el bloqueo de fila y la concurrencia no se
pueden probar en SQLite; sin esta variable se omiten, y hasta hoy nadie los ha
ejecutado contra un Postgres real):
```sh
cd services/api
TEST_POSTGRES_URL="postgresql+asyncpg://user:pass@localhost/cuycash_test" \
  .venv/bin/python -m pytest -m postgres -q
```
El fixture hace `drop_all` al entrar y al salir, así que el nombre de la base
**debe terminar en `_test`** o se niega a correr. Nunca apuntarlo a una base con
datos. `schema.sql` se regenera con `scripts/dump_schema.py`, no a mano.

## Reglas duras
1. Errores como valores (`Either`+`GlobalFailure`); ningún `throw` cruza capas.
2. Failures sellados (factory nombrado + subclase para pattern-match).
3. Toda interfaz nace con su `Memory*` funcional (backend `mock` + contrato de tests).
4. Estados sealed + `switch` exhaustivo; prohibido `when`/`maybeWhen`/`!`.
5. El Bloc consume `application` (Actions/UseCase) por constructor, nunca el repo.
6. Colores/tipografía solo desde `design_system`; cero hex sueltos.
7. Copy es-PE en ARB; cero strings de UI hardcodeados.
8. Un widget público por archivo; `.freezed.dart`/l10n generados se commitean.
9. `auth` es la feature plantilla — cópiala para features nuevas.
10. **El dinero es un `int` de céntimos envuelto en `Money`
    (`core_kernel`); ningún `double` representa dinero.** Mismo criterio en el
    backend: `BIGINT` de céntimos y `StrictInt` en los payloads. Formatear a
    soles solo al mostrar (`formatSoles`).
11. Toda escritura de dinero pasa por `app/services/ledger.py` y lleva
    `idempotency_key`; ninguna ruta inserta asientos por su cuenta.
