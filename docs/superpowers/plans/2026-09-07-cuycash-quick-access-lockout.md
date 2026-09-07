# CuyCash — Acceso rápido, usuario recordado, intentos/bloqueo y cambiar de usuario — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Acceso rápido por PIN para un usuario recordado en el dispositivo (con biometría simulada), conteo de intentos + bloqueo escalonado simulado, y diálogo de cambiar de usuario.

**Architecture:** Nueva feature `device` (Dart puro + `flutter_secure_storage`) que guarda el `RememberedUser` y el `LockoutState` cifrados en el dispositivo (todos los flavors). `QuickAccessBloc` consume `AuthActions` + `DeviceActions` con reloj inyectado. El splash decide la ruta inicial (bloqueado / acceso rápido / onboarding). Biometría e intentos/bloqueo se simulan en el cliente; el enforcement real es backend.

**Tech Stack:** Flutter, flutter_bloc, freezed, bloc_test, flutter_secure_storage, go_router, fpdart, design_system, core_kernel.

**Spec:** `docs/superpowers/specs/2026-09-07-cuycash-quick-access-lockout-design.md`

## Global Constraints

- Errores como valores; failures sellados; `Memory*` funcional = contrato de tests.
- Estados de feature sealed + `switch` exhaustivo; prohibido `when`/`maybeWhen`/`orElse`/`!` sobre estados. (Los estados de UI de una sola forma son data-class freezed.)
- El Bloc consume la capa `application` por constructor, nunca el repo.
- DI por constructor; composición raíz por flavor.
- Tokens del design system; cero hex sueltos en widgets. Copy es-PE en ARB. Marca "CuyCash".
- `.freezed.dart`/l10n generados se commitean. Codegen: `dart run build_runner build --delete-conflicting-outputs` (en `apps/mobile`).
- Un widget público por archivo. PIN = 6 dígitos.
- `flutter_secure_storage` se usa en TODOS los flavors (capacidad del dispositivo). Tests usan `MemoryDeviceStore`.
- Biometría simulada; intentos/bloqueo simulados en cliente; reloj inyectable (`DateTime Function()`), nunca `DateTime.now()` directo en lógica testeable.
- Bloqueo escalonado: nivel 1 = 15 min, nivel 2 = 1 h, nivel 3+ = 24 h. Máx. 3 intentos por ciclo.
- Analyze whole-project limpio; commits en español.

---

## File Structure

```
apps/mobile/lib/
  feature/device/
    domain/remembered_user.dart          # RememberedUser (dni, fullName, alias) + initials/firstName + json
    domain/lockout_state.dart            # LockoutState (failedAttempts, level, lockedUntil) + isLocked + json
    domain/lockout_policy.dart           # maxAttempts, durationForLevel
    domain/device_store.dart             # interface
    infrastructure/secure_device_store.dart   # flutter_secure_storage
    infrastructure/memory_device_store.dart   # tests + fake
    application/device_actions.dart      # readUser/saveUser/clearUser + readLockout/registerFailedAttempt/resetLockout
  feature/auth/domain/auth_session.dart  # + fullName? (para recordar nombre)
  feature/auth/infrastructure/memory_auth_repository.dart  # register incluye fullName
  presentation/quick_access/bloc/quick_access_bloc.dart (+ event/state/freezed)
  presentation/quick_access/quick_access_screen.dart
  presentation/quick_access/access_blocked_screen.dart
  presentation/quick_access/widgets/switch_user_dialog.dart
  presentation/splash/splash_screen.dart # decide ruta inicial vía DeviceActions
  presentation/app/app_routes.dart       # + quickAccess, blocked
  presentation/app/app_redirect.dart     # gate: quickAccess+blocked permitidos sin auth
  presentation/app/router.dart           # rutas + providers
  presentation/app/app_root.dart         # RepositoryProvider<DeviceActions> + guardar recordado al autenticar
  presentation/profile/profile_screen.dart # "cerrar sesión" → SwitchUserDialog
  core/injection/app_dependencies.dart   # + deviceStore
  core/injection/modules/{device_module,quick_access_module}.dart
  core/injection/envs/*                  # cablear SecureDeviceStore
  l10n/arb/app_es.arb

packages/design_system/lib/src/
  pin_dots.dart · pin_keypad.dart · initials_avatar.dart
```

---

## Task 1: Feature `device` (dominio + secure store + memory store + acciones)

**Files:**
- Create: `apps/mobile/lib/feature/device/domain/remembered_user.dart`
- Create: `apps/mobile/lib/feature/device/domain/lockout_state.dart`
- Create: `apps/mobile/lib/feature/device/domain/lockout_policy.dart`
- Create: `apps/mobile/lib/feature/device/domain/device_store.dart`
- Create: `apps/mobile/lib/feature/device/infrastructure/memory_device_store.dart`
- Create: `apps/mobile/lib/feature/device/infrastructure/secure_device_store.dart`
- Create: `apps/mobile/lib/feature/device/application/device_actions.dart`
- Modify: `apps/mobile/pubspec.yaml` (add `flutter_secure_storage`)
- Test: `apps/mobile/test/feature/device/memory_device_store_test.dart`
- Test: `apps/mobile/test/feature/device/device_actions_test.dart`

**Interfaces:**
- Produces:
  - `class RememberedUser { final String dni, fullName, alias; String get firstName; String get initials; Map<String,dynamic> toJson(); factory RememberedUser.fromJson(Map); }`
  - `class LockoutState { final int failedAttempts, level; final DateTime? lockedUntil; bool isLocked(DateTime now); LockoutState copyWith({...}); toJson/fromJson; const LockoutState(); }`
  - `abstract final class LockoutPolicy { static const int maxAttempts = 3; static Duration durationForLevel(int level); }`
  - `abstract interface class DeviceStore { readUser/saveUser/clearUser/readLockout/saveLockout/clearLockout }`
  - `class MemoryDeviceStore implements DeviceStore`
  - `class SecureDeviceStore implements DeviceStore` (`SecureDeviceStore(FlutterSecureStorage)`)
  - `class DeviceActions { DeviceActions(DeviceStore); readUser/saveUser/clearUser/readLockout; Future<LockoutState> registerFailedAttempt(DateTime now); Future<void> resetLockout(); }`

- [ ] **Step 1: Añadir dependencia**

En `apps/mobile/pubspec.yaml`, en `dependencies:` (tras `share_plus`):
```yaml
  flutter_secure_storage: ^9.2.4
```
Run: `cd /Users/jairconislla/Projects/cuycash && flutter pub get`

- [ ] **Step 2: `lockout_policy.dart`**

```dart
/// Política de bloqueo escalonado (simulada en cliente; el enforcement real
/// es backend). Nivel 1 = 15 min, nivel 2 = 1 h, nivel 3+ = 24 h.
abstract final class LockoutPolicy {
  static const int maxAttempts = 3;

  static Duration durationForLevel(int level) => switch (level) {
        1 => const Duration(minutes: 15),
        2 => const Duration(hours: 1),
        _ => const Duration(hours: 24),
      };
}
```

- [ ] **Step 3: `remembered_user.dart`**

