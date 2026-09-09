# CuyCash — app móvil (banca digital · Perú)

Monorepo Flutter. Sprint 1 = base: splash → onboarding → (login | registro) →
home → perfil (cerrar sesión). Backend real y dashboard web se difieren.

## Estructura
- `apps/mobile` — app Flutter (Bloc).
- `packages/core_kernel` — Result/Either, GlobalFailure, ExceptionMapper, ids (Dart puro).
- `packages/design_system` — tokens "Eucalipto y Ocre", theme, componentes.
- `services/auth` — backend de identidad (FastAPI + Postgres). Fuera del
  workspace de Flutter: `flutter analyze` y `flutter test` lo ignoran. Vive en
  este repo para poder cambiar app y contrato en un mismo commit.

Features-first vertical: `feature/<x>/{domain,application,infrastructure}` (sin
Flutter); UI + Bloc en `presentation/<x>/`.

## Flavors
- `mock` — repos en memoria (PIN válido `0000`). Default de desarrollo + tests.
- `local` — Supabase local (`config.local.json`).
- `production` — Supabase prod (`config.production.json`).

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
