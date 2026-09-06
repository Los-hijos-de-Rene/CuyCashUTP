# CuyCash — Base Mobile (Sprint 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Levantar la base arquitectónica del app móvil CuyCash (monorepo Flutter + Bloc + tests) con el flujo splash → onboarding → (login | registro) → home → perfil (cerrar sesión).

**Architecture:** Monorepo con `apps/mobile` + `packages/{core_kernel,design_system}`. Features-first vertical (`domain`/`application`/`infrastructure` sin Flutter; `presentation` con Bloc). Errores como valores (`Either`+`GlobalFailure`). DI por constructor con composición raíz por flavor (`mock`/`local`/`production`).

**Tech Stack:** Flutter (Dart ^3.8), flutter_bloc, go_router, fpdart, freezed, bloc_test, supabase_flutter (solo local/prod).

**Spec:** `docs/superpowers/specs/2026-09-05-cuycash-mobile-base-design.md`

## Global Constraints

- **Dart SDK:** `^3.8.0`. Todos los `pubspec.yaml` con `publish_to: none` y `resolution: workspace` (excepto el root, que define `workspace:`).
- **Errores como valores:** todo método que puede fallar devuelve `FutureResult<F,T>` (`Future<Either<GlobalFailure<F>,T>>`). Ningún `throw` cruza la frontera de capas.
- **Failures sellados:** `sealed class XxxFailure` con factory nombrado (construcción) + subclase `final` (pattern-match).
- **Estados sealed + `switch` exhaustivo:** prohibido `when`/`maybeWhen`/`orElse`/`!` sobre estados.
- **Imports prohibidos:** `presentation→infrastructure`, `domain→flutter`. `domain`/`application`/`infrastructure` = Dart puro.
- **DI:** el Bloc consume la capa `application` (`AuthActions`) por constructor, nunca el repository directo.
- **Design tokens:** cero hex sueltos en widgets; todo desde `CuyCashColors`/`CuyCashTypography`.
- **Copy es-PE en ARB:** cero strings de UI hardcodeados. Marca escrita "CuyCash".
- **Codegen:** `.freezed.dart`/`.g.dart` se commitean. Regenerar con `dart run build_runner build --delete-conflicting-outputs`.
- **Un widget público por archivo.** Nombres descriptivos (nunca de una letra salvo `_`, `emit`, `i`).
- **Flavor `mock`:** PIN válido fijo `0000`.
- **Commits en español:** `feat: ...`, `test: ...`, `docs: ...`, `chore: ...`.

---

## File Structure

```
cuycash/
├── pubspec.yaml                         # workspace root
├── analysis_options.yaml
├── .gitignore
├── packages/
│   ├── core_kernel/
│   │   ├── pubspec.yaml
│   │   └── lib/core_kernel.dart + src/{result,failures/global_failure,failures/exception_mapper,ids}.dart
│   └── design_system/
│       ├── pubspec.yaml
│       └── lib/design_system.dart + src/{cuycash_colors,cuycash_typography,cuycash_spacing,cuycash_theme,
│                                          primary_button,secondary_button,ghost_button,cuycash_text_field,
│                                          page_dots_indicator,brand_mark}.dart
└── apps/mobile/
    ├── pubspec.yaml
    ├── config.{mock,local,production,example}.json
    └── lib/
        ├── core/env/{app_env,app_flavor}.dart
        ├── core/boot/bootstrap.dart
        ├── core/injection/app_dependencies.dart
        ├── core/injection/modules/auth_module.dart
        ├── core/injection/envs/{mock,local,production}_dependencies.dart
        ├── core/injection/envs/shared/shared_supabase_dependencies.dart
        ├── feature/auth/domain/{auth_session,auth_failure,auth_repository}.dart
        ├── feature/auth/application/auth_actions.dart
        ├── feature/auth/infrastructure/{memory_auth_repository,supabase_auth_repository}.dart
        ├── presentation/app/{app_root,cuycash_app,router,app_redirect,go_router_refresh_stream}.dart
        ├── presentation/auth/bloc/{auth_bloc,auth_event,auth_state,auth_bloc.freezed}.dart
        ├── presentation/auth/{login_screen,register_screen,auth_error_text}.dart
        ├── presentation/onboarding/onboarding_screen.dart + widgets/onboarding_slide.dart
        ├── presentation/splash/splash_screen.dart
        ├── presentation/home/home_screen.dart
        ├── presentation/profile/profile_screen.dart
        ├── presentation/shell/app_shell.dart
        ├── l10n/arb/app_es.arb
        └── main_{mock,local,production}.dart
```

---

## Task 1: Scaffolding del monorepo

**Files:**
- Create: `pubspec.yaml` (root), `analysis_options.yaml`, `.gitignore`
- Create (vía `flutter create`): `apps/mobile/` (con android/ios)
- Create: `packages/core_kernel/pubspec.yaml`, `packages/design_system/pubspec.yaml`

**Interfaces:**
- Produces: workspace resoluble; paquetes `core_kernel` y `design_system` referenciables por path.

- [ ] **Step 1: Crear el app Flutter base**

```bash
cd /Users/jairconislla/Projects/cuycash
flutter create --org pe.cuycash --project-name cuycash \
  --platforms=android,ios apps/mobile
```

- [ ] **Step 2: Crear el `pubspec.yaml` root (workspace)**

```yaml
name: cuycash_workspace
description: Monorepo de CuyCash (app móvil + paquetes compartidos).
publish_to: none

environment:
  sdk: ^3.8.0

workspace:
  - apps/mobile
  - packages/core_kernel
  - packages/design_system
```

- [ ] **Step 3: Crear `packages/core_kernel/pubspec.yaml`**

```yaml
name: core_kernel
description: Kernel puro de CuyCash (Result/Either, GlobalFailure, ExceptionMapper, ids).
publish_to: none
resolution: workspace

environment:
  sdk: ^3.8.0

dependencies:
  fpdart: ^1.1.0

dev_dependencies:
  test: ^1.25.0
  flutter_lints: ^6.0.0
```

Crear `packages/core_kernel/lib/core_kernel.dart` con `library;` y sin exports aún (se agregan en Task 2).

- [ ] **Step 4: Crear `packages/design_system/pubspec.yaml`**

```yaml
name: design_system
description: Sistema visual "Eucalipto y Ocre" de CuyCash (tokens, theme, componentes).
publish_to: none
resolution: workspace

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
```

Crear `packages/design_system/lib/design_system.dart` con `library;`.

- [ ] **Step 5: Reemplazar `apps/mobile/pubspec.yaml`**

```yaml
name: cuycash
description: CuyCash — app móvil (banca digital · Perú).
publish_to: none
resolution: workspace
version: 0.1.0+1

environment:
  sdk: ^3.8.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  flutter_bloc: ^8.1.6
  go_router: ^14.0.0
  fpdart: ^1.1.0
  freezed_annotation: ^3.0.0
  shared_preferences: ^2.3.0
  supabase_flutter: ^2.8.0
  core_kernel:
    path: ../../packages/core_kernel
  design_system:
    path: ../../packages/design_system

dev_dependencies:
  bloc_test: ^9.1.7
  build_runner: ^2.4.15
  freezed: ^3.0.0
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 6: Crear `analysis_options.yaml` root**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
```

- [ ] **Step 7: Crear `.gitignore` root**

```gitignore
# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
*.iml

# Config con credenciales (solo la plantilla se commitea)
apps/mobile/config.local.json
apps/mobile/config.production.json

# OS
.DS_Store
```

- [ ] **Step 8: Resolver y verificar**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter pub get`
Expected: resuelve sin errores el workspace completo.

Run: `flutter analyze`
Expected: `No issues found!` (o solo el `main.dart` autogenerado — se reemplaza en Task 15).

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "chore: scaffolding del monorepo (apps/mobile + packages)"
```

---

## Task 2: `core_kernel` — Result, GlobalFailure, ExceptionMapper, ids

**Files:**
- Create: `packages/core_kernel/lib/src/failures/global_failure.dart`
- Create: `packages/core_kernel/lib/src/failures/exception_mapper.dart`
- Create: `packages/core_kernel/lib/src/result.dart`
- Create: `packages/core_kernel/lib/src/ids.dart`
- Modify: `packages/core_kernel/lib/core_kernel.dart`
- Test: `packages/core_kernel/test/exception_mapper_test.dart`

**Interfaces:**
- Produces:
  - `typedef Result<F,T> = Either<GlobalFailure<F>,T>` y `typedef FutureResult<F,T> = Future<Result<F,T>>`.
  - `sealed class GlobalFailure<F>` con `NoConnection`, `Timeout`, `PermissionDenied`, `NotFound`, `StorageFailure`, `ServerFailure<F>(F failure)`, `Unexpected`.
  - `abstract final class ExceptionMapper` con `static GlobalFailure<F> map<F>(Object, StackTrace)`, `register(FailureClassifier)`, `reset()`.
  - `enum FailureKind { noConnection, timeout, permissionDenied, notFound, storage }`, `typedef Classified`, `typedef FailureClassifier`.

- [ ] **Step 1: Escribir `global_failure.dart`**

