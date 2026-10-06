# CuyCash — Banca Online Integral

App móvil de banca digital para Perú. Proyecto universitario (UTP, 2026).

El alcance del producto cubre onboarding con KYC biométrico facial,
autenticación multifactor, cuentas, transferencias, préstamos digitales,
billetera/QR, motor transaccional, conciliación, antifraude y cumplimiento
PLDFT. Este repositorio contiene **la app móvil y un backend de identidad,
cuentas y libro mayor**; el resto de módulos está planificado por sprints (ver
[`docs/sla-kpi.md`](docs/sla-kpi.md)).

**Implementado hoy**

- Identidad: splash, onboarding, registro con KYC facial, ingreso con DNI + PIN,
  OTP, acceso rápido con bloqueo por intentos, home y perfil.
- Cuentas: una cuenta de ahorro en soles por titular, con saldo e historial de
  movimientos.
- Libro mayor con partida doble, idempotencia y bloqueo de fila.
- Envío de dinero a otro titular de CuyCash por DNI, confirmado con PIN.
- Recarga de saldo, **simulada**: el dinero sale de una cuenta de sistema, no de
  un medio de pago real.
- Beneficiarios frecuentes, detalle de movimiento y constancia compartible.

**No existe todavía:** transferencia interbancaria y CCI, pagos QR, préstamos,
antifraude, conciliación y cumplimiento PLDFT. Tampoco cuentas en USD ni varias
cuentas por titular.

**Estado de la verificación.** La app y el backend tienen sus propias suites
(contra dobles en memoria la app, por HTTP contra SQLite el backend), y el
recorrido del backend se ejercitó a mano con `curl`. La prueba con la app
real hablando con el backend (flavor `local`, en emulador) **nunca se ha
ejecutado**; el guion está en [`docs/verificacion-manual.md`](docs/verificacion-manual.md).

**Sin probar:** los dos tests de concurrencia (marca `postgres`: envíos cruzados
y misma clave en paralelo) nunca se han ejecutado contra un Postgres real; el
orden de bloqueo del `FOR UPDATE` y la ventana de idempotencia están razonados,
no probados. Y el SLA de 200 ms por operación del motor no tiene medición
automatizada.

---

## 1. Levantar el proyecto

### Requisitos

- Flutter (canal estable) con un emulador Android o simulador iOS.
- Python 3.9+ solo si vas a correr `services/api` (la suite corre en 3.9; la imagen Docker usa 3.10).
- Docker solo si quieres ese servicio con Postgres.

### La ruta rápida: flavor `mock`

No necesita backend, credenciales ni red. Es el default de desarrollo.

```sh
flutter pub get                       # en la raíz, resuelve el workspace
cd apps/mobile
flutter run --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json
```

Todos los repositorios son `Memory*`. El **PIN válido es `000000`** y el KYC se
resuelve sin cámara real.

### Contra el backend: flavor `local`

Levanta primero `services/api` (puerto 8001). Sin instalar nada, con SQLite:

```sh
cd services/api
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" \
  .venv/bin/uvicorn app.main:app --reload --port 8001
```

Si cambiaste los modelos y ya tenías una base, el servicio no altera tablas
existentes (`create_all` solo crea las que faltan): recrea el esquema, que
**borra todos los datos**, con `.venv/bin/python scripts/reset_schema.py`. Sin
`ALLOW_DESTRUCTIVE_RESET=1` solo acepta SQLite y `localhost`/`127.0.0.1`.

Con Postgres: `cp .env.example .env && docker compose up --build`.
Docs interactivas en `http://localhost:8001/docs`. Detalle en
[`services/api/README.md`](services/api/README.md).

Luego la app:

```sh
cd apps/mobile
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config.local.json
```

### Comandos del día a día

```sh
flutter pub get                      # en la raíz, resuelve el workspace
flutter analyze                      # cero issues antes de commit
flutter test                         # toda la suite (corre sobre el flavor mock)
dart run build_runner build --delete-conflicting-outputs   # freezed
cd apps/mobile && flutter gen-l10n   # regenera l10n desde los ARB
cd services/api && .venv/bin/python -m pytest             # tests del backend
```

Los tests de concurrencia del libro exigen Postgres real y se omiten sin él (y hasta hoy nadie los ha ejecutado)
(`pytest -m postgres` con `TEST_POSTGRES_URL`; la base debe terminar en
`_test`). Detalle en [`CLAUDE.md`](CLAUDE.md).

`services/api` está fuera del workspace de Flutter: `flutter analyze` y
`flutter test` lo ignoran. Vive en este repo para poder cambiar app y contrato
en un mismo commit.

---

## 2. Entornos

Un flavor = un entrypoint = un grafo de dependencias. No hay `if (kDebugMode)`
decidiendo backends en tiempo de ejecución.

| Flavor | Entrypoint | Config | Backend |
|---|---|---|---|
| `mock` | `lib/main_mock.dart` | `config.mock.json` | Repos en memoria. PIN `000000`. Default de desarrollo y tests. |
| `local` | `lib/main_local.dart` | `config.local.json` | `services/api` corriendo en tu PC. |
| `production` | `lib/main_production.dart` | `config.production.json` | Backend desplegado. |

### Variables de configuración

Se pasan con `--dart-define-from-file`. Plantilla en `apps/mobile/config.example.json`:

```json
{
  "AUTH_BASE_URL": "http://10.0.2.2:8001",
  "KYC_BASE_URL": "",
  "KYC_API_KEY": ""
}
```

