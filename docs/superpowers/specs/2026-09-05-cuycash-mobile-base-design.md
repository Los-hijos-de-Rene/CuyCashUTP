# CuyCash — Sprint 1 (mobile): diseño de la base

- **Fecha:** 2026-09-05
- **Alcance:** app móvil Flutter. El dashboard (web) se difiere a un sprint posterior.
- **State management:** Bloc + tests unitarios.
- **Referencias de arquitectura:** `mediccuy/apps/app` (Bloc — plantilla canónica) y `kuyino/apps/mobile` (Riverpod — mismo esqueleto de capas). CuyCash sigue el patrón de **mediccuy**.

## Objetivo del Sprint 1

Dejar **la base arquitectónica lista** para colgar el resto de features después. Flujo end-to-end:

```
splash → onboarding → (login | registro) → home → perfil (cerrar sesión)
```

- **Login** funcional (DNI/Alias + PIN).
- **Registro**: entrada + pantalla stub. Las pantallas reales (validación DNI/rostro) llegan después.
- **Home**: placeholder autenticado.
- **Perfil**: acción **cerrar sesión** funcional (vuelve a onboarding/login).

Las pantallas detalladas de registro y demás features se entregarán más adelante, una vez completada esta base.

## Decisiones (defaults confirmados)

1. **Monorepo desde ya**: `apps/mobile` + `packages/core_kernel` + `packages/design_system`. El dashboard entra luego como `apps/admin` sin re-migrar.
2. **Tres flavors** (proyecto universitario, un solo servidor real):
   - `mock` → `Memory*` repos, sin red (default de desarrollo + contrato de tests).
   - `local` → apunta a backend local (Supabase local / API en `localhost`).
   - `production` → apunta al backend prod (único servidor real).
   `local` y `production` comparten implementación (`Supabase*Repository`); solo cambian URL/keys.
3. **Auth**: DNI/Alias + PIN (4 dígitos). En `mock`, PIN válido fijo (`0000`).
4. **Bloc**: event+state en freezed sealed, `switch` exhaustivo, `bloc_test`. Los `.freezed.dart` se commitean.

## Reglas duras (heredadas de mediccuy/kuyino)

1. **Errores como valores**: `Either` + `GlobalFailure<F>` de la frontera al pixel. Ningún `throw` cruza capas; catch tipificado en infrastructure vía `ExceptionMapper`.
2. **Failures sellados**: `sealed class XxxFailure` con factory nombrado para construir (`AuthFailure.invalidCredentials()`) + subclase `final` para pattern-match (`case InvalidCredentials()`).
3. **Toda interfaz nace con su `Memory*` funcional** (nunca stubs que lanzan): backend del flavor `mock` + contrato de tests.
4. **Estados sealed + `switch` exhaustivo**. Prohibido `maybeWhen`/`orElse`/`!` sobre estados. Ante error transitorio se retiene el dato previo (no se destruye).
5. **DI por constructor** + composición raíz por flavor (`AppDependencies` + `main_<flavor>.dart`). El Bloc consume la capa `application`, nunca el repository directo.
6. **Colores/tipografía solo desde tokens** (`CuyCashColors`/`CuyCashTypography`). Cero hex sueltos en widgets.
7. **Copy es-PE en ARB** (cero strings de UI hardcodeados).
8. **Un widget público por archivo**; piezas propias en `<feature>/widgets/`. Nombres descriptivos, funciones cortas, early-return.
9. **Imports prohibidos**: `presentation→infrastructure`, `domain→flutter`. Domain depende solo de `core_kernel` + fpdart/freezed.
10. **Test obligatorio**: `Memory*` + use case/bloc. Gate de cobertura ≥80% en `packages/` y `feature/*/application`.

---

## Sección 1 — Estructura del monorepo y flavors