```dart
/// Usuario recordado en este dispositivo (para el acceso rápido). Dato local
/// no secreto salvo el DNI; se guarda cifrado vía secure storage.
class RememberedUser {
  const RememberedUser({
    required this.dni,
    required this.fullName,
    required this.alias,
  });

  final String dni;
  final String fullName;
  final String alias;

  String get firstName {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? alias : trimmed.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts =
        fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return alias.replaceAll('@', '').toUpperCase().padRight(1).substring(0, 1);
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() =>
      {'dni': dni, 'fullName': fullName, 'alias': alias};

  factory RememberedUser.fromJson(Map<String, dynamic> json) => RememberedUser(
        dni: json['dni'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        alias: json['alias'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is RememberedUser &&
      other.dni == dni &&
      other.fullName == fullName &&
      other.alias == alias;

  @override
  int get hashCode => Object.hash(dni, fullName, alias);
}
```

- [ ] **Step 4: `lockout_state.dart`**

```dart
/// Estado de intentos/bloqueo (simulado, persistido). `level` = nº de bloqueos
/// aplicados (para escalar la duración).
class LockoutState {
  const LockoutState({
    this.failedAttempts = 0,
    this.level = 0,
    this.lockedUntil,
  });

  final int failedAttempts;
  final int level;
  final DateTime? lockedUntil;

  bool isLocked(DateTime now) =>
      lockedUntil != null && now.isBefore(lockedUntil!);

  LockoutState copyWith({int? failedAttempts, int? level, DateTime? lockedUntil}) =>
      LockoutState(
        failedAttempts: failedAttempts ?? this.failedAttempts,
        level: level ?? this.level,
        lockedUntil: lockedUntil ?? this.lockedUntil,
      );

  Map<String, dynamic> toJson() => {
        'failedAttempts': failedAttempts,
        'level': level,
        'lockedUntil': lockedUntil?.toIso8601String(),
      };

  factory LockoutState.fromJson(Map<String, dynamic> json) => LockoutState(
        failedAttempts: json['failedAttempts'] as int? ?? 0,
        level: json['level'] as int? ?? 0,
        lockedUntil: switch (json['lockedUntil']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  @override
  bool operator ==(Object other) =>
      other is LockoutState &&
      other.failedAttempts == failedAttempts &&
      other.level == level &&
      other.lockedUntil == lockedUntil;

  @override
  int get hashCode => Object.hash(failedAttempts, level, lockedUntil);
}
```

- [ ] **Step 5: `device_store.dart`**

```dart
import 'lockout_state.dart';
import 'remembered_user.dart';

/// Almacén local del dispositivo (usuario recordado + bloqueo). Nunca lanza:
/// ante error de lectura devuelve null / `const LockoutState()`.
abstract interface class DeviceStore {
  Future<RememberedUser?> readUser();
  Future<void> saveUser(RememberedUser user);
  Future<void> clearUser();

  Future<LockoutState> readLockout();
  Future<void> saveLockout(LockoutState state);
  Future<void> clearLockout();
}
```

- [ ] **Step 6: `memory_device_store.dart`**

```dart
import '../domain/device_store.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore en memoria (tests / fake).
class MemoryDeviceStore implements DeviceStore {
  MemoryDeviceStore({RememberedUser? user, LockoutState lockout = const LockoutState()})
      : _user = user,
        _lockout = lockout;

  RememberedUser? _user;
  LockoutState _lockout;

  @override
  Future<RememberedUser?> readUser() async => _user;

  @override
  Future<void> saveUser(RememberedUser user) async => _user = user;

  @override
  Future<void> clearUser() async => _user = null;

  @override
  Future<LockoutState> readLockout() async => _lockout;

  @override
  Future<void> saveLockout(LockoutState state) async => _lockout = state;

  @override
  Future<void> clearLockout() async => _lockout = const LockoutState();
}
```

- [ ] **Step 7: `secure_device_store.dart`**

```dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/device_store.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// DeviceStore cifrado (Keychain / EncryptedSharedPreferences). Usado en todos
/// los flavors (capacidad del dispositivo, no backend).
class SecureDeviceStore implements DeviceStore {
  const SecureDeviceStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _userKey = 'cuycash.remembered_user';
  static const _lockoutKey = 'cuycash.lockout';

  @override
  Future<RememberedUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return RememberedUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveUser(RememberedUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  @override
  Future<void> clearUser() => _storage.delete(key: _userKey);

  @override
  Future<LockoutState> readLockout() async {
    final raw = await _storage.read(key: _lockoutKey);
    if (raw == null) return const LockoutState();
    try {
      return LockoutState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const LockoutState();
    }
  }

  @override
  Future<void> saveLockout(LockoutState state) =>
      _storage.write(key: _lockoutKey, value: jsonEncode(state.toJson()));

  @override
  Future<void> clearLockout() => _storage.delete(key: _lockoutKey);
}
```

- [ ] **Step 8: `device_actions.dart`**

```dart
import '../domain/device_store.dart';
import '../domain/lockout_policy.dart';
import '../domain/lockout_state.dart';
import '../domain/remembered_user.dart';

/// Capa de aplicación del dispositivo. `registerFailedAttempt` encapsula el
/// escalonado de bloqueo (reloj inyectado por el llamador).
class DeviceActions {
  const DeviceActions(this._store);

  final DeviceStore _store;

  Future<RememberedUser?> readUser() => _store.readUser();
  Future<void> saveUser(RememberedUser user) => _store.saveUser(user);
  Future<void> clearUser() => _store.clearUser();
  Future<LockoutState> readLockout() => _store.readLockout();

  /// Registra un intento fallido. Al alcanzar `maxAttempts`, sube de nivel y
  /// fija `lockedUntil = now + duración(nivel)`, reiniciando el contador.
  Future<LockoutState> registerFailedAttempt(DateTime now) async {
    final current = await _store.readLockout();
    final attempts = current.failedAttempts + 1;
    final LockoutState next;
    if (attempts >= LockoutPolicy.maxAttempts) {
      final level = current.level + 1;
      next = LockoutState(
        failedAttempts: 0,
        level: level,
        lockedUntil: now.add(LockoutPolicy.durationForLevel(level)),
      );
    } else {
      next = current.copyWith(failedAttempts: attempts);
    }
    await _store.saveLockout(next);
    return next;
  }

  Future<void> resetLockout() => _store.clearLockout();
}
```

- [ ] **Step 9: Tests**

`apps/mobile/test/feature/device/memory_device_store_test.dart`:
```dart
import 'package:cuycash/feature/device/domain/lockout_state.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user save/read/clear', () async {
    final store = MemoryDeviceStore();
    expect(await store.readUser(), isNull);
    const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');
    await store.saveUser(user);
    expect(await store.readUser(), user);
    await store.clearUser();
    expect(await store.readUser(), isNull);
  });

  test('lockout save/read/clear', () async {
    final store = MemoryDeviceStore();
    expect(await store.readLockout(), const LockoutState());
    final locked = LockoutState(failedAttempts: 1, level: 0, lockedUntil: DateTime(2030));
    await store.saveLockout(locked);
    expect(await store.readLockout(), locked);
    await store.clearLockout();
    expect(await store.readLockout(), const LockoutState());
  });

  test('RememberedUser.initials', () {
    expect(const RememberedUser(dni: '1', fullName: 'Juan Pérez', alias: '@j').initials, 'JP');
    expect(const RememberedUser(dni: '1', fullName: 'Juan', alias: '@j').initials, 'J');
  });
}
```