| Variable | Si falta |
|---|---|
| `AUTH_BASE_URL` | Se asume el PC anfitrión: `10.0.2.2` en emulador Android, `127.0.0.1` en simulador iOS. |
| `KYC_BASE_URL` / `KYC_API_KEY` | La app cae a `MemoryKycRepository` en vez de romper el arranque. |

En un teléfono **físico** ninguna de las dos se puede inferir: hay que poner la
IP del PC en la red local.

> **La `KYC_API_KEY` en la app es un atajo de demo.** Todo lo compilado en el
> binario es extraíble, así que esa clave debe tratarse como pública. El destino
> es que `services/api` la guarde y actúe de proxy hacia el servicio de KYC;
> hasta entonces, no usarla contra un despliegue real.

---

## 3. Arquitectura

### El monorepo

```
apps/mobile             App Flutter (Bloc).
packages/core_kernel    Result/Either, GlobalFailure, ExceptionMapper, ids. Dart puro.
packages/design_system  Tokens "Eucalipto y Ocre", theme, componentes.
services/api            Backend de identidad, cuentas y libro mayor (FastAPI + Postgres). Fuera del workspace Flutter.
docs/adr                Decisiones de arquitectura.
docs/modelo-datos.md    Modelo de datos: tablas implementadas y diseñadas.
docs/superpowers/specs  Diseño de las funcionalidades implementadas.
docs/sla-kpi.md         SLA, KPI, backlog y plan de sprints.
```

`flutter pub get` en la raíz resuelve el workspace completo (app + packages).

### Features-first vertical

Cada feature se parte en dos mitades. La lógica **no depende de Flutter**:

```
lib/feature/<x>/
  domain/           Entidades, contrato del repositorio, failures sellados.
  application/      Actions/UseCase — lo único que consume el Bloc.
  infrastructure/   Memory*Repository (flavor mock) y Http*Repository (backends reales).

lib/presentation/<x>/   Widgets + Bloc.
```

`feature/auth` es la plantilla: cópiala para features nuevas. Features actuales:
`auth`, `kyc`, `otp`, `device`, `lockout`, `account`, `transfer`, `beneficiary`.

### Composición y arranque

```
lib/core/boot/bootstrap.dart          Arranque común a los tres entrypoints.
lib/core/env/                         Flavor, variables de entorno, host de desarrollo.
lib/core/injection/modules/<x>.dart   Cómo se arma cada feature.
lib/core/injection/envs/<flavor>.dart Qué implementación recibe cada módulo en ese flavor.
```

Cada `main_<flavor>.dart` es tres líneas: construye el grafo de dependencias de
su entorno y se lo entrega a `AppRoot`. Navegación con go_router en
`lib/presentation/app/`.

### Reglas duras

1. Errores como valores (`Either` + `GlobalFailure`); ningún `throw` cruza capas.
2. Failures sellados (factory nombrado + subclase para pattern-match).
3. Toda interfaz nace con su `Memory*` funcional (backend `mock` + contrato de tests).
4. Estados sealed + `switch` exhaustivo; prohibido `when`/`maybeWhen`/`!`.
5. El Bloc consume `application` (Actions/UseCase) por constructor, nunca el repo.
6. Colores/tipografía solo desde `design_system`; cero hex sueltos.
7. Copy es-PE en ARB; cero strings de UI hardcodeados.
8. Un widget público por archivo; `.freezed.dart` y l10n generados se commitean.
9. `auth` es la feature plantilla — cópiala para features nuevas.
10. El dinero es un `int` de céntimos envuelto en `Money`; ningún `double`
    representa dinero.
11. Toda escritura de dinero pasa por `services/api/app/services/ledger.py` y
    lleva `idempotency_key`.

---

## 4. Documentación

| Documento | Qué contiene |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Guía de trabajo en el repo (arquitectura, comandos, reglas). |
| [`docs/sla-kpi.md`](docs/sla-kpi.md) | SLA por módulo, KPI de negocio y ágiles, backlog y sprints. |
| [`docs/verificacion-manual.md`](docs/verificacion-manual.md) | Guion para probar la app contra el backend en un emulador (pendiente de ejecutar). |
| [`docs/modelo-datos.md`](docs/modelo-datos.md) | Modelo de datos: tablas implementadas (con sus columnas) y diseñadas. |
| [`docs/adr/0001-integracion-kyc-facial.md`](docs/adr/0001-integracion-kyc-facial.md) | Contrato, riesgos y acuerdos con el servicio de KYC. |
| [`docs/adr/0002-backend-de-autenticacion.md`](docs/adr/0002-backend-de-autenticacion.md) | Diseño del backend propio de auth. |
| [`docs/superpowers/specs/`](docs/superpowers/specs/) | Diseño de las funcionalidades implementadas. |
| `SLA_KPI_Banca_Online_Integral.xlsx` | Fuente de los SLA/KPI, con justificación por historia. |

## Equipo

| Integrante | Rol |
|---|---|
| Jair Pool Conislla Bocangel | Scrum Master |
| Jeremy Piero Rojas Egusquiza | Backend |
| Jheampierre Johayro Ralli Peralta | Frontend |
| Andersson Junior Espinoza Medina | Datos |
| Gian Piero Gonzales Flores | QA y Seguridad |

Responsabilidad de cada rol sobre los SLA/KPI en [`docs/sla-kpi.md`](docs/sla-kpi.md).