```
cuycash/
├── pubspec.yaml                    # workspace: apps/mobile + packages/*
├── CLAUDE.md                       # reglas del proyecto (derivadas de mediccuy)
├── docs/superpowers/specs/         # este diseño
├── packages/
│   ├── core_kernel/                # Dart puro: Result/Either, GlobalFailure<F>,
│   │   └── lib/                     #   ExceptionMapper, ids. Sin Flutter.
│   └── design_system/              # tokens "Eucalipto y Ocre" + theme + componentes
│       └── lib/
└── apps/
    └── mobile/
        ├── config.mock.json
        ├── config.local.json       # SUPABASE_URL=localhost, keys locales
        ├── config.production.json  # SUPABASE_URL prod, keys prod   (gitignored)
        ├── config.example.json     # plantilla commiteada
        └── lib/
            ├── core/
            │   ├── env/            # AppEnv (--dart-define) + AppFlavor {mock,local,production}
            │   ├── injection/      # AppDependencies + modules/ + envs/ por flavor
            │   ├── router/         # (o presentation/app/router.dart) go_router + gate
            │   └── boot/           # bootstrap.dart (entrypoint genérico)
            ├── feature/            # domain/application/infrastructure (sin Flutter)
            ├── presentation/       # UI + Blocs
            ├── l10n/arb/           # copy es-PE
            ├── main_mock.dart
            ├── main_local.dart
            └── main_production.dart
```

**Comandos:**
```sh
flutter run --flavor mock       -t lib/main_mock.dart       --dart-define-from-file=config.mock.json
flutter run --flavor local      -t lib/main_local.dart      --dart-define-from-file=config.local.json
flutter run --flavor production -t lib/main_production.dart  --dart-define-from-file=config.production.json
```

## Sección 2 — Design System "Eucalipto y Ocre" (`packages/design_system`)

Fuente de tokens: `DESIGN.md` (paleta "Eucalipto y Ocre", tipografía Inter, ritmo 4px). Mismo patrón que mediccuy: tokens en clases `abstract final`, theme centralizado desde tokens, componentes exportados vía `design_system.dart`.

- **`CuyCashColors`** — todos los tokens del DESIGN.md como `Color`:
  - Marca: `primary` (Eucalipto `#152A1F`), `primaryContainer` `#2B4034`, `secondary`/ocre `#D98C2B`, `accentText` `#9B5F12`.
  - Superficies: `surface` `#FBF9F4` (stone), `surfaceContainerLowest` `#FFFFFF` (cards) + escala `surfaceContainer*`.
  - Texto: `onSurface` `#1B1C19`, `secondaryText` `#6B7268`, `outline`/`outlineVariant` (`#C2C8C2`).
  - Estados: `error` (carmín `#B31D3F`), `errorContainer`.
- **`CuyCashTypography`** — escala Inter como `TextStyle` semánticos: `displayLg`, `headlineMd`, `headlineLgMobile`, `titleMd`, `bodyLg`, `bodyMd`, `labelMd`, `labelSm`. Inter va a `assets/fonts/` del package; si aún no está el `.ttf`, se deja `fontFamily` listo (un solo lugar para activarlo).
- **`CuyCashSpacing` / `CuyCashRadii`** — ritmo 4px; radios: cards `14`, botones/inputs `10–12`, badges `6–8`, `full` para pills.
- **`CuyCashTheme.light()`** — `ThemeData` M3 desde tokens: `scaffoldBackgroundColor: surface`; inputs (borde `outlineVariant` 1px, focus eucalipto 2px, radius 12, **label persistente arriba**); botones (primary eucalipto, alto mín. **52px**, radius 10–12); cards (blanco, radius 14, sombra ambiental verde `0px 2px 12px rgba(43,64,52,0.05)`); dividers `#EBE8E0`.
- **Componentes Sprint 1** (un widget público por archivo):
  - `PrimaryButton` / `SecondaryButton` / `GhostButton`.
  - `CuyCashTextField` — input con label persistente arriba (DNI, PIN).
  - `PageDotsIndicator` — dots del onboarding (barra activa eucalipto/ocre).
  - `BrandMark` — logo "CC" (splash + onboarding). Placeholder vectorial hasta el asset final.
  - `AppScaffold`/helper de padding — margen mobile 16px, container-padding 20px.

