# CuyCash — Banca Online Integral

App móvil de banca digital para Perú. Proyecto universitario (UTP, 2026).

El alcance del producto cubre onboarding con KYC biométrico facial,
autenticación multifactor, cuentas, transferencias, préstamos digitales,
billetera/QR, motor transaccional, conciliación, antifraude y cumplimiento
PLDFT. Este repositorio contiene **la app móvil y el backend de identidad**; el
resto de módulos está planificado por sprints (ver [`docs/sla-kpi.md`](docs/sla-kpi.md)).

Implementado hoy: splash, onboarding, registro con KYC facial, ingreso con
DNI + PIN, OTP, acceso rápido con bloqueo por intentos, home y perfil.

---

## 1. Levantar el proyecto

### Requisitos

- Flutter (canal estable) con un emulador Android o simulador iOS.
- Python 3.11+ solo si vas a correr `services/auth`.
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

### Contra el backend de identidad: flavor `local`

Levanta primero `services/auth` (puerto 8001). Sin instalar nada, con SQLite:

```sh
cd services/auth
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" \
  .venv/bin/uvicorn app.main:app --reload --port 8001
```

Con Postgres: `cp .env.example .env && docker compose up --build`.
Docs interactivas en `http://localhost:8001/docs`. Detalle en
[`services/auth/README.md`](services/auth/README.md).

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
cd services/auth && .venv/bin/python -m pytest             # tests del backend
```

`services/auth` está fuera del workspace de Flutter: `flutter analyze` y
`flutter test` lo ignoran. Vive en este repo para poder cambiar app y contrato
en un mismo commit.

---

## 2. Entornos

Un flavor = un entrypoint = un grafo de dependencias. No hay `if (kDebugMode)`
decidiendo backends en tiempo de ejecución.

| Flavor | Entrypoint | Config | Backend |
|---|---|---|---|
| `mock` | `lib/main_mock.dart` | `config.mock.json` | Repos en memoria. PIN `000000`. Default de desarrollo y tests. |
| `local` | `lib/main_local.dart` | `config.local.json` | `services/auth` corriendo en tu PC. |
| `production` | `lib/main_production.dart` | `config.production.json` | Backend desplegado. |

### Variables de configuración

Se pasan con `--dart-define-from-file`. Plantilla en `apps/mobile/config.example.json`:

```json
{
  "AUTH_BASE_URL": "http://10.0.2.2:8001",
  "KYC_BASE_URL": "http://10.0.2.2:8000",
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
> es que `services/auth` la guarde y actúe de proxy hacia el servicio de KYC;
> hasta entonces, no usarla contra un despliegue real.

---

## 3. Arquitectura

### El monorepo

```
apps/mobile             App Flutter (Bloc).
packages/core_kernel    Result/Either, GlobalFailure, ExceptionMapper, ids. Dart puro.
packages/design_system  Tokens "Eucalipto y Ocre", theme, componentes.
services/auth           Backend de identidad (FastAPI + Postgres). Fuera del workspace Flutter.
docs/adr                Decisiones de arquitectura.
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
`auth`, `kyc`, `otp`, `device`, `lockout`.

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

---

## 4. Documentación

| Documento | Qué contiene |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Guía de trabajo en el repo (arquitectura, comandos, reglas). |
| [`docs/sla-kpi.md`](docs/sla-kpi.md) | SLA por módulo, KPI de negocio y ágiles, backlog y sprints. |
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