`apps/mobile/test/feature/device/device_actions_test.dart`:
```dart
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 10, 0, 0);

  test('primer y segundo fallo suben failedAttempts sin bloquear', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    final s1 = await actions.registerFailedAttempt(t0);
    expect(s1.failedAttempts, 1);
    expect(s1.isLocked(t0), isFalse);
    final s2 = await actions.registerFailedAttempt(t0);
    expect(s2.failedAttempts, 2);
    expect(s2.isLocked(t0), isFalse);
  });

  test('tercer fallo bloquea 15 min (nivel 1) y reinicia el contador', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    await actions.registerFailedAttempt(t0);
    await actions.registerFailedAttempt(t0);
    final s3 = await actions.registerFailedAttempt(t0);
    expect(s3.level, 1);
    expect(s3.failedAttempts, 0);
    expect(s3.lockedUntil, t0.add(const Duration(minutes: 15)));
    expect(s3.isLocked(t0), isTrue);
    expect(s3.isLocked(t0.add(const Duration(minutes: 16))), isFalse);
  });

  test('segundo bloqueo escala a 1 h (nivel 2)', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    for (var i = 0; i < 3; i++) {
      await actions.registerFailedAttempt(t0);
    }
    for (var i = 0; i < 2; i++) {
      await actions.registerFailedAttempt(t0);
    }
    final s = await actions.registerFailedAttempt(t0);
    expect(s.level, 2);
    expect(s.lockedUntil, t0.add(const Duration(hours: 1)));
  });

  test('resetLockout limpia', () async {
    final actions = DeviceActions(MemoryDeviceStore());
    await actions.registerFailedAttempt(t0);
    await actions.resetLockout();
    final s = await actions.readLockout();
    expect(s.failedAttempts, 0);
    expect(s.lockedUntil, isNull);
  });
}
```

- [ ] **Step 10: Correr**

Run: `cd apps/mobile && flutter test test/feature/device/`
Expected: todos PASS. Run `flutter analyze lib/feature/device` → No issues.

- [ ] **Step 11: Commit**

```bash
git add apps/mobile/lib/feature/device apps/mobile/test/feature/device apps/mobile/pubspec.yaml pubspec.lock
git commit -m "feat: feature device (usuario recordado + bloqueo escalonado, secure storage)"
```

---

## Task 2: design_system — PinDots, PinKeypad, InitialsAvatar

**Files:**
- Create: `packages/design_system/lib/src/pin_dots.dart`
- Create: `packages/design_system/lib/src/pin_keypad.dart`
- Create: `packages/design_system/lib/src/initials_avatar.dart`
- Modify: `packages/design_system/lib/design_system.dart`
- Test: `packages/design_system/test/quick_access_components_test.dart`

**Interfaces:**
- Produces:
  - `PinDots({int count = 6, required int filled})`
  - `PinKeypad({required ValueChanged<int> onDigit, required VoidCallback onBackspace, VoidCallback? onBiometric})`
  - `InitialsAvatar({required String initials, double size = 72})`

- [ ] **Step 1: `pin_dots.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';

/// Indicador de PIN: `count` puntos; los primeros `filled` van rellenos.
class PinDots extends StatelessWidget {
  const PinDots({required this.filled, this.count = 6, super.key});

  final int filled;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isFilled = index < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? CuyCashColors.primaryContainer : null,
            border: isFilled
                ? null
                : Border.all(color: CuyCashColors.outlineVariant, width: 1.5),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: `pin_keypad.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Teclado numérico del acceso rápido (1-9, biométrico, 0, backspace).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      children: [
        for (var n = 1; n <= 9; n++) _DigitKey(digit: n, onTap: () => onDigit(n)),
        _biometricKey(),
        _DigitKey(digit: 0, onTap: () => onDigit(0)),
        _IconKey(
          icon: Icons.backspace_outlined,
          onTap: onBackspace,
          label: 'Borrar',
        ),
      ],
    );
  }

  Widget _biometricKey() {
    if (onBiometric == null) return const SizedBox.shrink();
    return Center(
      child: Material(
        color: CuyCashColors.primaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBiometric,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.fingerprint, color: CuyCashColors.onPrimary),
          ),
        ),
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onTap});
  final int digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Center(
        child: Text('$digit',
            style: CuyCashTypography.headlineMd
                .copyWith(color: CuyCashColors.primaryContainer)),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, required this.onTap, required this.label});
  final IconData icon;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Center(
        child: Icon(icon, color: CuyCashColors.primaryContainer, semanticLabel: label),
      ),
    );
  }
}
```

- [ ] **Step 3: `initials_avatar.dart`**

```dart
import 'package:flutter/material.dart';

import 'cuycash_colors.dart';
import 'cuycash_typography.dart';

/// Avatar circular con iniciales (para el acceso rápido).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.initials, this.size = 72, super.key});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CuyCashColors.surfaceContainerHighest,
      ),
      child: Text(initials,
          style: CuyCashTypography.headlineSm
              .copyWith(color: CuyCashColors.primaryContainer)),
    );
  }
}
```

- [ ] **Step 4: Exports en `design_system.dart`** (añadir, orden alfabético)

```dart
export 'src/initials_avatar.dart';
export 'src/pin_dots.dart';
export 'src/pin_keypad.dart';
```

- [ ] **Step 5: Test**

`packages/design_system/test/quick_access_components_test.dart`:
```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: CuyCashTheme.light(), home: Scaffold(body: child));