```dart
/// Error como valor, de la frontera al pixel.
///
/// `F` es el failure de negocio por feature (`AuthFailure`, …), sealed y
/// definido en el domain de cada feature. PROHIBIDO aplanar a string o
/// `catch (_) {}`: el consumo es por `switch` exhaustivo.
sealed class GlobalFailure<F> {
  const GlobalFailure();

  const factory GlobalFailure.noConnection() = NoConnection<F>;
  const factory GlobalFailure.timeout() = Timeout<F>;
  const factory GlobalFailure.permissionDenied(String? hint) = PermissionDenied<F>;
  const factory GlobalFailure.notFound() = NotFound<F>;
  const factory GlobalFailure.storage(String message) = StorageFailure<F>;
  const factory GlobalFailure.server(F failure) = ServerFailure<F>;
  const factory GlobalFailure.unexpected(Object error, StackTrace stackTrace) =
      Unexpected<F>;
}

final class NoConnection<F> extends GlobalFailure<F> {
  const NoConnection();
}

final class Timeout<F> extends GlobalFailure<F> {
  const Timeout();
}

final class PermissionDenied<F> extends GlobalFailure<F> {
  const PermissionDenied(this.hint);
  final String? hint;
}

final class NotFound<F> extends GlobalFailure<F> {
  const NotFound();
}

final class StorageFailure<F> extends GlobalFailure<F> {
  const StorageFailure(this.message);
  final String message;
}

final class ServerFailure<F> extends GlobalFailure<F> {
  const ServerFailure(this.failure);
  final F failure;
}

final class Unexpected<F> extends GlobalFailure<F> {
  const Unexpected(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
```

- [ ] **Step 2: Escribir `exception_mapper.dart`**

```dart
import 'dart:async';

import 'global_failure.dart';

/// Clasificación transportable de una excepción de infraestructura.
enum FailureKind { noConnection, timeout, permissionDenied, notFound, storage }

typedef Classified = ({FailureKind kind, String? detail});

/// Clasificador adicional registrado por una capa de infraestructura.
/// Devuelve null si no reconoce el error.
typedef FailureClassifier = Classified? Function(Object error);

/// El mapper ÚNICO de excepción → failure. core_kernel no depende de SDKs;
/// los clasificadores específicos se REGISTRAN desde el bootstrap de la app.
abstract final class ExceptionMapper {
  static final List<FailureClassifier> _classifiers = [];

  static void register(FailureClassifier classifier) =>
      _classifiers.add(classifier);

  /// Solo para tests.
  static void reset() => _classifiers.clear();

  static GlobalFailure<F> map<F>(Object error, StackTrace stackTrace) {
    if (error is TimeoutException) return GlobalFailure<F>.timeout();
    for (final classify in _classifiers) {
      final classified = classify(error);
      if (classified == null) continue;
      return switch (classified.kind) {
        FailureKind.noConnection => GlobalFailure<F>.noConnection(),
        FailureKind.timeout => GlobalFailure<F>.timeout(),
        FailureKind.permissionDenied =>
          GlobalFailure<F>.permissionDenied(classified.detail),
        FailureKind.notFound => GlobalFailure<F>.notFound(),
        FailureKind.storage => GlobalFailure<F>.storage(classified.detail ?? ''),
      };
    }
    return GlobalFailure<F>.unexpected(error, stackTrace);
  }
}
```

- [ ] **Step 3: Escribir `result.dart`**

```dart
import 'package:fpdart/fpdart.dart';

import 'failures/global_failure.dart';

/// Typedefs de resultado: las firmas de los contratos de domain devuelven
/// estos tipos, nunca lanzan.
typedef Result<F, T> = Either<GlobalFailure<F>, T>;
typedef FutureResult<F, T> = Future<Result<F, T>>;
typedef StreamResult<F, T> = Stream<Result<F, T>>;
```

- [ ] **Step 4: Escribir `ids.dart`**

```dart
/// Id de usuario (extension type sobre String — cero costo en runtime, tipado
/// en compile-time).
extension type const UserId(String value) {}
```

- [ ] **Step 5: Actualizar `core_kernel.dart`**

```dart
/// Kernel mínimo de CuyCash (errores como valores).
library;

export 'src/failures/exception_mapper.dart';
export 'src/failures/global_failure.dart';
export 'src/ids.dart';
export 'src/result.dart';
```

- [ ] **Step 6: Escribir el test de `ExceptionMapper`**

`packages/core_kernel/test/exception_mapper_test.dart`:

```dart
import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  setUp(ExceptionMapper.reset);
  tearDown(ExceptionMapper.reset);

  test('TimeoutException → Timeout sin clasificadores', () {
    final failure = ExceptionMapper.map<String>(
      TimeoutException('x'),
      StackTrace.current,
    );
    expect(failure, isA<Timeout<String>>());
  });

  test('error desconocido → Unexpected', () {
    final failure = ExceptionMapper.map<String>(
      StateError('boom'),
      StackTrace.current,
    );
    expect(failure, isA<Unexpected<String>>());
  });

  test('clasificador registrado mapea a su FailureKind', () {
    ExceptionMapper.register(
      (error) => error is FormatException
          ? (kind: FailureKind.permissionDenied, detail: 'rls')
          : null,
    );
    final failure = ExceptionMapper.map<String>(
      const FormatException(),
      StackTrace.current,
    );
    expect(failure, isA<PermissionDenied<String>>());
    expect((failure as PermissionDenied<String>).hint, 'rls');
  });
}
```

- [ ] **Step 7: Correr el test**

Run: `cd packages/core_kernel && dart test`
Expected: 3 tests PASS.

- [ ] **Step 8: Commit**

```bash
git add packages/core_kernel
git commit -m "feat: core_kernel (Result, GlobalFailure, ExceptionMapper, ids)"
```

---

## Task 3: `design_system` — tokens y theme

**Files:**
- Create: `packages/design_system/lib/src/cuycash_colors.dart`
- Create: `packages/design_system/lib/src/cuycash_typography.dart`
- Create: `packages/design_system/lib/src/cuycash_spacing.dart`
- Create: `packages/design_system/lib/src/cuycash_theme.dart`
- Modify: `packages/design_system/lib/design_system.dart`
- Test: `packages/design_system/test/cuycash_theme_test.dart`

**Interfaces:**
- Produces: `CuyCashColors` (tokens `Color`), `CuyCashTypography` (`TextStyle`), `CuyCashSpacing`/`CuyCashRadii` (`double`), `CuyCashTheme.light()` → `ThemeData`.

- [ ] **Step 1: Escribir `cuycash_colors.dart`** (tokens del DESIGN.md)

```dart
import 'package:flutter/material.dart';

/// Tokens de color "Eucalipto y Ocre" (DESIGN.md). Regla dura: TODA superficie
/// usa estos tokens; prohibido hex suelto en widgets.
abstract final class CuyCashColors {
  // Marca
  static const primary = Color(0xFF152A1F);          // Eucalipto profundo
  static const primaryContainer = Color(0xFF2B4034); // Eucalipto
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFD98C2B);        // Ocre (fills/acentos)
  static const accentText = Color(0xFF9B5F12);       // Ocre oscuro (texto legible)

  // Superficies
  static const surface = Color(0xFFFBF9F4);                 // Stone (fondo app)
  static const surfaceContainerLowest = Color(0xFFFFFFFF);  // Cards
  static const surfaceContainerLow = Color(0xFFF5F3EE);
  static const surfaceContainer = Color(0xFFF0EEE9);
  static const surfaceContainerHigh = Color(0xFFEAE8E3);
  static const surfaceContainerHighest = Color(0xFFE4E2DD);

  // Texto / bordes
  static const onSurface = Color(0xFF1B1C19);
  static const secondaryText = Color(0xFF6B7268);   // Sage muted
  static const outline = Color(0xFF737873);
  static const outlineVariant = Color(0xFFC2C8C2);
  static const divider = Color(0xFFEBE8E0);

  // Estados
  static const error = Color(0xFFB31D3F);           // Carmín
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);

  // Sombra ambiental verde de cards
  static const ambientShadow = Color(0x0D2B4034);   // rgba(43,64,52,0.05)
}
```

- [ ] **Step 2: Escribir `cuycash_typography.dart`** (escala Inter del DESIGN.md)

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Escala tipográfica (DESIGN.md). Inter cuando esté en assets; hasta entonces
/// `fontFamily` = null (cae al system font). Un solo lugar para activar Inter.
abstract final class CuyCashTypography {
  static const _family = null; // 'Inter' cuando el .ttf esté en assets/fonts/

  static const displayLg = TextStyle(
    fontFamily: _family, fontSize: 36, fontWeight: FontWeight.w700,
    height: 44 / 36, letterSpacing: -0.72, color: CuyCashColors.onSurface,
  );
  static const headlineLgMobile = TextStyle(
    fontFamily: _family, fontSize: 30, fontWeight: FontWeight.w700,
    height: 38 / 30, color: CuyCashColors.onSurface,
  );
  static const headlineMd = TextStyle(
    fontFamily: _family, fontSize: 28, fontWeight: FontWeight.w700,
    height: 36 / 28, letterSpacing: -0.28, color: CuyCashColors.onSurface,
  );
  static const headlineSm = TextStyle(
    fontFamily: _family, fontSize: 24, fontWeight: FontWeight.w600,
    height: 32 / 24, color: CuyCashColors.onSurface,
  );
  static const titleMd = TextStyle(
    fontFamily: _family, fontSize: 20, fontWeight: FontWeight.w600,
    height: 28 / 20, color: CuyCashColors.onSurface,
  );
  static const bodyLg = TextStyle(
    fontFamily: _family, fontSize: 16, fontWeight: FontWeight.w400,
    height: 24 / 16, color: CuyCashColors.onSurface,
  );
  static const bodyMd = TextStyle(
    fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w400,
    height: 20 / 14, color: CuyCashColors.secondaryText,
  );
  static const labelMd = TextStyle(
    fontFamily: _family, fontSize: 14, fontWeight: FontWeight.w600,
    height: 20 / 14, letterSpacing: 0.14, color: CuyCashColors.primary,
  );
  static const labelSm = TextStyle(
    fontFamily: _family, fontSize: 12, fontWeight: FontWeight.w500,
    height: 16 / 12, color: CuyCashColors.secondaryText,
  );
}
```

- [ ] **Step 3: Escribir `cuycash_spacing.dart`**

```dart
/// Ritmo 4px y radios (DESIGN.md).
abstract final class CuyCashSpacing {
  static const unit = 4.0;
  static const marginMobile = 16.0;
  static const containerPadding = 20.0;
  static const stackXs = 4.0;
  static const stackSm = 8.0;
  static const stackMd = 16.0;
  static const stackLg = 24.0;
  static const stackXl = 48.0;
}