## Sección 3 — Feature `auth` (domain / application / infrastructure)

**`feature/auth/domain/`** (Dart puro):
- `auth_session.dart` — `AuthSession { userId, identifier, alias? }` con `==`/`hashCode`.
- `auth_failure.dart` — `sealed class AuthFailure` (factory nombrado + subclase `final`): `InvalidCredentials`, `IdentifierTaken`, `WeakPin`, `AuthUnavailable`.
- `auth_repository.dart` — `abstract interface class AuthRepository` (nunca lanza):
  - `AuthSession? get currentSession`
  - `Stream<AuthSession?> sessionChanges()`
  - `FutureResult<AuthFailure, AuthSession> signIn({required String identifier, required String pin})`
  - `FutureResult<AuthFailure, AuthSession> register({required String dni, String? alias, required String pin})`
  - `FutureResult<AuthFailure, Unit> signOut()`

**`feature/auth/application/`**:
- `auth_actions.dart` — `AuthActions(this._repo)`: delegación fina (`signIn`, `register`, `signOut`, `currentSession`, `sessionChanges`). El Bloc la consume por constructor. Si `register`/`signOut` pasan a orquestar 2+ deps, salen a `*_use_case.dart`.

**`feature/auth/infrastructure/`**:
- `memory_auth_repository.dart` — **funcional**: `validPin` default `'0000'`, mapa `dni → session`. `signIn` PIN OK→emite sesión / si no→`InvalidCredentials`; `register` valida PIN (4 dígitos) y DNI único→crea y emite / DNI repetido→`IdentifierTaken` / PIN inválido→`WeakPin`; `signOut`→null + emite.
- `supabase_auth_repository.dart` — **esqueleto** (misma interfaz, flavors `local`/`production`). En sprint 1 mapea a `AuthUnavailable` (documentado como pendiente de backend). Existe para no romper el contrato.

## Sección 4 — Presentation: Blocs, pantallas y navegación

**Composición raíz** (`presentation/app/`):
- `app_root.dart` — `MultiRepositoryProvider` (flavor) + `MultiBlocProvider` (blocs por módulos). Recibe `AppDependencies` resuelto.
- `cuycash_app.dart` — `MaterialApp.router` con `CuyCashTheme.light()` + l10n es-PE.
- `router.dart` — `go_router` con `AppRoutes` + `refreshListenable` sobre `authBloc.stream`.
- `app_redirect.dart` — **gate de auth** (función pura, testeable):
  - `AuthUnauthenticated` → si fuera de pantallas de gate (`/onboarding`, `/login`, `/registro`) → `/onboarding`.
  - `AuthAuthenticated` → si está en pantalla de gate → `/home`.

**Rutas** (`AppRoutes`):
```
/onboarding   → OnboardingScreen (carrusel 3 slides)   [gate]
/login        → LoginScreen (DNI/Alias + PIN)          [gate]
/registro     → RegisterScreen (stub sprint 1)         [gate]
/home         → HomeScreen (placeholder autenticado)   [shell]
/perfil       → ProfileScreen (cerrar sesión)          [shell]
```
- **Splash**: `SplashScreen` Flutter breve (barra de progreso del mockup) → el primer redirect del router decide onboarding/home según sesión.
- **Shell**: `StatefulShellRoute.indexedStack` con 2 tabs (Home, Perfil). Escala a más tabs luego.

**Blocs** (`presentation/<x>/bloc/`, 3 archivos, event+state freezed sealed):
- `auth/bloc/auth_bloc.dart` — consume `AuthActions` por constructor. Estado inicial sincrónico desde `currentSession`; se mueve con `sessionChanges()`.
  - Eventos: `AuthLoginSubmitted(identifier, pin)`, `AuthRegisterSubmitted(dni, alias?, pin)`, `AuthSignedOut`, `_AuthSessionChanged`.
  - Estados: `AuthUnauthenticated({FormStatus status, AuthError? error})` / `AuthAuthenticated(session)`. En éxito de login/registro **no** emite directo: la sesión llega por el stream.
  - `AuthError` enum (sin texto; la UI traduce con ARB vía `auth_error_text.dart`).