void main() {
  testWidgets('PinDots rellena los primeros N', (tester) async {
    await tester.pumpWidget(_wrap(const PinDots(filled: 2)));
    expect(find.byType(Container), findsNWidgets(6));
  });

  testWidgets('PinKeypad dispara dígito y backspace', (tester) async {
    final digits = <int>[];
    var back = 0;
    await tester.pumpWidget(_wrap(PinKeypad(
      onDigit: digits.add,
      onBackspace: () => back++,
      onBiometric: () {},
    )));
    await tester.tap(find.text('5'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(digits, [5]);
    expect(back, 1);
  });

  testWidgets('InitialsAvatar muestra iniciales', (tester) async {
    await tester.pumpWidget(_wrap(const InitialsAvatar(initials: 'JP')));
    expect(find.text('JP'), findsOneWidget);
  });
}
```

- [ ] **Step 6: Correr**

Run: `cd packages/design_system && flutter test`
Expected: todos PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/design_system
git commit -m "feat: design_system PinDots, PinKeypad, InitialsAvatar"
```

---

## Task 3: `AuthSession.fullName` + register lo incluye

**Files:**
- Modify: `apps/mobile/lib/feature/auth/domain/auth_session.dart`
- Modify: `apps/mobile/lib/feature/auth/infrastructure/memory_auth_repository.dart`
- Test: `apps/mobile/test/feature/auth/memory_auth_repository_test.dart`

**Interfaces:**
- Produces: `AuthSession { userId, identifier, alias?, fullName? }` (nuevo campo opcional). `register` devuelve la sesión con `fullName = '$nombres $apellidos'`.

- [ ] **Step 1: Añadir `fullName` a `auth_session.dart`**

```dart
/// Sesión autenticada.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.identifier,
    this.alias,
    this.fullName,
  });

  final String userId;
  final String identifier;
  final String? alias;
  final String? fullName;

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.identifier == identifier &&
      other.alias == alias &&
      other.fullName == fullName;

  @override
  int get hashCode => Object.hash(userId, identifier, alias, fullName);
}
```

- [ ] **Step 2: `register` incluye `fullName`**

En `memory_auth_repository.dart`, dentro de `register`, al construir la sesión:
```dart
    return right(AuthSession(
      userId: 'mem-${dni.hashCode}',
      identifier: dni,
      alias: _aliasFor(nombres, dni),
      fullName: '${nombres.trim()} ${apellidos.trim()}'.trim(),
    ));
```

- [ ] **Step 3: Test — register incluye fullName**

En `memory_auth_repository_test.dart`, en el test "register crea la cuenta …" añadir:
```dart
    expect(session?.fullName, 'Juan Carlos Pérez García');
```
(justo después del `expect(session?.alias, '@juan');`).

- [ ] **Step 4: Correr**

Run: `cd apps/mobile && flutter test test/feature/auth/memory_auth_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/feature/auth apps/mobile/test/feature/auth/memory_auth_repository_test.dart
git commit -m "feat: AuthSession.fullName (register lo incluye) para recordar el nombre"
```

---

## Task 4: `QuickAccessBloc`

**Files:**
- Create: `apps/mobile/lib/presentation/quick_access/bloc/quick_access_bloc.dart` (+ event/state + freezed)
- Test: `apps/mobile/test/presentation/quick_access/quick_access_bloc_test.dart`

**Interfaces:**
- Consumes: `AuthActions` (signIn, activate), `DeviceActions` (registerFailedAttempt, resetLockout), `RememberedUser`, `AuthSession`.
- Produces:
  - `enum QuickAccessStatus { idle, verifying }`
  - `QuickAccessState { RememberedUser user, String pin, QuickAccessStatus status, int attemptsLeft, bool lastWrong, DateTime? lockedUntil }`
  - Events: `QuickAccessDigitPressed(int)`, `QuickAccessBackspace()`, `QuickAccessBiometric()`
  - `QuickAccessBloc({required AuthActions auth, required DeviceActions device, required RememberedUser user, DateTime Function()? clock})`

- [ ] **Step 1: `quick_access_event.dart`**

```dart
part of 'quick_access_bloc.dart';

@freezed
sealed class QuickAccessEvent with _$QuickAccessEvent {
  const factory QuickAccessEvent.digitPressed(int digit) =
      QuickAccessDigitPressed;
  const factory QuickAccessEvent.backspace() = QuickAccessBackspace;
  const factory QuickAccessEvent.biometric() = QuickAccessBiometric;
}
```

- [ ] **Step 2: `quick_access_state.dart`**

```dart
part of 'quick_access_bloc.dart';

enum QuickAccessStatus { idle, verifying }

@freezed
abstract class QuickAccessState with _$QuickAccessState {
  const factory QuickAccessState({
    required RememberedUser user,
    @Default('') String pin,
    @Default(QuickAccessStatus.idle) QuickAccessStatus status,
    @Default(LockoutPolicy.maxAttempts) int attemptsLeft,
    @Default(false) bool lastWrong,
    DateTime? lockedUntil,
  }) = _QuickAccessState;
}
```

- [ ] **Step 3: `quick_access_bloc.dart`**

```dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_session.dart';
import '../../../feature/device/application/device_actions.dart';
import '../../../feature/device/domain/lockout_policy.dart';
import '../../../feature/device/domain/remembered_user.dart';

part 'quick_access_bloc.freezed.dart';
part 'quick_access_event.dart';
part 'quick_access_state.dart';

/// Acceso rápido: verifica el PIN del usuario recordado vía `AuthActions.signIn`
/// y gestiona intentos/bloqueo vía `DeviceActions`. En éxito no navega: la
/// sesión emitida llega al AuthBloc → gate → home. Al bloquear, expone
/// `lockedUntil` (la pantalla escucha y navega a /bloqueado).
class QuickAccessBloc extends Bloc<QuickAccessEvent, QuickAccessState> {
  QuickAccessBloc({
    required AuthActions auth,
    required DeviceActions device,
    required RememberedUser user,
    DateTime Function()? clock,
  })  : _auth = auth,
        _device = device,
        _now = clock ?? DateTime.now,
        super(QuickAccessState(user: user)) {
    on<QuickAccessDigitPressed>(_onDigit);
    on<QuickAccessBackspace>((event, emit) {
      if (state.pin.isNotEmpty && state.status == QuickAccessStatus.idle) {
        emit(state.copyWith(
            pin: state.pin.substring(0, state.pin.length - 1), lastWrong: false));
      }
    });
    on<QuickAccessBiometric>(_onBiometric);
  }

  final AuthActions _auth;
  final DeviceActions _device;
  final DateTime Function() _now;

  Future<void> _onDigit(
    QuickAccessDigitPressed event,
    Emitter<QuickAccessState> emit,
  ) async {
    if (state.status == QuickAccessStatus.verifying || state.pin.length >= 6) {
      return;
    }
    final pin = '${state.pin}${event.digit}';
    emit(state.copyWith(pin: pin, lastWrong: false));
    if (pin.length < 6) return;

    emit(state.copyWith(status: QuickAccessStatus.verifying));
    final result = await _auth.signIn(identifier: state.user.dni, pin: pin);
    await result.match(
      (failure) async {
        final lockout = await _device.registerFailedAttempt(_now());
        if (lockout.isLocked(_now())) {
          emit(state.copyWith(
              status: QuickAccessStatus.idle,
              pin: '',
              lockedUntil: lockout.lockedUntil));
        } else {
          emit(state.copyWith(
            status: QuickAccessStatus.idle,
            pin: '',
            lastWrong: true,
            attemptsLeft: LockoutPolicy.maxAttempts - lockout.failedAttempts,
          ));
        }
      },
      (_) async => _device.resetLockout(), // éxito → sesión por el stream → home
    );
  }

  Future<void> _onBiometric(
    QuickAccessBiometric event,
    Emitter<QuickAccessState> emit,
  ) async {
    // Biometría simulada: éxito inmediato → activa la sesión del recordado.
    await _device.resetLockout();
    await _auth.activate(AuthSession(
      userId: 'mem-${state.user.dni.hashCode}',
      identifier: state.user.dni,
      alias: state.user.alias,
      fullName: state.user.fullName,
    ));
  }
}
```

- [ ] **Step 4: Generar freezed**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `quick_access_bloc.freezed.dart` generado.

- [ ] **Step 5: Test**

`apps/mobile/test/presentation/quick_access/quick_access_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');
  final clock = () => DateTime(2026, 1, 1, 10);

  QuickAccessBloc build({MemoryAuthRepository? auth, MemoryDeviceStore? device}) =>
      QuickAccessBloc(
        auth: AuthActions(auth ?? MemoryAuthRepository()),
        device: DeviceActions(device ?? MemoryDeviceStore()),
        user: user,
        clock: clock,
      );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'dígitos acumulan el pin',
    build: build,
    act: (b) => b
      ..add(const QuickAccessEvent.digitPressed(1))
      ..add(const QuickAccessEvent.digitPressed(2)),
    verify: (b) => expect(b.state.pin, '12'),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'backspace borra el último dígito',
    build: build,
    act: (b) => b
      ..add(const QuickAccessEvent.digitPressed(1))
      ..add(const QuickAccessEvent.backspace()),
    verify: (b) => expect(b.state.pin, ''),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'PIN correcto (000000) autentica y limpia lockout',
    build: () {
      final device = MemoryDeviceStore();
      return QuickAccessBloc(
        auth: AuthActions(MemoryAuthRepository()),
        device: DeviceActions(device),
        user: user,
        clock: clock,
      );
    },
    act: (b) {
      for (final d in [0, 0, 0, 0, 0, 0]) {
        b.add(QuickAccessEvent.digitPressed(d));
      }
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.lockedUntil, isNull),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'PIN incorrecto baja attemptsLeft y limpia el pin',
    build: build,
    act: (b) {
      for (final d in [9, 9, 9, 9, 9, 9]) {
        b.add(QuickAccessEvent.digitPressed(d));
      }
    },
    wait: const Duration(milliseconds: 10),
    verify: (b) {
      expect(b.state.pin, '');
      expect(b.state.lastWrong, isTrue);
      expect(b.state.attemptsLeft, 2);
    },
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'tercer PIN incorrecto fija lockedUntil',
    build: () {
      final device = MemoryDeviceStore();
      return QuickAccessBloc(
        auth: AuthActions(MemoryAuthRepository()),
        device: DeviceActions(device),
        user: user,
        clock: clock,
      );
    },
    act: (b) async {
      for (var attempt = 0; attempt < 3; attempt++) {
        for (final d in [9, 9, 9, 9, 9, 9]) {
          b.add(QuickAccessEvent.digitPressed(d));
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    },
    wait: const Duration(milliseconds: 20),
    verify: (b) => expect(b.state.lockedUntil, isNotNull),
  );

  blocTest<QuickAccessBloc, QuickAccessState>(
    'biométrico autentica (activa sesión del recordado)',
    build: () {
      final auth = MemoryAuthRepository();
      final bloc = QuickAccessBloc(
        auth: AuthActions(auth),
        device: DeviceActions(MemoryDeviceStore()),
        user: user,
        clock: clock,
      );
      return bloc;
    },
    act: (b) => b.add(const QuickAccessEvent.biometric()),
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.status, QuickAccessStatus.idle),
  );
}
```

- [ ] **Step 6: Correr**

Run: `cd apps/mobile && flutter test test/presentation/quick_access/quick_access_bloc_test.dart`
Expected: todos PASS.

- [ ] **Step 7: Commit** (incluye `.freezed.dart`)

```bash
git add apps/mobile/lib/presentation/quick_access/bloc apps/mobile/test/presentation/quick_access/quick_access_bloc_test.dart
git commit -m "feat: QuickAccessBloc (PIN, intentos/bloqueo, biométrico simulado)"
```

---

## Task 5: Copy es-PE (acceso rápido, bloqueo, cambiar de usuario)

**Files:**
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Generated: `apps/mobile/lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces: getters l10n usados por las pantallas de este batch.

- [ ] **Step 1: Añadir claves** (respetar comas JSON)

```json
  "quickAccessGreeting": "Hola, {name}",
  "@quickAccessGreeting": { "placeholders": { "name": { "type": "String" } } },
  "quickAccessPrompt": "Ingresa tu PIN de seguridad",
  "notYou": "¿No eres {name}?",
  "@notYou": { "placeholders": { "name": { "type": "String" } } },
  "forgotPinAction": "Olvidé mi PIN",
  "pinWrongAttempts": "PIN incorrecto. Te quedan {n} intentos.",
  "@pinWrongAttempts": { "placeholders": { "n": { "type": "int" } } },
  "pinWrongHint": "Tras 3 intentos fallidos tu acceso se bloqueará por 15 minutos.",
  "blockedTitle": "Tu acceso está bloqueado",
  "blockedSubtitle": "Por tu seguridad bloqueamos el ingreso tras 3 intentos fallidos.",
  "blockedCountdownLabel": "Podrás intentarlo de nuevo en",
  "blockedRecoverPin": "Recuperar mi PIN",
  "blockedSupport": "Escribir a soporte por WhatsApp",
  "switchUserTitle": "¿Salir de esta cuenta?",
  "switchUserBody": "{name} tendrá que ingresar su DNI y su PIN de seguridad para volver a entrar en este teléfono.",
  "@switchUserBody": { "placeholders": { "name": { "type": "String" } } },
  "switchUserConsequenceBiometric": "Se desactivará el acceso con huella.",
  "switchUserConsequenceSession": "Se cerrará la sesión guardada en este dispositivo.",
  "switchUserConfirm": "Salir de esta cuenta",
  "cancel": "Cancelar",
```

- [ ] **Step 2: Generar**

Run: `cd apps/mobile && flutter gen-l10n`
Expected: sin errores. `flutter analyze lib/l10n` → No issues.

- [ ] **Step 3: Commit**

```bash
git add apps/mobile/lib/l10n
git commit -m "feat: copy es-PE de acceso rápido, bloqueo y cambiar de usuario"
```

---

## Task 6: `SwitchUserDialog`

**Files:**
- Create: `apps/mobile/lib/presentation/quick_access/widgets/switch_user_dialog.dart`
- Test: `apps/mobile/test/presentation/quick_access/switch_user_dialog_test.dart`

**Interfaces:**
- Consumes: l10n, design_system.
- Produces: `Future<bool?> showSwitchUserDialog(BuildContext context, {required String name})` → devuelve `true` si confirma salir.

- [ ] **Step 1: `switch_user_dialog.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Diálogo "¿Salir de esta cuenta?". Devuelve true si el usuario confirma.
Future<bool?> showSwitchUserDialog(BuildContext context, {required String name}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _SwitchUserDialog(name: name),
  );
}

class _SwitchUserDialog extends StatelessWidget {
  const _SwitchUserDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: CuyCashColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CuyCashColors.surfaceContainerHighest),
                child: const Icon(Icons.switch_account,
                    color: CuyCashColors.primaryContainer),
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Text(l10n.switchUserTitle,
                textAlign: TextAlign.center,
                style: CuyCashTypography.titleMd),
            const SizedBox(height: CuyCashSpacing.stackSm),
            Text(l10n.switchUserBody(name),
                textAlign: TextAlign.center,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(CuyCashRadii.input),
              ),
              child: Column(
                children: [
                  _consequence(Icons.fingerprint,
                      l10n.switchUserConsequenceBiometric),
                  const SizedBox(height: CuyCashSpacing.stackSm),
                  _consequence(Icons.shield_outlined,
                      l10n.switchUserConsequenceSession),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            PrimaryButton(
              label: l10n.switchUserConfirm,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: CuyCashSpacing.stackSm),
            GhostButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consequence(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CuyCashColors.secondaryText),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
              child: Text(text,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.onSurface))),
        ],
      );
}
```

- [ ] **Step 2: Test**

`apps/mobile/test/presentation/quick_access/switch_user_dialog_test.dart`:
```dart
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/widgets/switch_user_dialog.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el copy corregido (DNI y PIN) y confirma con true',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async =>
                  result = await showSwitchUserDialog(context, name: 'Juan'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('su DNI y su PIN de seguridad'), findsOneWidget);
    expect(find.textContaining('correo y contraseña'), findsNothing);
    await tester.tap(find.text('Salir de esta cuenta'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
```

- [ ] **Step 3: Correr**

Run: `cd apps/mobile && flutter test test/presentation/quick_access/switch_user_dialog_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/presentation/quick_access/widgets/switch_user_dialog.dart apps/mobile/test/presentation/quick_access/switch_user_dialog_test.dart
git commit -m "feat: diálogo cambiar de usuario (copy DNI + PIN corregido)"
```

---

## Task 7: `AccessBlockedScreen`

**Files:**
- Create: `apps/mobile/lib/presentation/quick_access/access_blocked_screen.dart`
- Test: `apps/mobile/test/presentation/quick_access/access_blocked_screen_test.dart`

**Interfaces:**
- Consumes: l10n, design_system, `AppRoutes`, go_router, `url_launcher`? NO — el WhatsApp queda como placeholder (onPressed vacío) para no añadir dependencia ahora.
- Produces: `AccessBlockedScreen({required DateTime lockedUntil, VoidCallback? onExpired})`.

- [ ] **Step 1: `access_blocked_screen.dart`**

```dart
import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Pantalla de acceso bloqueado con cuenta regresiva hasta [lockedUntil].
/// Al expirar invoca [onExpired] (el router decide a dónde volver).
class AccessBlockedScreen extends StatefulWidget {
  const AccessBlockedScreen({
    required this.lockedUntil,
    this.onExpired,
    super.key,
  });

  final DateTime lockedUntil;
  final VoidCallback? onExpired;

  @override
  State<AccessBlockedScreen> createState() => _AccessBlockedScreenState();
}

class _AccessBlockedScreenState extends State<AccessBlockedScreen> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = _computeRemaining();
      if (left <= Duration.zero) {
        _timer?.cancel();
        widget.onExpired?.call();
      }
      if (mounted) setState(() => _remaining = left);
    });
  }

  Duration _computeRemaining() {
    final left = widget.lockedUntil.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final totalMinutes = _remaining.inMinutes;
    final hours = _remaining.inHours;
    if (hours >= 1) {
      final mm = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
      return '${hours.toString().padLeft(2, '0')}:$mm';
    }
    final mm = totalMinutes.toString().padLeft(2, '0');
    final ss = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CuyCashColors.error.withValues(alpha: 0.10)),
                child: const Icon(Icons.lock_outline,
                    size: 36, color: CuyCashColors.error),
              ),
              const SizedBox(height: CuyCashSpacing.stackLg),
              Text(l10n.blockedTitle,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.headlineSm),
              const SizedBox(height: CuyCashSpacing.stackSm),
              Text(l10n.blockedSubtitle,
                  textAlign: TextAlign.center,
                  style: CuyCashTypography.bodyLg
                      .copyWith(color: CuyCashColors.secondaryText)),
              const SizedBox(height: CuyCashSpacing.stackXl),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CuyCashColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(CuyCashRadii.card),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(l10n.blockedCountdownLabel,
                          style: CuyCashTypography.bodyMd
                              .copyWith(color: CuyCashColors.secondaryText)),
                    ),
                    Text(_formatted,
                        style: CuyCashTypography.headlineMd.copyWith(
                            color: CuyCashColors.primaryContainer,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(label: l10n.blockedRecoverPin, onPressed: () {}),
              const SizedBox(height: CuyCashSpacing.stackSm),
              GhostButton(label: l10n.blockedSupport, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
```

> Nota: `Duration.inMinutes` es la API correcta; `_remaining.inMinutes` (no `inMinutes` mal escrito). Corregir cualquier typo: usar `_remaining.inMinutes`, `_remaining.inHours`, `_remaining.inSeconds`. `FontFeature` viene de `dart:ui`; añadir `import 'dart:ui' show FontFeature;` si el analyzer no lo resuelve vía material.

- [ ] **Step 2: Test**

`apps/mobile/test/presentation/quick_access/access_blocked_screen_test.dart`:
```dart
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/access_blocked_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra título y cuenta regresiva', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: CuyCashTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccessBlockedScreen(
        lockedUntil: DateTime.now().add(const Duration(minutes: 15)),
      ),
    ));
    await tester.pump();
    expect(find.text('Tu acceso está bloqueado'), findsOneWidget);
    expect(find.textContaining(':'), findsWidgets); // countdown mm:ss / hh:mm
  });
}
```

- [ ] **Step 3: Correr**

Run: `cd apps/mobile && flutter test test/presentation/quick_access/access_blocked_screen_test.dart`
Expected: PASS. (No usar `pumpAndSettle` — hay un Timer periódico; usar `pump()`.)

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/presentation/quick_access/access_blocked_screen.dart apps/mobile/test/presentation/quick_access/access_blocked_screen_test.dart
git commit -m "feat: pantalla de acceso bloqueado con cuenta regresiva"
```