abstract final class CuyCashRadii {
  static const sm = 8.0;
  static const button = 12.0;
  static const input = 12.0;
  static const card = 14.0;
  static const full = 9999.0;
}
```

- [ ] **Step 4: Escribir `cuycash_theme.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Tema de CuyCash construido SOLO desde tokens (DESIGN.md).
abstract final class CuyCashTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: CuyCashColors.primary,
      onPrimary: CuyCashColors.onPrimary,
      secondary: CuyCashColors.secondary,
      surface: CuyCashColors.surface,
      onSurface: CuyCashColors.onSurface,
      error: CuyCashColors.error,
      onError: CuyCashColors.onError,
      outline: CuyCashColors.outline,
      outlineVariant: CuyCashColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: CuyCashColors.surface,
      dividerColor: CuyCashColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: CuyCashColors.surface,
        foregroundColor: CuyCashColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: CuyCashTypography.titleMd,
      ),
      cardTheme: CardThemeData(
        color: CuyCashColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.card),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CuyCashColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.input),
          borderSide: const BorderSide(color: CuyCashColors.primary, width: 2),
        ),
        hintStyle: CuyCashTypography.bodyLg
            .copyWith(color: CuyCashColors.secondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CuyCashColors.primaryContainer,
          foregroundColor: CuyCashColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: CuyCashTypography.labelMd
              .copyWith(color: CuyCashColors.onPrimary, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CuyCashRadii.button),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: CuyCashTypography.displayLg,
        headlineMedium: CuyCashTypography.headlineMd,
        titleMedium: CuyCashTypography.titleMd,
        bodyLarge: CuyCashTypography.bodyLg,
        bodyMedium: CuyCashTypography.bodyMd,
        labelMedium: CuyCashTypography.labelMd,
      ),
    );
  }
}
```

- [ ] **Step 5: Actualizar `design_system.dart`**

```dart
/// Sistema visual "Eucalipto y Ocre" de CuyCash.
library;

export 'src/cuycash_colors.dart';
export 'src/cuycash_spacing.dart';
export 'src/cuycash_theme.dart';
export 'src/cuycash_typography.dart';
```

- [ ] **Step 6: Escribir el test de theme**

`packages/design_system/test/cuycash_theme_test.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light() usa los tokens de marca', () {
    final theme = CuyCashTheme.light();
    expect(theme.colorScheme.primary, CuyCashColors.primary);
    expect(theme.scaffoldBackgroundColor, CuyCashColors.surface);
    expect(theme.useMaterial3, isTrue);
  });

  test('botón primario tiene alto mínimo 52', () {
    final theme = CuyCashTheme.light();
    final size = theme.elevatedButtonTheme.style!.minimumSize!
        .resolve({});
    expect(size!.height, 52);
  });
}
```

- [ ] **Step 7: Correr el test**

Run: `cd packages/design_system && flutter test`
Expected: 2 tests PASS.

- [ ] **Step 8: Commit**

```bash
git add packages/design_system
git commit -m "feat: design_system tokens y theme (Eucalipto y Ocre)"
```

---

## Task 4: `design_system` — componentes UI

**Files:**
- Create: `packages/design_system/lib/src/primary_button.dart`
- Create: `packages/design_system/lib/src/secondary_button.dart`
- Create: `packages/design_system/lib/src/ghost_button.dart`
- Create: `packages/design_system/lib/src/cuycash_text_field.dart`
- Create: `packages/design_system/lib/src/page_dots_indicator.dart`
- Create: `packages/design_system/lib/src/brand_mark.dart`
- Modify: `packages/design_system/lib/design_system.dart`
- Test: `packages/design_system/test/components_test.dart`

**Interfaces:**
- Produces:
  - `PrimaryButton({required String label, VoidCallback? onPressed, bool loading})`
  - `SecondaryButton({required String label, VoidCallback? onPressed})`
  - `GhostButton({required String label, VoidCallback? onPressed})`
  - `CuyCashTextField({required String label, String? hint, TextEditingController? controller, bool obscure, TextInputType? keyboardType, String? errorText, ValueChanged<String>? onChanged})`
  - `PageDotsIndicator({required int count, required int activeIndex})`
  - `BrandMark({double size})`

- [ ] **Step 1: `primary_button.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Botón primario (Eucalipto, alto 52). Muestra spinner si [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CuyCashColors.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}
```

- [ ] **Step 2: `secondary_button.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';

/// Botón secundario (borde Eucalipto 1.5px, texto Eucalipto).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CuyCashColors.primary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: CuyCashColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CuyCashRadii.button),
        ),
      ),
      child: Text(label),
    );
  }
}
```

- [ ] **Step 3: `ghost_button.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Botón ghost (solo texto Eucalipto, sin fondo).
class GhostButton extends StatelessWidget {
  const GhostButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: CuyCashColors.primary),
      child: Text(label),
    );
  }
}
```

- [ ] **Step 4: `cuycash_text_field.dart`** (label persistente arriba)

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Input con label persistente arriba (DESIGN.md). Errores en carmín.
class CuyCashTextField extends StatelessWidget {
  const CuyCashTextField({
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CuyCashTypography.labelMd),
        const SizedBox(height: CuyCashSpacing.stackSm),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: `page_dots_indicator.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Dots del onboarding: el activo se alarga (barra Eucalipto).
class PageDotsIndicator extends StatelessWidget {
  const PageDotsIndicator({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: active ? 24 : 6,
          decoration: BoxDecoration(
            color: active
                ? CuyCashColors.primary
                : CuyCashColors.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 6: `brand_mark.dart`** (placeholder del logo "CC")

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Logo placeholder "CC" (dos anillos entrelazados eucalipto/ocre). Se
/// reemplaza por el asset vectorial final cuando esté disponible.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _Ring(size: size * 0.7, color: CuyCashColors.surface),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _Ring(size: size * 0.7, color: CuyCashColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: size * 0.14),
      ),
    );
  }
}
```

- [ ] **Step 7: Actualizar `design_system.dart`** (añadir exports)

```dart
export 'src/brand_mark.dart';
export 'src/cuycash_text_field.dart';
export 'src/ghost_button.dart';
export 'src/page_dots_indicator.dart';
export 'src/primary_button.dart';
export 'src/secondary_button.dart';
```

- [ ] **Step 8: Test de componentes**

`packages/design_system/test/components_test.dart`:

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: CuyCashTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('PrimaryButton muestra label y dispara onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PrimaryButton(label: 'Ingresar', onPressed: () => tapped = true),
    ));
    expect(find.text('Ingresar'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton loading oculta el label y deshabilita', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      PrimaryButton(label: 'Ingresar', loading: true, onPressed: () => tapped = true),
    ));
    expect(find.text('Ingresar'), findsNothing);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isFalse);
  });

  testWidgets('CuyCashTextField muestra label y errorText', (tester) async {
    await tester.pumpWidget(_wrap(
      const CuyCashTextField(label: 'DNI o Alias', errorText: 'Requerido'),
    ));
    expect(find.text('DNI o Alias'), findsOneWidget);
    expect(find.text('Requerido'), findsOneWidget);
  });

  testWidgets('PageDotsIndicator renderiza count dots', (tester) async {
    await tester.pumpWidget(_wrap(
      const PageDotsIndicator(count: 3, activeIndex: 1),
    ));
    expect(find.byType(AnimatedContainer), findsNWidgets(3));
  });
}
```

- [ ] **Step 9: Correr tests**

Run: `cd packages/design_system && flutter test`
Expected: 6 tests PASS (2 de theme + 4 de componentes).

- [ ] **Step 10: Commit**

```bash
git add packages/design_system
git commit -m "feat: componentes design_system (botones, input, dots, brand)"
```

---

## Task 5: Feature `auth` — domain

**Files:**
- Create: `apps/mobile/lib/feature/auth/domain/auth_session.dart`
- Create: `apps/mobile/lib/feature/auth/domain/auth_failure.dart`
- Create: `apps/mobile/lib/feature/auth/domain/auth_repository.dart`

**Interfaces:**
- Produces:
  - `class AuthSession { final String userId; final String identifier; final String? alias; }` con `==`/`hashCode`.
  - `sealed class AuthFailure` con factories `invalidCredentials()`, `identifierTaken()`, `weakPin()`, `authUnavailable()` y subclases `InvalidCredentials`, `IdentifierTaken`, `WeakPin`, `AuthUnavailable`.
  - `abstract interface class AuthRepository` con `currentSession`, `sessionChanges()`, `signIn({identifier, pin})`, `register({dni, alias, pin})`, `signOut()`.

- [ ] **Step 1: `auth_session.dart`**

```dart
/// Sesión autenticada.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.identifier,
    this.alias,
  });

  final String userId;
  final String identifier; // DNI o alias con el que inició sesión
  final String? alias;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.identifier == identifier &&
      other.alias == alias;

  @override
  int get hashCode => Object.hash(userId, identifier, alias);
}
```

- [ ] **Step 2: `auth_failure.dart`**

