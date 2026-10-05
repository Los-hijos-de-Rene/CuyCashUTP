# CuyCash — app móvil (banca digital · Perú)

Monorepo Flutter. Proyecto universitario UTP 2026, "Banca Online Integral".
El producto completo son 22 historias de usuario en 6 épicas repartidas en 6
sprints: identidad/KYC, cuentas y motor transaccional, transferencias y
antifraude, préstamos digitales, billetera/QR, conciliación y cumplimiento.

**Lo implementado hoy es el Sprint 1 (identidad y accesos):** splash →
onboarding → (login | registro con KYC) → home → perfil, más OTP, PIN y acceso
rápido con bloqueo por intentos. Cuentas, transferencias, préstamos, QR,
conciliación y antifraude **no existen todavía** — no asumas que hay código de
esos módulos. El dashboard web está diferido.

Backlog, sprints, SLA y KPI: `docs/sla-kpi.md` (derivado de
`SLA_KPI_Banca_Online_Integral.xlsx`).

## Estructura
- `apps/mobile` — app Flutter (Bloc).
- `packages/core_kernel` — Result/Either, GlobalFailure, ExceptionMapper, ids (Dart puro).
- `packages/design_system` — tokens "Eucalipto y Ocre", theme, componentes.
- `services/api` — backend de identidad (FastAPI + Postgres). Fuera del
  workspace de Flutter: `flutter analyze` y `flutter test` lo ignoran. Vive en
  este repo para poder cambiar app y contrato en un mismo commit.

Features-first vertical: `feature/<x>/{domain,application,infrastructure}` (sin
Flutter); UI + Bloc en `presentation/<x>/`. Features actuales: `auth`, `kyc`,
`otp`, `device`, `lockout`.

Composición por flavor en `lib/core/injection/`: `modules/<x>.dart` arma cada
feature, `envs/<flavor>.dart` decide qué implementación recibe. Cada
`main_<flavor>.dart` solo construye ese grafo y se lo pasa a `AppRoot`.

## Flavors
- `mock` — repos en memoria (PIN válido `000000`). Default de desarrollo + tests.
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
- Bloqueo automático de cuenta al 5.º intento fallido.
- Onboarding completo: < 5 min, con ≥ 85 % de finalización.
- Futuro motor transaccional: < 200 ms por operación; libro mayor atómico.
- Pagos QR: una sola autorización por pago (idempotencia).

## Comandos
```sh
flutter pub get                       # en la raíz, resuelve el workspace
flutter analyze                       # cero issues antes de commit
flutter test                          # toda la suite
dart run build_runner build --delete-conflicting-outputs   # freezed
flutter gen-l10n                      # regenera ARB (en apps/mobile)

# Ejecutar (en apps/mobile)
flutter run --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json
```

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