---

## Task 8: `QuickAccessScreen`

**Files:**
- Create: `apps/mobile/lib/presentation/quick_access/quick_access_screen.dart`
- Test: `apps/mobile/test/presentation/quick_access/quick_access_screen_test.dart`

**Interfaces:**
- Consumes: `QuickAccessBloc`, design_system (`InitialsAvatar`, `PinDots`, `PinKeypad`, `GhostButton`), l10n, `AppRoutes`, go_router, `showSwitchUserDialog`, `DeviceActions` (para "¿No eres X?"/switch), `AuthActions` (signOut).
- Produces: `QuickAccessScreen()` (el `QuickAccessBloc` lo provee la ruta).

- [ ] **Step 1: `quick_access_screen.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../feature/auth/application/auth_actions.dart';
import '../../feature/device/application/device_actions.dart';
import '../../l10n/app_localizations.dart';
import '../app/app_routes.dart';
import 'bloc/quick_access_bloc.dart';
import 'widgets/switch_user_dialog.dart';

/// Acceso rápido para el usuario recordado en este dispositivo.
class QuickAccessScreen extends StatelessWidget {
  const QuickAccessScreen({super.key});

  Future<void> _switchUser(BuildContext context, String name) async {
    final confirmed = await showSwitchUserDialog(context, name: name);
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthActions>().signOut();
    await context.read<DeviceActions>().clearUser();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: CuyCashColors.surfaceContainerLow,
      body: SafeArea(
        child: BlocConsumer<QuickAccessBloc, QuickAccessState>(
          listenWhen: (p, c) => p.lockedUntil != c.lockedUntil && c.lockedUntil != null,
          listener: (context, state) => context.go(AppRoutes.blocked),
          builder: (context, state) {
            final bloc = context.read<QuickAccessBloc>();
            final user = state.user;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(CuyCashSpacing.stackSm),
                    child: GhostButton(
                      label: l10n.notYou(user.firstName),
                      onPressed: () => _switchUser(context, user.firstName),
                    ),
                  ),
                ),
                const SizedBox(height: CuyCashSpacing.stackLg),
                InitialsAvatar(initials: user.initials),
                const SizedBox(height: CuyCashSpacing.stackMd),
                Text(l10n.quickAccessGreeting(user.firstName),
                    style: CuyCashTypography.headlineSm),
                const SizedBox(height: CuyCashSpacing.stackXs),
                Text(l10n.quickAccessPrompt,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.secondaryText)),
                const SizedBox(height: CuyCashSpacing.stackXl),
                PinDots(filled: state.pin.length),
                const SizedBox(height: CuyCashSpacing.stackLg),
                if (state.lastWrong)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: CuyCashSpacing.marginMobile),
                    child: _ErrorBanner(
                      title: l10n.pinWrongAttempts(state.attemptsLeft),
                      hint: l10n.pinWrongHint,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CuyCashSpacing.stackLg),
                  child: PinKeypad(
                    onDigit: (d) =>
                        bloc.add(QuickAccessEvent.digitPressed(d)),
                    onBackspace: () =>
                        bloc.add(const QuickAccessEvent.backspace()),
                    onBiometric: () =>
                        bloc.add(const QuickAccessEvent.biometric()),
                  ),
                ),
                const SizedBox(height: CuyCashSpacing.stackSm),
                GhostButton(label: l10n.forgotPinAction, onPressed: () {}),
                const SizedBox(height: CuyCashSpacing.stackSm),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuyCashColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 18, color: CuyCashColors.error),
              const SizedBox(width: CuyCashSpacing.stackSm),
              Flexible(
                child: Text(title,
                    style: CuyCashTypography.bodyMd.copyWith(
                        color: CuyCashColors.error,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: CuyCashSpacing.stackXs),
          Text(hint,
              textAlign: TextAlign.center,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.secondaryText)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Test**

`apps/mobile/test/presentation/quick_access/quick_access_screen_test.dart`:
```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/feature/device/application/device_actions.dart';
import 'package:cuycash/feature/device/infrastructure/memory_device_store.dart';
import 'package:cuycash/feature/device/domain/remembered_user.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/quick_access/bloc/quick_access_bloc.dart';
import 'package:cuycash/presentation/quick_access/quick_access_screen.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = RememberedUser(dni: '12345678', fullName: 'Juan Pérez', alias: '@juan');

  testWidgets('saluda y el keypad llena los dots', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = QuickAccessBloc(
      auth: AuthActions(MemoryAuthRepository()),
      device: DeviceActions(MemoryDeviceStore()),
      user: user,
      clock: () => DateTime(2026),
    );
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        theme: CuyCashTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const QuickAccessScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Juan'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(bloc.state.pin, '1');
  });
}
```

- [ ] **Step 3: Correr**

Run: `cd apps/mobile && flutter test test/presentation/quick_access/quick_access_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/presentation/quick_access/quick_access_screen.dart apps/mobile/test/presentation/quick_access/quick_access_screen_test.dart
git commit -m "feat: pantalla de acceso rápido (keypad, dots, biométrico, ¿no eres tú?)"
```

---

## Task 9: Integración — DI, rutas, splash, gate, guardar recordado, perfil, login lockout

**Files:**
- Modify: `apps/mobile/lib/core/injection/app_dependencies.dart` (+ `DeviceStore deviceStore`)
- Create: `apps/mobile/lib/core/injection/modules/device_module.dart`
- Modify: `apps/mobile/lib/core/injection/envs/mock_dependencies.dart` (+ SecureDeviceStore)
- Modify: `apps/mobile/lib/core/injection/envs/shared/shared_supabase_dependencies.dart` (+ SecureDeviceStore)
- Modify: `apps/mobile/lib/presentation/app/app_routes.dart` (+ quickAccess, blocked)
- Modify: `apps/mobile/lib/presentation/app/app_redirect.dart` (gate: permitir quickAccess+blocked sin auth)
- Modify: `apps/mobile/lib/presentation/app/app_root.dart` (RepositoryProvider<AuthActions>+<DeviceActions>; guardar recordado al autenticar)
- Modify: `apps/mobile/lib/presentation/app/router.dart` (rutas quickAccess/blocked + provider del QuickAccessBloc)
- Modify: `apps/mobile/lib/presentation/splash/splash_screen.dart` (decidir ruta inicial)
- Modify: `apps/mobile/lib/presentation/profile/profile_screen.dart` ("cerrar sesión" → SwitchUserDialog + clearUser)
- Test: `apps/mobile/test/presentation/app/app_redirect_test.dart` (casos nuevos)

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: `AppRoutes.quickAccess='/acceso-rapido'`, `AppRoutes.blocked='/bloqueado'`; `DeviceModule.create(AppDependencies)→DeviceActions`; `AppDependencies.deviceStore`.

- [ ] **Step 1: `AppDependencies` + `DeviceModule`**

En `app_dependencies.dart` añadir el import de `DeviceStore` y el campo:
```dart
import '../../feature/device/domain/device_store.dart';
```
```dart
    required this.authRepository,
    required this.deviceStore,