```dart
/// Failures de auth (viajan en `GlobalFailure.server`). Construcción por factory
/// nombrado; pattern matching por subclase.
sealed class AuthFailure {
  const AuthFailure();

  const factory AuthFailure.invalidCredentials() = InvalidCredentials;
  const factory AuthFailure.identifierTaken() = IdentifierTaken;
  const factory AuthFailure.weakPin() = WeakPin;
  const factory AuthFailure.authUnavailable() = AuthUnavailable;
}

/// DNI/Alias o PIN incorrectos.
final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

/// El DNI ya está registrado.
final class IdentifierTaken extends AuthFailure {
  const IdentifierTaken();
}

/// El PIN no cumple el formato (4 dígitos).
final class WeakPin extends AuthFailure {
  const WeakPin();
}

/// No se pudo contactar al proveedor de auth (sin backend real aún).
final class AuthUnavailable extends AuthFailure {
  const AuthUnavailable();
}
```

- [ ] **Step 3: `auth_repository.dart`**

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import 'auth_failure.dart';
import 'auth_session.dart';

/// Contrato de auth (domain). Nunca lanza: devuelve `Result`. Impl real =
/// Supabase (local/prod); su `Memory*` funcional vive en infrastructure.
abstract interface class AuthRepository {
  /// Sesión actual cacheada (sincrónica), o null.
  AuthSession? get currentSession;

  /// Emite la sesión vigente ante cambios (login/register/logout).
  Stream<AuthSession?> sessionChanges();

  /// Inicia sesión con DNI/Alias + PIN.
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  });

  /// Registra una cuenta nueva (DNI + PIN, alias opcional).
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    String? alias,
    required String pin,
  });

  FutureResult<AuthFailure, Unit> signOut();
}
```

- [ ] **Step 4: Verificar análisis**

Run: `cd apps/mobile && flutter analyze lib/feature/auth/domain`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/feature/auth/domain
git commit -m "feat: auth domain (session, failure, repository)"
```

---

## Task 6: Feature `auth` — infrastructure (MemoryAuthRepository, TDD)

**Files:**
- Create: `apps/mobile/lib/feature/auth/infrastructure/memory_auth_repository.dart`
- Test: `apps/mobile/test/feature/auth/memory_auth_repository_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `AuthSession`, `AuthFailure`, `FutureResult`, `GlobalFailure`.
- Produces: `class MemoryAuthRepository implements AuthRepository { MemoryAuthRepository({AuthSession? initial, String validPin = '0000'}); }`.

- [ ] **Step 1: Escribir el test primero (falla)**

`apps/mobile/test/feature/auth/memory_auth_repository_test.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signIn con PIN válido → sesión y la emite por el stream', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);

    final result = await repo.signIn(identifier: '12345678', pin: '0000');

    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isA<AuthSession>());
  });

  test('signIn con PIN inválido → InvalidCredentials', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.signIn(identifier: '12345678', pin: '9999');

    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<InvalidCredentials>()),
    );
    expect(repo.currentSession, isNull);
  });

  test('register nuevo DNI → sesión', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(dni: '87654321', pin: '0000');
    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
  });

  test('register con PIN de menos de 4 dígitos → WeakPin', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(dni: '87654321', pin: '12');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<WeakPin>()),
    );
  });

  test('register con DNI ya registrado → IdentifierTaken', () async {
    final repo = MemoryAuthRepository();
    await repo.register(dni: '87654321', pin: '0000');
    await repo.signOut();
    final result = await repo.register(dni: '87654321', pin: '0000');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<IdentifierTaken>()),
    );
  });

  test('signOut → sesión null y lo emite', () async {
    final repo = MemoryAuthRepository(
      initial: const AuthSession(userId: 'u', identifier: '12345678'),
    );
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);

    final result = await repo.signOut();

    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isNull);
  });
}
```

- [ ] **Step 2: Correr el test (debe fallar por clase inexistente)**

Run: `cd apps/mobile && flutter test test/feature/auth/memory_auth_repository_test.dart`
Expected: FAIL — `MemoryAuthRepository` no existe.

- [ ] **Step 3: Implementar `MemoryAuthRepository`**

```dart
import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Memory* FUNCIONAL de auth (backend del flavor `mock` + contrato de tests).
/// [validPin] (default '0000') es el PIN que se acepta.
class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({AuthSession? initial, this.validPin = '0000'})
      : _session = initial {
    if (initial != null) _registered.add(initial.identifier);
  }

  final String validPin;
  AuthSession? _session;
  final Set<String> _registered = {};
  final _controller = StreamController<AuthSession?>.broadcast();

  static final _pinFormat = RegExp(r'^\d{4}$');

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> sessionChanges() => _controller.stream;

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async {
    if (pin != validPin) {
      return left(const GlobalFailure.server(AuthFailure.invalidCredentials()));
    }
    final session =
        AuthSession(userId: 'mem-${identifier.hashCode}', identifier: identifier);
    _emit(session);
    return right(session);
  }

  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    String? alias,
    required String pin,
  }) async {
    if (!_pinFormat.hasMatch(pin)) {
      return left(const GlobalFailure.server(AuthFailure.weakPin()));
    }
    if (_registered.contains(dni)) {
      return left(const GlobalFailure.server(AuthFailure.identifierTaken()));
    }
    _registered.add(dni);
    final session =
        AuthSession(userId: 'mem-${dni.hashCode}', identifier: dni, alias: alias);
    _emit(session);
    return right(session);
  }

  @override
  FutureResult<AuthFailure, Unit> signOut() async {
    _session = null;
    _controller.add(null);
    return right(unit);
  }

  void _emit(AuthSession session) {
    _session = session;
    _controller.add(session);
  }
}
```

- [ ] **Step 4: Correr el test (debe pasar)**

Run: `cd apps/mobile && flutter test test/feature/auth/memory_auth_repository_test.dart`
Expected: 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/feature/auth/infrastructure/memory_auth_repository.dart apps/mobile/test/feature/auth
git commit -m "feat: MemoryAuthRepository funcional + tests de contrato"
```

---

## Task 7: Feature `auth` — application (AuthActions)

**Files:**
- Create: `apps/mobile/lib/feature/auth/application/auth_actions.dart`

**Interfaces:**
- Consumes: `AuthRepository`.
- Produces: `class AuthActions { const AuthActions(AuthRepository); AuthSession? get currentSession; Stream<AuthSession?> sessionChanges(); signIn({identifier,pin}); register({dni,alias,pin}); signOut(); }`.

- [ ] **Step 1: Escribir `auth_actions.dart`**

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Agrupa las operaciones FINAS de auth (delegación directa sobre una sola
/// dependencia: el `AuthRepository`). El bloc la consume por constructor; nunca
/// toca el repo directo. Cuando una operación pase a orquestar 2+ dependencias,
/// sale a su propio `*_use_case.dart`.
class AuthActions {
  const AuthActions(this._repo);

  final AuthRepository _repo;

  AuthSession? get currentSession => _repo.currentSession;

  Stream<AuthSession?> sessionChanges() => _repo.sessionChanges();

  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) =>
      _repo.signIn(identifier: identifier, pin: pin);

  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    String? alias,
    required String pin,
  }) =>
      _repo.register(dni: dni, alias: alias, pin: pin);

  FutureResult<AuthFailure, Unit> signOut() => _repo.signOut();
}
```

- [ ] **Step 2: Verificar análisis**

Run: `cd apps/mobile && flutter analyze lib/feature/auth`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/feature/auth/application
git commit -m "feat: AuthActions (capa de aplicación de auth)"
```

---

## Task 8: Feature `auth` — AuthBloc (freezed + bloc_test)

**Files:**
- Create: `apps/mobile/lib/presentation/auth/bloc/auth_bloc.dart`
- Create: `apps/mobile/lib/presentation/auth/bloc/auth_event.dart`
- Create: `apps/mobile/lib/presentation/auth/bloc/auth_state.dart`
- Generated: `apps/mobile/lib/presentation/auth/bloc/auth_bloc.freezed.dart`
- Test: `apps/mobile/test/presentation/auth/auth_bloc_test.dart`

**Interfaces:**
- Consumes: `AuthActions`, `AuthSession`, `AuthFailure`, `GlobalFailure`.
- Produces:
  - `enum FormStatus { idle, submitting }`, `enum AuthError { invalidCredentials, identifierTaken, weakPin, generic }`.
  - `sealed AuthState`: `AuthUnauthenticated({FormStatus status, AuthError? error})` (=`AuthUnauthenticated`), `AuthAuthenticated(AuthSession session)` (=`AuthAuthenticated`).
  - `sealed AuthEvent`: `AuthLoginSubmitted(String identifier, String pin)`, `AuthRegisterSubmitted(String dni, String? alias, String pin)`, `AuthSignedOut()`, `_AuthSessionChanged(AuthSession? session)` (factory `AuthEvent.sessionChanged`).
  - `class AuthBloc extends Bloc<AuthEvent, AuthState> { AuthBloc(AuthActions); }`.

- [ ] **Step 1: Escribir `auth_event.dart`**

```dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginSubmitted({
    required String identifier,
    required String pin,
  }) = AuthLoginSubmitted;

  const factory AuthEvent.registerSubmitted({
    required String dni,
    String? alias,
    required String pin,
  }) = AuthRegisterSubmitted;

  const factory AuthEvent.signedOut() = AuthSignedOut;

  const factory AuthEvent.sessionChanged(AuthSession? session) =
      _AuthSessionChanged;
}
```

- [ ] **Step 2: Escribir `auth_state.dart`**

```dart
part of 'auth_bloc.dart';

/// Progreso del form de auth.
enum FormStatus { idle, submitting }

/// Tipo de error de auth. El bloc no carga texto: la UI traduce con ARB
/// (ver `auth_error_text.dart`).
enum AuthError { invalidCredentials, identifierTaken, weakPin, generic }

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unauthenticated({
    @Default(FormStatus.idle) FormStatus status,
    AuthError? error,
  }) = AuthUnauthenticated;

  const factory AuthState.authenticated(AuthSession session) = AuthAuthenticated;
}
```

- [ ] **Step 3: Escribir `auth_bloc.dart`**