- `onboarding` — UI pura (índice de página) → **estado local del widget**, sin Bloc.
- Home/Perfil — leen `AuthBloc` (perfil: identifier + botón cerrar sesión → `AuthSignedOut`). Sin Bloc propio en sprint 1.

**Pantallas** (un widget público por archivo; piezas propias en `<x>/widgets/`):
`SplashScreen`, `OnboardingScreen` (+ `widgets/onboarding_slide.dart`, `PageDotsIndicator`), `LoginScreen` (`CuyCashTextField` + `PrimaryButton`), `RegisterScreen` (stub), `HomeScreen` (placeholder), `ProfileScreen` (cerrar sesión), `AppShell` (bottom nav).

**Copy**: `l10n/arb/app_es.arb` (es-PE), cero strings hardcodeados.

## Sección 5 — Inyección (flavors) + plan de tests

**Composición raíz por flavor** (`core/injection/`):
- `app_dependencies.dart` — grafo inmutable con **solo interfaces** (`flavor`, `authRepository`, …). Crece por feature.
- `modules/auth_module.dart` — `AuthModule.blocProviders(deps)` arma `AuthBloc(AuthActions(deps.authRepository))`. El bloc nunca recibe el repo directo.
- `envs/`:
  - `mock_dependencies.dart` → `AppDependencies(authRepository: MemoryAuthRepository())`. Sin red.
  - `shared/shared_supabase_dependencies.dart` → construye `SupabaseClient` + `Supabase*Repository`.
  - `local_dependencies.dart` / `production_dependencies.dart` → llaman al shared con su config (mismo código, distinta URL/keys).
- `core/env/`: `AppEnv` (lee `--dart-define`) + `AppFlavor { mock, local, production }`.
- `core/boot/bootstrap.dart` — entrypoint genérico (`runZonedGuarded`, `ensureInitialized`).
- `main_mock.dart` / `main_local.dart` / `main_production.dart` → cada uno arma su grafo y monta `AppRoot`.

**Plan de tests** (gate ≥80% en `packages/` y `feature/*/application`):

| Suite | Qué prueba |
|---|---|
| `test/feature/auth/memory_auth_repository_test.dart` | `MemoryAuthRepository`: signIn OK/`InvalidCredentials`, register OK/`IdentifierTaken`/`WeakPin`, signOut emite null. Contrato. |
| `test/feature/auth/auth_actions_test.dart` | Delegación fina (opcional si trivial). |
| `test/presentation/auth/auth_bloc_test.dart` | `bloc_test` sobre `MemoryAuthRepository`: estado inicial (con/sin sesión), login OK→`AuthAuthenticated` (vía stream), login incorrecto→error retenido, register OK/duplicado, signOut→`AuthUnauthenticated`. |
| `test/presentation/app/app_redirect_test.dart` | Gate puro: unauth fuera de gate→`/onboarding`; auth en gate→`/home`; sin redirect innecesario. |
| `test/core/injection/mock_dependencies_test.dart` | El grafo `mock` se construye y expone `MemoryAuthRepository`. |
| `test/presentation/auth/login_screen_test.dart` (widget, opcional) | Render + submit dispara `AuthLoginSubmitted`. |

**Dependencias** (`apps/mobile/pubspec.yaml`): `flutter_bloc`, `go_router`, `fpdart`, `freezed_annotation`, `shared_preferences`, `supabase_flutter` (local/prod); dev: `bloc_test`, `build_runner`, `freezed`, `flutter_lints`. Packages: `core_kernel`, `design_system`.

## Fuera de alcance (Sprint 1)

- Pantallas reales de registro (validación DNI/rostro).
- Backend real (Supabase local/prod) más allá del esqueleto de repos.
- Dashboard web (`apps/admin`).
- Features de billetera (enviar/cobrar/recibir) mostradas en el onboarding — solo copy en las slides.