```
```dart
  final AuthRepository authRepository;
  final DeviceStore deviceStore;
```

`device_module.dart`:
```dart
import '../../../feature/device/application/device_actions.dart';
import '../app_dependencies.dart';

abstract final class DeviceModule {
  static DeviceActions create(AppDependencies deps) =>
      DeviceActions(deps.deviceStore);
}
```

- [ ] **Step 2: Cablear SecureDeviceStore en los envs**

En `envs/mock_dependencies.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../feature/device/infrastructure/secure_device_store.dart';
```
y en el `AppDependencies(...)`:
```dart
      authRepository: MemoryAuthRepository(),
      deviceStore: const SecureDeviceStore(FlutterSecureStorage()),
```
En `envs/shared/shared_supabase_dependencies.dart`, igual: importar y añadir `deviceStore: const SecureDeviceStore(FlutterSecureStorage())` al `AppDependencies(...)`.

- [ ] **Step 3: `AppRoutes` + gate**

En `app_routes.dart`:
```dart
  static const quickAccess = '/acceso-rapido';
  static const blocked = '/bloqueado';
```
En `app_redirect.dart`, añadir al set de gate:
```dart
const _gateLocations = {
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.registro,
  AppRoutes.quickAccess,
  AppRoutes.blocked,
};
```
(La lógica existente ya trata: no-auth fuera de gate → onboarding; auth en gate → home.)

- [ ] **Step 4: Test del gate (casos nuevos)**

Añadir a `app_redirect_test.dart`:
```dart
  test('no autenticado en acceso rápido / bloqueado → sin redirect', () {
    expect(appRedirect(unauthed, AppRoutes.quickAccess), isNull);
    expect(appRedirect(unauthed, AppRoutes.blocked), isNull);
  });
  test('autenticado en acceso rápido → /home', () {
    expect(appRedirect(authed, AppRoutes.quickAccess), AppRoutes.home);
  });