```dart
import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../../feature/auth/domain/auth_session.dart';

part 'auth_bloc.freezed.dart';
part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc de auth. Consume `AuthActions` por constructor — nunca el repo directo.
/// Estado inicial sincrónico desde `currentSession`; se mueve con el stream. En
/// éxito de login/register NO emite directo: la sesión llega por el stream →
/// `AuthAuthenticated`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthActions actions)
      : _actions = actions,
        super(_resolve(actions.currentSession)) {
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthSignedOut>((event, emit) => _actions.signOut());
    on<_AuthSessionChanged>((event, emit) => emit(_resolve(event.session)));
    _sub = _actions.sessionChanges().listen(
          (session) => add(AuthEvent.sessionChanged(session)),
        );
  }

  final AuthActions _actions;
  late final StreamSubscription<AuthSession?> _sub;

  static AuthState _resolve(AuthSession? session) => session == null
      ? const AuthState.unauthenticated()
      : AuthState.authenticated(session);

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated(status: FormStatus.submitting));
    final result =
        await _actions.signIn(identifier: event.identifier, pin: event.pin);
    result.match(
      (failure) => emit(AuthState.unauthenticated(error: _errorFor(failure))),
      (_) {}, // éxito → sessionChanged por el stream
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated(status: FormStatus.submitting));
    final result = await _actions.register(
        dni: event.dni, alias: event.alias, pin: event.pin);
    result.match(
      (failure) => emit(AuthState.unauthenticated(error: _errorFor(failure))),
      (_) {}, // éxito → sessionChanged por el stream
    );
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}

/// Mapea el `AuthFailure` a `AuthError` (sin texto; la UI lo traduce).
AuthError _errorFor(GlobalFailure<AuthFailure> failure) => switch (failure) {
      ServerFailure(failure: InvalidCredentials()) =>
        AuthError.invalidCredentials,
      ServerFailure(failure: IdentifierTaken()) => AuthError.identifierTaken,
      ServerFailure(failure: WeakPin()) => AuthError.weakPin,
      _ => AuthError.generic,
    };
```

- [ ] **Step 4: Generar el código freezed**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: genera `auth_bloc.freezed.dart` sin errores.

- [ ] **Step 5: Escribir el test del bloc**

`apps/mobile/test/presentation/auth/auth_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

AuthBloc buildBloc(MemoryAuthRepository repo) => AuthBloc(AuthActions(repo));

void main() {
  const session = AuthSession(userId: 'u', identifier: '12345678');

  test('estado inicial sin sesión → AuthUnauthenticated', () {
    final bloc = buildBloc(MemoryAuthRepository());
    expect(bloc.state, isA<AuthUnauthenticated>());
    bloc.close();
  });

  test('estado inicial con sesión → AuthAuthenticated', () {
    final bloc = buildBloc(MemoryAuthRepository(initial: session));
    expect(bloc.state, isA<AuthAuthenticated>());
    bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'login correcto → submitting, luego AuthAuthenticated (vía stream)',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc.add(
        const AuthEvent.loginSubmitted(identifier: '12345678', pin: '0000')),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>(), isA<AuthAuthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'login incorrecto → submitting, luego error (sigue Unauthenticated)',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc.add(
        const AuthEvent.loginSubmitted(identifier: '12345678', pin: '9999')),
    expect: () => [
      isA<AuthUnauthenticated>(),
      isA<AuthUnauthenticated>()
          .having((s) => s.error, 'error', AuthError.invalidCredentials),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'register correcto → AuthAuthenticated',
    build: () => buildBloc(MemoryAuthRepository()),
    act: (bloc) => bloc
        .add(const AuthEvent.registerSubmitted(dni: '87654321', pin: '0000')),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>(), isA<AuthAuthenticated>()],
  );

  blocTest<AuthBloc, AuthState>(
    'signOut → AuthUnauthenticated',
    build: () => buildBloc(MemoryAuthRepository(initial: session)),
    act: (bloc) => bloc.add(const AuthEvent.signedOut()),
    wait: const Duration(milliseconds: 10),
    expect: () => [isA<AuthUnauthenticated>()],
  );
}
```

- [ ] **Step 6: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/auth/auth_bloc_test.dart`
Expected: 6 tests PASS.

- [ ] **Step 7: Commit** (incluye el `.freezed.dart`)

```bash
git add apps/mobile/lib/presentation/auth/bloc apps/mobile/test/presentation/auth/auth_bloc_test.dart
git commit -m "feat: AuthBloc (login/register/signOut) + bloc_test"
```

---

## Task 9: Env, flavors e inyección

**Files:**
- Create: `apps/mobile/lib/core/env/app_flavor.dart`
- Create: `apps/mobile/lib/core/env/app_env.dart`
- Create: `apps/mobile/lib/core/injection/app_dependencies.dart`
- Create: `apps/mobile/lib/core/injection/modules/auth_module.dart`
- Create: `apps/mobile/lib/feature/auth/infrastructure/supabase_auth_repository.dart`
- Create: `apps/mobile/lib/core/injection/envs/mock_dependencies.dart`
- Create: `apps/mobile/lib/core/injection/envs/shared/shared_supabase_dependencies.dart`
- Create: `apps/mobile/lib/core/injection/envs/local_dependencies.dart`
- Create: `apps/mobile/lib/core/injection/envs/production_dependencies.dart`
- Create: `apps/mobile/config.{mock,local,production,example}.json`
- Test: `apps/mobile/test/core/injection/mock_dependencies_test.dart`

**Interfaces:**
- Consumes: `AuthRepository`, `MemoryAuthRepository`, `AuthActions`, `AuthBloc`.
- Produces:
  - `enum AppFlavor { mock, local, production }`.
  - `abstract final class AppEnv { static String get supabaseUrl; static String get supabaseAnonKey; static void validate(); }`.
  - `class AppDependencies { const AppDependencies({required AppFlavor flavor, required AuthRepository authRepository}); }`.
  - `abstract final class AuthModule { static List<BlocProvider<AuthBloc>> blocProviders(AppDependencies); }`.
  - `class SupabaseAuthRepository implements AuthRepository`.
  - `Future<AppDependencies> buildMockDependencies()`, `buildLocalDependencies()`, `buildProductionDependencies()`.

- [ ] **Step 1: `app_flavor.dart`**

```dart
/// Flavors de CuyCash. `mock` = repos en memoria; `local`/`production` =
/// Supabase (mismo código, distinta config).
enum AppFlavor { mock, local, production }
```

- [ ] **Step 2: `app_env.dart`**

```dart
/// Config de entorno leída de `--dart-define` (via `--dart-define-from-file`).
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Valida que existan credenciales (solo flavors local/production).
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Faltan SUPABASE_URL / SUPABASE_ANON_KEY. Usá --dart-define-from-file.',
      );
    }
  }
}
```

- [ ] **Step 3: `app_dependencies.dart`**

```dart
import '../../feature/auth/domain/auth_repository.dart';
import '../env/app_flavor.dart';

/// Grafo de dependencias ya resuelto (composición raíz). Solo INTERFACES:
/// el bootstrap no conoce Supabase ni memory. Crece con cada feature.
class AppDependencies {
  const AppDependencies({
    required this.flavor,
    required this.authRepository,
  });

  final AppFlavor flavor;
  final AuthRepository authRepository;
}
```

- [ ] **Step 4: `modules/auth_module.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../presentation/auth/bloc/auth_bloc.dart';
import '../app_dependencies.dart';

/// Wiring de auth: arma `AuthActions` desde el `AuthRepository` y la inyecta al
/// `AuthBloc` (el bloc nunca recibe el repository directo).
abstract final class AuthModule {
  static List<BlocProvider<AuthBloc>> blocProviders(AppDependencies deps) => [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(AuthActions(deps.authRepository)),
        ),
      ];
}
```

- [ ] **Step 5: `supabase_auth_repository.dart`** (esqueleto — backend pendiente)

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:fpdart/fpdart.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';

/// Esqueleto de la impl real (Supabase). El backend se cablea en un sprint
/// posterior; por ahora responde `AuthUnavailable` para no romper el contrato.
class SupabaseAuthRepository implements AuthRepository {
  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> sessionChanges() => const Stream.empty();

  @override
  FutureResult<AuthFailure, AuthSession> signIn({
    required String identifier,
    required String pin,
  }) async =>
      left(const GlobalFailure.server(AuthFailure.authUnavailable()));

  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    String? alias,
    required String pin,
  }) async =>
      left(const GlobalFailure.server(AuthFailure.authUnavailable()));

  @override
  FutureResult<AuthFailure, Unit> signOut() async => right(unit);
}
```

- [ ] **Step 6: `envs/mock_dependencies.dart`**

```dart
import '../../../feature/auth/infrastructure/memory_auth_repository.dart';
import '../../env/app_flavor.dart';
import '../app_dependencies.dart';

/// Grafo del flavor `mock`: repos en memoria, sin red. PIN válido = '0000'.
Future<AppDependencies> buildMockDependencies() async => AppDependencies(
      flavor: AppFlavor.mock,
      authRepository: MemoryAuthRepository(),
    );
```

- [ ] **Step 7: `envs/shared/shared_supabase_dependencies.dart`**

```dart
import '../../../../feature/auth/infrastructure/supabase_auth_repository.dart';
import '../../../env/app_env.dart';
import '../../../env/app_flavor.dart';
import '../../app_dependencies.dart';

/// Construcción compartida por `local` y `production` (mismo código, distinta
/// config vía `--dart-define`). El cableado real de Supabase.initialize se
/// completa cuando llegue el backend.
Future<AppDependencies> buildSharedSupabaseDependencies(
  AppFlavor flavor,
) async {
  AppEnv.validate();
  // TODO(backend): Supabase.initialize(url: AppEnv.supabaseUrl, anonKey: ...)
  return AppDependencies(
    flavor: flavor,
    authRepository: SupabaseAuthRepository(),
  );
}
```

> Nota: el `TODO(backend)` es un marcador de trabajo diferido explícito, no un placeholder del plan — la clase compila y cumple el contrato hoy.

- [ ] **Step 8: `envs/local_dependencies.dart` y `envs/production_dependencies.dart`**

`local_dependencies.dart`:

```dart
import '../../env/app_flavor.dart';
import '../app_dependencies.dart';
import 'shared/shared_supabase_dependencies.dart';

Future<AppDependencies> buildLocalDependencies() =>
    buildSharedSupabaseDependencies(AppFlavor.local);
```

`production_dependencies.dart`:

```dart
import '../../env/app_flavor.dart';
import '../app_dependencies.dart';
import 'shared/shared_supabase_dependencies.dart';

Future<AppDependencies> buildProductionDependencies() =>
    buildSharedSupabaseDependencies(AppFlavor.production);
```

- [ ] **Step 9: Config JSON**

`config.mock.json`:
```json
{}
```
`config.example.json`:
```json
{
  "SUPABASE_URL": "",
  "SUPABASE_ANON_KEY": ""
}
```
`config.local.json`:
```json
{
  "SUPABASE_URL": "http://127.0.0.1:54321",
  "SUPABASE_ANON_KEY": "REEMPLAZAR_CON_ANON_KEY_LOCAL"
}
```
`config.production.json`:
```json
{
  "SUPABASE_URL": "https://REEMPLAZAR.supabase.co",
  "SUPABASE_ANON_KEY": "REEMPLAZAR_CON_ANON_KEY_PROD"
}
```

- [ ] **Step 10: Test del grafo mock**

`apps/mobile/test/core/injection/mock_dependencies_test.dart`:

```dart
import 'package:cuycash/core/env/app_flavor.dart';
import 'package:cuycash/core/injection/envs/mock_dependencies.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildMockDependencies expone un MemoryAuthRepository', () async {
    final deps = await buildMockDependencies();
    expect(deps.flavor, AppFlavor.mock);
    expect(deps.authRepository, isA<MemoryAuthRepository>());
  });
}
```

- [ ] **Step 11: Correr el test**

Run: `cd apps/mobile && flutter test test/core/injection/mock_dependencies_test.dart`
Expected: 1 test PASS.

- [ ] **Step 12: Commit**

```bash
git add apps/mobile/lib/core apps/mobile/lib/feature/auth/infrastructure/supabase_auth_repository.dart \
        apps/mobile/config.mock.json apps/mobile/config.example.json apps/mobile/test/core
git commit -m "feat: flavors (mock/local/production) + AppDependencies + auth wiring"
```

---

## Task 10: Navegación — gate de auth (TDD) + router

**Files:**
- Create: `apps/mobile/lib/presentation/app/app_redirect.dart`
- Create: `apps/mobile/lib/presentation/app/go_router_refresh_stream.dart`
- Create: `apps/mobile/lib/presentation/app/router.dart`
- Test: `apps/mobile/test/presentation/app/app_redirect_test.dart`

**Interfaces:**
- Consumes: `AuthState`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthBloc`, `AppDependencies`.
- Produces:
  - `abstract final class AppRoutes { static const splash='/'; onboarding='/onboarding'; login='/login'; registro='/registro'; home='/home'; perfil='/perfil'; }`.
  - `String? appRedirect(AuthState authState, String location)`.
  - `class GoRouterRefreshStream extends ChangeNotifier`.
  - `GoRouter createAppRouter(AppDependencies deps, AuthBloc authBloc)`.

- [ ] **Step 1: Escribir el test del gate primero**

`apps/mobile/test/presentation/app/app_redirect_test.dart`:

```dart
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/presentation/app/app_redirect.dart';
import 'package:cuycash/presentation/app/router.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authed = AuthState.authenticated(
      AuthSession(userId: 'u', identifier: '12345678'));
  const unauthed = AuthState.unauthenticated();

  test('no autenticado fuera de gate → /onboarding', () {
    expect(appRedirect(unauthed, AppRoutes.home), AppRoutes.onboarding);
  });

  test('no autenticado ya en /login → sin redirect', () {
    expect(appRedirect(unauthed, AppRoutes.login), isNull);
  });

  test('autenticado en pantalla de gate → /home', () {
    expect(appRedirect(authed, AppRoutes.login), AppRoutes.home);
    expect(appRedirect(authed, AppRoutes.onboarding), AppRoutes.home);
  });

  test('autenticado en /home → sin redirect', () {
    expect(appRedirect(authed, AppRoutes.home), isNull);
  });
}
```

- [ ] **Step 2: Escribir `router.dart` con `AppRoutes`** (mínimo para compilar el test)

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/injection/app_dependencies.dart';
import '../auth/bloc/auth_bloc.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
import '../shell/app_shell.dart';
import '../splash/splash_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'app_redirect.dart';
import 'go_router_refresh_stream.dart';

/// Rutas de la app.
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const registro = '/registro';
  static const home = '/home';
  static const perfil = '/perfil';
}

/// Router: gate de auth + shell de 2 tabs (Home, Perfil).
GoRouter createAppRouter(AppDependencies deps, AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      if (state.matchedLocation == AppRoutes.splash) return null;
      return appRedirect(authBloc.state, state.matchedLocation);
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.registro,
          builder: (_, _) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.perfil,
                builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
```

- [ ] **Step 3: Escribir `app_redirect.dart`**

```dart
import '../auth/bloc/auth_bloc.dart';
import 'router.dart';

/// Pantallas de gate (no requieren sesión). Función pura, testeable.
const _gateLocations = {
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.registro,
};

/// Gate del router según auth.
/// - no autenticado fuera de gate → /onboarding
/// - autenticado en pantalla de gate → /home
/// - resto → sin redirect
String? appRedirect(AuthState authState, String location) {
  switch (authState) {
    case AuthUnauthenticated():
      return _gateLocations.contains(location) ? null : AppRoutes.onboarding;
    case AuthAuthenticated():
      return _gateLocations.contains(location) ? AppRoutes.home : null;
  }
}
```

- [ ] **Step 4: Escribir `go_router_refresh_stream.dart`**

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta un Stream a Listenable para el `refreshListenable` de go_router.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

> Las pantallas referenciadas (`SplashScreen`, etc.) se crean en Task 11–12. Para que el test del gate corra ya, este paso puede fallar al compilar el router; corré el test del gate contra `app_redirect.dart` (no importa el router entero) — ver Step 5. El router se valida completo al final de Task 12.

- [ ] **Step 5: Correr el test del gate**

Run: `cd apps/mobile && flutter test test/presentation/app/app_redirect_test.dart`
Expected: 4 tests PASS. (Si el import de `router.dart` arrastra pantallas aún inexistentes, crear primero los stubs de Task 11–12 y volver aquí.)

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/presentation/app apps/mobile/test/presentation/app/app_redirect_test.dart
git commit -m "feat: gate de auth (app_redirect) + router go_router"
```

---

## Task 11: Pantallas — splash, onboarding, home, perfil, shell

**Files:**
- Create: `apps/mobile/lib/presentation/splash/splash_screen.dart`
- Create: `apps/mobile/lib/presentation/onboarding/onboarding_screen.dart`
- Create: `apps/mobile/lib/presentation/onboarding/widgets/onboarding_slide.dart`
- Create: `apps/mobile/lib/presentation/home/home_screen.dart`
- Create: `apps/mobile/lib/presentation/profile/profile_screen.dart`
- Create: `apps/mobile/lib/presentation/shell/app_shell.dart`
- Test: `apps/mobile/test/presentation/profile/profile_screen_test.dart`

**Interfaces:**
- Consumes: `AppRoutes`, `AuthBloc`, `AuthEvent.signedOut`, `PrimaryButton`, `SecondaryButton`, `GhostButton`, `PageDotsIndicator`, `BrandMark`, `CuyCashColors`, `CuyCashTypography`.
- Produces: `SplashScreen`, `OnboardingScreen`, `OnboardingSlide`, `HomeScreen`, `ProfileScreen`, `AppShell({required StatefulNavigationShell navigationShell})` — todos `const` widgets.

- [ ] **Step 1: `splash_screen.dart`**

```dart
import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';

/// Splash breve: muestra la marca y luego navega a onboarding (el gate del
/// router lo reenviará a /home si ya hay sesión).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) context.go(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CuyCashColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 96),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Text('CuyCash',
                style: CuyCashTypography.headlineMd
                    .copyWith(color: CuyCashColors.surface)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: CuyCashColors.secondary,
                backgroundColor: CuyCashColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `widgets/onboarding_slide.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Un slide del onboarding: ilustración placeholder + título + descripción.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: CuyCashSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          AspectRatio(
            aspectRatio: 1.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: CuyCashColors.outlineVariant),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(160)),
              ),
              child: const Center(child: BrandMark(size: 80)),
            ),
          ),
          const Spacer(),
          Text(title, style: CuyCashTypography.headlineLgMobile),
          const SizedBox(height: CuyCashSpacing.stackMd),
          Text(description, style: CuyCashTypography.bodyLg
              .copyWith(color: CuyCashColors.secondaryText)),
          const SizedBox(height: CuyCashSpacing.stackXl),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `onboarding_screen.dart`** (estado local del PageView)

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/router.dart';
import 'widgets/onboarding_slide.dart';

/// Carrusel de 3 slides. El índice es estado local (UI pura, sin Bloc).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      (title: l10n.onboardingTitle1, description: l10n.onboardingBody1),
      (title: l10n.onboardingTitle2, description: l10n.onboardingBody2),
      (title: l10n.onboardingTitle3, description: l10n.onboardingBody3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                itemCount: slides.length,
                itemBuilder: (_, index) => OnboardingSlide(
                  title: slides[index].title,
                  description: slides[index].description,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: CuyCashSpacing.marginMobile),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PageDotsIndicator(
                        count: slides.length, activeIndex: _index),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  PrimaryButton(
                    label: l10n.createAccount,
                    onPressed: () => context.go(AppRoutes.registro),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  GhostButton(
                    label: l10n.alreadyHaveAccount,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: `home_screen.dart`** (placeholder)

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Home placeholder del Sprint 1 (las features de billetera llegan después).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Text(l10n.homePlaceholder,
              textAlign: TextAlign.center, style: CuyCashTypography.bodyLg),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: `profile_screen.dart`** (cerrar sesión)

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';

/// Perfil: muestra el identificador de la sesión y permite cerrar sesión.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<AuthBloc>().state;
    final identifier =
        state is AuthAuthenticated ? state.session.identifier : '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.profileIdentifierLabel,
                style: CuyCashTypography.labelMd),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(identifier, style: CuyCashTypography.titleMd),
            const Spacer(),
            SecondaryButton(
              label: l10n.signOut,
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthEvent.signedOut()),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: `app_shell.dart`** (bottom nav de 2 tabs)

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// Shell con bottom nav (Home, Perfil).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        indicatorColor: CuyCashColors.surfaceContainerHigh,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile),
        ],
      ),
    );
  }
}
```