```

- [ ] **Step 5: Splash decide la ruta inicial**

Reemplazar el cuerpo de `_SplashScreenState` para leer `DeviceActions` y decidir:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../feature/device/application/device_actions.dart';
...
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final device = context.read<DeviceActions>();
    final lockout = await device.readLockout();
    final user = await device.readUser();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (lockout.isLocked(DateTime.now())) {
      context.go(AppRoutes.blocked);
    } else if (user != null) {
      context.go(AppRoutes.quickAccess);
    } else {
      context.go(AppRoutes.onboarding);
    }
  }
```
(Quitar el `Timer` anterior; el delay corto mantiene el splash visible.)

- [ ] **Step 6: `AppRoot` — proveer AuthActions/DeviceActions + guardar recordado**

En `app_root.dart`, envolver con `MultiRepositoryProvider` que exponga `AppFlavor`, `AuthActions` y `DeviceActions`, y un `BlocListener<AuthBloc, AuthState>` que, al quedar `AuthAuthenticated`, guarde el `RememberedUser`:
```dart
// providers:
RepositoryProvider<AuthActions>.value(value: AuthActions(dependencies.authRepository)),
RepositoryProvider<DeviceActions>.value(value: DeviceModule.create(dependencies)),
// listener (envolviendo CuyCashApp):
BlocListener<AuthBloc, AuthState>(
  listenWhen: (p, c) => c is AuthAuthenticated,
  listener: (context, state) {
    if (state is! AuthAuthenticated) return;
    final s = state.session;
    context.read<DeviceActions>().saveUser(RememberedUser(
      dni: s.identifier,
      fullName: s.fullName ?? '',
      alias: s.alias ?? '@${s.identifier}',
    ));
  },
  child: CuyCashApp(dependencies: dependencies),
),
```
(Importar `AuthActions`, `DeviceActions`, `DeviceModule`, `RememberedUser`, `auth_bloc`.)