- [ ] **Step 7: Test de ProfileScreen (dispara signOut)**

`apps/mobile/test/presentation/profile/profile_screen_test.dart`:

```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/profile/profile_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el identificador y cerrar sesión dispara signOut',
      (tester) async {
    final repo = MemoryAuthRepository(
      initial: const AuthSession(userId: 'u', identifier: '12345678'),
    );
    final bloc = AuthBloc(AuthActions(repo));

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12345678'), findsOneWidget);

    await tester.tap(find.byType(SecondaryButton));
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNull);
    await bloc.close();
  });
}
```

- [ ] **Step 8: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/profile/profile_screen_test.dart`
Expected: 1 test PASS (tras generar l10n en Task 13; si aún no existe `AppLocalizations`, correr Task 13 primero y volver).

- [ ] **Step 9: Commit**

```bash
git add apps/mobile/lib/presentation/splash apps/mobile/lib/presentation/onboarding \
        apps/mobile/lib/presentation/home apps/mobile/lib/presentation/profile \
        apps/mobile/lib/presentation/shell apps/mobile/test/presentation/profile
git commit -m "feat: pantallas splash/onboarding/home/perfil + shell"
```

---

## Task 12: Pantallas de auth — login y registro

**Files:**
- Create: `apps/mobile/lib/presentation/auth/login_screen.dart`
- Create: `apps/mobile/lib/presentation/auth/register_screen.dart`
- Create: `apps/mobile/lib/presentation/auth/auth_error_text.dart`
- Test: `apps/mobile/test/presentation/auth/login_screen_test.dart`

**Interfaces:**
- Consumes: `AuthBloc`, `AuthEvent`, `AuthState`, `AuthError`, `FormStatus`, `CuyCashTextField`, `PrimaryButton`, `GhostButton`, `AppRoutes`, `AppLocalizations`.
- Produces: `LoginScreen`, `RegisterScreen`, `String authErrorText(AppLocalizations, AuthError)`.

- [ ] **Step 1: `auth_error_text.dart`** (traduce AuthError → copy ARB)

```dart
import '../../l10n/app_localizations.dart';
import 'bloc/auth_bloc.dart';

/// Traduce el `AuthError` del bloc a copy es-PE (el bloc no carga texto).
String authErrorText(AppLocalizations l10n, AuthError error) => switch (error) {
      AuthError.invalidCredentials => l10n.errorInvalidCredentials,
      AuthError.identifierTaken => l10n.errorIdentifierTaken,
      AuthError.weakPin => l10n.errorWeakPin,
      AuthError.generic => l10n.errorGeneric,
    };