- [ ] **Step 7: Router — rutas quickAccess/blocked + provider**

En `router.dart` añadir imports (`QuickAccessBloc`, `QuickAccessScreen`, `AccessBlockedScreen`, `DeviceModule`, `AuthActions`, `flutter_bloc`, `RememberedUser`, `DeviceActions`) y las rutas. `/acceso-rapido` necesita el `RememberedUser`; se obtiene de forma síncrona no disponible aquí, así que el `QuickAccessScreen` se envuelve con un `FutureBuilder` sobre `DeviceModule.create(deps).readUser()`:
```dart
GoRoute(
  path: AppRoutes.quickAccess,
  builder: (context, state) {
    final device = DeviceModule.create(deps);
    return FutureBuilder(
      future: device.readUser(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) return const SplashScreen();
        return BlocProvider(
          create: (_) => QuickAccessBloc(
            auth: AuthActions(deps.authRepository),
            device: device,
            user: user,
          ),
          child: const QuickAccessScreen(),
        );
      },
    );
  },
),
GoRoute(
  path: AppRoutes.blocked,
  builder: (context, state) {
    final device = DeviceModule.create(deps);
    return FutureBuilder(
      future: device.readLockout(),
      builder: (context, snap) {
        final until = snap.data?.lockedUntil;
        if (until == null) return const SplashScreen();
        return AccessBlockedScreen(
          lockedUntil: until,
          onExpired: () => context.go(AppRoutes.quickAccess),
        );
      },
    );
  },
),
```

- [ ] **Step 8: Perfil — "cerrar sesión" abre el diálogo**

En `profile_screen.dart`, cambiar el `onPressed` del `SecondaryButton` para abrir el diálogo y, si confirma, cerrar sesión + limpiar recordado:
```dart
onPressed: () async {
  final name = state is AuthAuthenticated ? state.session.identifier : '';
  final confirmed = await showSwitchUserDialog(context, name: name);
  if (confirmed != true || !context.mounted) return;
  context.read<AuthBloc>().add(const AuthEvent.signedOut());
  await context.read<DeviceActions>().clearUser();
},
```
(Importar `showSwitchUserDialog`, `DeviceActions`.)

- [ ] **Step 9: Analyze + suite + build**

Run (foreground, esperar cada uno):
```bash
cd /Users/jairconislla/Projects/cuycash && flutter pub get
cd apps/mobile && flutter analyze
cd /Users/jairconislla/Projects/cuycash/packages/core_kernel && dart test
cd /Users/jairconislla/Projects/cuycash/packages/design_system && flutter test
cd /Users/jairconislla/Projects/cuycash/apps/mobile && flutter test
cd /Users/jairconislla/Projects/cuycash/apps/mobile && flutter build apk --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json --debug
```
Expected: analyze limpio, toda la suite verde, APK compila (con flutter_secure_storage + share_plus).

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: integra acceso rápido/bloqueo — DI, rutas, splash, gate, recordar usuario, perfil"
```

---

## Self-Review

**1. Spec coverage:**
- Feature device (RememberedUser, LockoutState, DeviceStore, secure+memory, DeviceActions) → Task 1. ✓
- Escalonado 15m/1h/24h → Task 1 (LockoutPolicy + DeviceActions.registerFailedAttempt). ✓
- Componentes (PinKeypad, PinDots, InitialsAvatar) → Task 2. ✓
- QuickAccessBloc (pin, intentos, bloqueo, biométrico sim, reloj inyectado) → Task 4. ✓
- Acceso rápido pantalla → Task 8. Bloqueado → Task 7. Cambiar de usuario → Task 6. ✓
- Copy es-PE → Task 5. ✓
- Splash decide, gate, rutas, guardar recordado, login (via AuthBloc)/perfil → Task 9. ✓
- AuthSession.fullName para recordar nombre → Task 3. ✓
- flutter_secure_storage en todos los flavors → Task 1 (dep) + Task 9 (cableado). ✓

**Cobertura parcial anotada:** el spec dice que el login DNI+PIN también cuenta intentos/bloqueo. Este plan implementa el conteo/bloqueo en el ACCESO RÁPIDO (y el splash/gate/bloqueado). Para el login DNI+PIN, el guardado del recordado ocurre al autenticar; el conteo de intentos en login se puede añadir enganchando `DeviceActions.registerFailedAttempt` a los errores del `AuthBloc` en `login_screen`, pero se DEFIERE a una tarea aparte para no inflar la integración (el login es el flujo que realmente necesita rate-limit de servidor). Registrado como follow-up en el hand-off.

**2. Placeholder scan:** "Olvidé mi PIN", "Recuperar mi PIN" y "Escribir a soporte por WhatsApp" quedan como `onPressed: () {}` (placeholders de UI deliberados: los flujos de recuperación/soporte no existen aún). No hay TODO/TBD en código de lógica. El typo señalado en Task 7 (`inMinutes`) trae su corrección explícita.

**3. Type consistency:** `DeviceStore`/`DeviceActions` con las mismas firmas en domain/infra/application/tests. `RememberedUser{dni,fullName,alias}` + `initials`/`firstName` usados consistentes. `LockoutState{failedAttempts,level,lockedUntil}` + `isLocked`. `QuickAccessState{user,pin,status,attemptsLeft,lastWrong,lockedUntil}` consistente entre bloc y pantalla. `AppRoutes.quickAccess`/`blocked`. `AuthSession.fullName` añadido en Task 3 y consumido en Task 6/9. `DeviceModule.create(deps)`.

**Nota de orden:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 (dependencias: device y AuthSession.fullName antes del bloc; l10n antes de las pantallas; todo antes de la integración).