```

- [ ] **Step 2: `login_screen.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/router.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Login con DNI/Alias + PIN.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthEvent.loginSubmitted(
          identifier: _identifier.text.trim(),
          pin: _pin.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final unauth =
                state is AuthUnauthenticated ? state : const AuthUnauthenticated();
            final error = unauth.error;
            return ListView(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              children: [
                Text(l10n.loginHeadline,
                    style: CuyCashTypography.headlineMd),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(l10n.loginSubtitle, style: CuyCashTypography.bodyMd),
                const SizedBox(height: CuyCashSpacing.stackXl),
                CuyCashTextField(
                  label: l10n.identifierLabel,
                  hint: 'Ej. 12345678',
                  controller: _identifier,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                CuyCashTextField(
                  label: l10n.pinLabel,
                  hint: '****',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  errorText: error == null ? null : authErrorText(l10n, error),
                ),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PrimaryButton(
                  label: l10n.loginCta,
                  loading: unauth.status == FormStatus.submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(
                  label: l10n.goToRegister,
                  onPressed: () => context.go(AppRoutes.registro),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: `register_screen.dart`** (stub: DNI + PIN, resto después)

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../app/router.dart';
import 'auth_error_text.dart';
import 'bloc/auth_bloc.dart';

/// Registro stub del Sprint 1: DNI + PIN. Las pantallas reales (validación
/// DNI/rostro) llegan después.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _dni = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _dni.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(AuthEvent.registerSubmitted(
          dni: _dni.text.trim(),
          pin: _pin.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final unauth =
                state is AuthUnauthenticated ? state : const AuthUnauthenticated();
            final error = unauth.error;
            return ListView(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              children: [
                Text(l10n.registerHeadline,
                    style: CuyCashTypography.headlineMd),
                const SizedBox(height: CuyCashSpacing.stackXl),
                CuyCashTextField(
                  label: l10n.dniLabel,
                  hint: 'Ej. 12345678',
                  controller: _dni,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                CuyCashTextField(
                  label: l10n.pinLabel,
                  hint: '****',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  errorText: error == null ? null : authErrorText(l10n, error),
                ),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PrimaryButton(
                  label: l10n.registerCta,
                  loading: unauth.status == FormStatus.submitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(
                  label: l10n.goToLogin,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Test de LoginScreen (submit dispara evento)**

`apps/mobile/test/presentation/auth/login_screen_test.dart`:

```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/auth/login_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ingresar con credenciales válidas autentica', (tester) async {
    final repo = MemoryAuthRepository();
    final bloc = AuthBloc(AuthActions(repo));

    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12345678');
    await tester.enterText(find.byType(TextField).last, '0000');
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(repo.currentSession, isNotNull);
    await bloc.close();
  });
}
```

- [ ] **Step 5: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/auth/login_screen_test.dart`
Expected: 1 test PASS.

- [ ] **Step 6: Verificar el router completo compila**

Run: `cd apps/mobile && flutter analyze lib/presentation`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add apps/mobile/lib/presentation/auth apps/mobile/test/presentation/auth/login_screen_test.dart
git commit -m "feat: pantallas de login y registro (stub) con AuthBloc"
```

---

## Task 13: Localización es-PE (ARB)

**Files:**
- Create: `apps/mobile/l10n.yaml`
- Create: `apps/mobile/lib/l10n/arb/app_es.arb`
- Generated: `apps/mobile/lib/l10n/app_localizations.dart` (+ `app_localizations_es.dart`)

**Interfaces:**
- Produces: `class AppLocalizations` con todas las claves usadas por las pantallas (ver lista abajo). `AppLocalizations.of(context)`, `localizationsDelegates`, `supportedLocales`.

- [ ] **Step 1: `l10n.yaml`**

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n
nullable-getter: false
```

- [ ] **Step 2: `lib/l10n/arb/app_es.arb`** (copy es-PE completo)

```json
{
  "@@locale": "es",
  "createAccount": "Crear mi cuenta",
  "alreadyHaveAccount": "¿Ya tienes cuenta? Iniciar sesión",
  "onboardingTitle1": "Tu banco, sin colas ni papeles",
  "onboardingBody1": "Abre tu cuenta en minutos validando tu DNI y tu rostro.",
  "onboardingTitle2": "Envía y cobra en segundos",
  "onboardingBody2": "Manda dinero a cualquier persona en CuyCash sin comisiones, o cobra mostrando tu código.",
  "onboardingTitle3": "Recibe desde otras billeteras",
  "onboardingBody3": "El dinero que te envían desde otras apps llega directo a tu billetera CuyCash.",
  "loginTitle": "Iniciar sesión",
  "loginHeadline": "Te extrañábamos",
  "loginSubtitle": "Ingresa tus datos para continuar.",
  "identifierLabel": "DNI o Alias",
  "pinLabel": "PIN de seguridad",
  "loginCta": "Ingresar",
  "goToRegister": "¿No tienes cuenta? Regístrate",
  "registerTitle": "Crear cuenta",
  "registerHeadline": "Empecemos por lo básico",
  "dniLabel": "DNI",
  "registerCta": "Continuar",
  "goToLogin": "¿Ya tienes cuenta? Iniciar sesión",
  "homeTitle": "Inicio",
  "homePlaceholder": "Tu billetera estará disponible muy pronto.",
  "profileTitle": "Perfil",
  "profileIdentifierLabel": "Tu identificador",
  "signOut": "Cerrar sesión",
  "navHome": "Inicio",
  "navProfile": "Perfil",
  "errorInvalidCredentials": "DNI/Alias o PIN incorrectos.",
  "errorIdentifierTaken": "Este DNI ya está registrado.",
  "errorWeakPin": "El PIN debe tener 4 dígitos.",
  "errorGeneric": "Ocurrió un error. Intenta de nuevo."
}
```

- [ ] **Step 3: Generar la localización**

Run: `cd apps/mobile && flutter gen-l10n`
Expected: genera `lib/l10n/app_localizations.dart` sin errores.

- [ ] **Step 4: Verificar que resuelve**

Run: `cd apps/mobile && flutter analyze lib/l10n`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/l10n.yaml apps/mobile/lib/l10n
git commit -m "feat: localización es-PE (ARB) + copy de pantallas"
```

> **Nota de orden de ejecución:** Task 13 produce `AppLocalizations`, del que dependen las pantallas de Task 11–12. Si se ejecuta con subagentes en orden, correr los tests de widget de Task 11 (Step 8) y Task 12 (Step 5) *después* de Task 13. El plan mantiene el orden numérico por dependencia de contratos; el ejecutor puede generar l10n antes de correr esos tests de widget.

---

## Task 14: Composición raíz (AppRoot, CuyCashApp) y entrypoints

**Files:**
- Create: `apps/mobile/lib/presentation/app/app_root.dart`
- Create: `apps/mobile/lib/presentation/app/cuycash_app.dart`
- Create: `apps/mobile/lib/core/boot/bootstrap.dart`
- Create: `apps/mobile/lib/main_mock.dart`
- Create: `apps/mobile/lib/main_local.dart`
- Create: `apps/mobile/lib/main_production.dart`
- Delete: `apps/mobile/lib/main.dart` (el autogenerado)

**Interfaces:**
- Consumes: `AppDependencies`, `AuthModule`, `AuthBloc`, `createAppRouter`, `CuyCashTheme`, `AppLocalizations`, `buildMockDependencies`/`buildLocalDependencies`/`buildProductionDependencies`.
- Produces: `AppRoot({required AppDependencies dependencies})`, `CuyCashApp({required AppDependencies dependencies})`, `Future<void> bootstrap(Future<Widget> Function() builder)`.

- [ ] **Step 1: `bootstrap.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';

/// Entrypoint genérico: inicializa bindings y monta el árbol dentro de una zona
/// guardada. Cada `main_<flavor>` le pasa el builder de su `AppRoot`.
Future<void> bootstrap(Future<Widget> Function() builder) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(await builder());
  }, (error, stack) {
    debugPrint('[bootstrap] error no capturado: $error');
  });
}
```

- [ ] **Step 2: `cuycash_app.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../core/injection/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'router.dart';

/// MaterialApp.router con theme + l10n. Crea el router una sola vez con el
/// AuthBloc del árbol.
class CuyCashApp extends StatefulWidget {
  const CuyCashApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<CuyCashApp> createState() => _CuyCashAppState();
}

class _CuyCashAppState extends State<CuyCashApp> {
  late final router = createAppRouter(
    widget.dependencies,
    context.read<AuthBloc>(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CuyCash',
      debugShowCheckedModeBanner: false,
      theme: CuyCashTheme.light(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

- [ ] **Step 3: `app_root.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/env/app_flavor.dart';
import '../../core/injection/app_dependencies.dart';
import '../../core/injection/modules/auth_module.dart';
import 'cuycash_app.dart';

/// Composición raíz: recibe el grafo resuelto (`AppDependencies`) y lo provee —
/// flavor por RepositoryProvider, blocs por sus módulos.
class AppRoot extends StatelessWidget {
  const AppRoot({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AppFlavor>.value(
      value: dependencies.flavor,
      child: MultiBlocProvider(
        providers: [
          ...AuthModule.blocProviders(dependencies),
        ],
        child: CuyCashApp(dependencies: dependencies),
      ),
    );
  }
}
```

- [ ] **Step 4: Entrypoints**

`main_mock.dart`:
```dart
import 'core/boot/bootstrap.dart';
import 'core/injection/envs/mock_dependencies.dart';
import 'presentation/app/app_root.dart';

Future<void> main() => bootstrap(
      () async => AppRoot(dependencies: await buildMockDependencies()),
    );
```

`main_local.dart`:
```dart
import 'core/boot/bootstrap.dart';
import 'core/injection/envs/local_dependencies.dart';
import 'presentation/app/app_root.dart';

Future<void> main() => bootstrap(
      () async => AppRoot(dependencies: await buildLocalDependencies()),
    );
```

`main_production.dart`:
```dart
import 'core/boot/bootstrap.dart';
import 'core/injection/envs/production_dependencies.dart';
import 'presentation/app/app_root.dart';

Future<void> main() => bootstrap(
      () async => AppRoot(dependencies: await buildProductionDependencies()),
    );
```

- [ ] **Step 5: Borrar el `main.dart` autogenerado y su widget test**

```bash
rm apps/mobile/lib/main.dart apps/mobile/test/widget_test.dart
```

- [ ] **Step 6: Análisis global**

Run: `cd apps/mobile && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 7: Correr toda la suite**

Run: `cd /Users/jairconislla/Projects/cuycash && flutter test`
Expected: todos los tests PASS (core_kernel, design_system, auth memory/bloc, gate, mock deps, profile, login).

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib apps/mobile/test
git commit -m "feat: composición raíz (AppRoot, CuyCashApp) + entrypoints por flavor"
```

---

## Task 15: Flavors nativos + smoke run + CLAUDE.md

**Files:**
- Modify: `apps/mobile/android/app/build.gradle` (o `build.gradle.kts`) — productFlavors `mock`/`local`/`production`
- Modify: `apps/mobile/ios/` — schemes (documentar; setup manual en Xcode si aplica)
- Create: `cuycash/CLAUDE.md`
- Create: `cuycash/README.md`

**Interfaces:**
- Produces: la app corre con `--flavor mock`; doc de comandos.

- [ ] **Step 1: Configurar productFlavors en Android**

En `apps/mobile/android/app/build.gradle.kts`, dentro de `android { }`:

```kotlin
flavorDimensions += "env"
productFlavors {
    create("mock") {
        dimension = "env"
        applicationIdSuffix = ".mock"
        resValue("string", "app_name", "CuyCash Mock")
    }
    create("local") {
        dimension = "env"
        applicationIdSuffix = ".local"
        resValue("string", "app_name", "CuyCash Local")
    }
    create("production") {
        dimension = "env"
        resValue("string", "app_name", "CuyCash")
    }
}
```

(Si el proyecto generó `build.gradle` en Groovy, usar la sintaxis Groovy equivalente.)

- [ ] **Step 2: Smoke run en flavor mock**

Run:
```bash
cd apps/mobile
flutter run --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json
```
Expected: arranca → splash → onboarding. "Crear mi cuenta" → registro; con DNI `12345678` + PIN `0000` entra a Home; en Perfil, "Cerrar sesión" vuelve a onboarding. Login con PIN `0000` funciona; PIN distinto muestra error carmín.

(Si no hay dispositivo/emulador, correr `flutter build apk --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json` para validar el build.)

- [ ] **Step 3: Crear `CLAUDE.md`**

```markdown
# CuyCash — app móvil (banca digital · Perú)

Monorepo Flutter. Sprint 1 = base: splash → onboarding → (login | registro) →
home → perfil (cerrar sesión). Backend real y dashboard web se difieren.

## Estructura
- `apps/mobile` — app Flutter (Bloc).
- `packages/core_kernel` — Result/Either, GlobalFailure, ExceptionMapper, ids (Dart puro).
- `packages/design_system` — tokens "Eucalipto y Ocre", theme, componentes.

Features-first vertical: `feature/<x>/{domain,application,infrastructure}` (sin
Flutter); UI + Bloc en `presentation/<x>/`.

## Flavors
- `mock` — repos en memoria (PIN válido `0000`). Default de desarrollo + tests.
- `local` — Supabase local (`config.local.json`).
- `production` — Supabase prod (`config.production.json`).

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
```

- [ ] **Step 4: Crear `README.md`** (breve)

```markdown
# CuyCash

App móvil de banca digital (Perú). Proyecto universitario. Ver `CLAUDE.md` para
arquitectura y comandos, y `docs/superpowers/specs/` para el diseño.
```

- [ ] **Step 5: Commit final**

```bash
git add apps/mobile/android CLAUDE.md README.md
git commit -m "chore: flavors nativos android + CLAUDE.md + README"
```

---

## Self-Review

**1. Spec coverage:**
- §1 monorepo/flavors → Task 1, 9, 15. ✓
- §2 design system → Task 3, 4. ✓
- §3 feature auth (domain/application/infra) → Task 5, 6, 7, 9 (supabase skeleton). ✓
- §4 presentation (blocs, pantallas, router, gate) → Task 8, 10, 11, 12. ✓
- §5 inyección + plan de tests → Task 9, y tests distribuidos en 2/3/4/6/8/10/11/12. ✓
- Copy es-PE ARB → Task 13. ✓
- Composición raíz + entrypoints → Task 14. ✓

**2. Placeholder scan:** El único `TODO(backend)` (Task 9, Step 7) es un marcador de trabajo diferido explícito y documentado — la clase compila y cumple el contrato. No hay "TBD"/"implement later" en pasos de implementación. Todos los pasos de código traen código real.

**3. Type consistency:** `AuthSession { userId, identifier, alias }`, `AuthActions.signIn/register/signOut`, `AuthEvent.loginSubmitted/registerSubmitted/signedOut/sessionChanged`, `AuthState.unauthenticated/authenticated`, `AuthError { invalidCredentials, identifierTaken, weakPin, generic }`, `FormStatus { idle, submitting }`, `AppRoutes.{splash,onboarding,login,registro,home,perfil}`, `appRedirect(AuthState, String)`, `buildMockDependencies/buildLocalDependencies/buildProductionDependencies`, `AuthModule.blocProviders` — nombres consistentes en todas las tasks.

**Nota de orden:** l10n (Task 13) produce `AppLocalizations`, consumido por pantallas de Task 11–12. Los tests de widget de esas tasks se corren tras generar l10n (nota en Task 13). El resto del orden respeta dependencias de contrato.
