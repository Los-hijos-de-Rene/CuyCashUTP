# CuyCash — Wizard de registro (4 pasos) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el stub de registro por un wizard de 4 pasos (Datos → Documento → Rostro → Seguridad) con `RegisterBloc`, migrando el PIN a 6 dígitos y el `register` al perfil completo.

**Architecture:** Un `RegisterBloc` (freezed) mantiene `RegisterDraft` + paso + errores y hace el submit final vía `AuthActions.register`. `RegisterFlowScreen` conmuta 4 widgets de paso con `IndexedStack`. La navegación al éxito la hace el gate del router existente (la sesión llega por el stream de auth → `AuthBloc` → `/home`). Captura de documento y reconocimiento facial simulados en flavor `mock`.

**Tech Stack:** Flutter, flutter_bloc, freezed, bloc_test, go_router, fpdart, design_system, core_kernel.

**Spec:** `docs/superpowers/specs/2026-09-06-cuycash-register-wizard-design.md`

## Global Constraints

- Errores como valores (`Either`+`GlobalFailure`); ningún `throw` cruza capas; failures sellados.
- `Memory*` funcional = backend `mock` + contrato de tests. Use case/bloc sin test = incompleto.
- Estados de FEATURE sealed + `switch` exhaustivo; prohibido `when`/`maybeWhen`/`orElse`/`!` sobre estados. (El estado del wizard es un data-class freezed de una sola forma — válido para estado de formulario.)
- El Bloc consume la capa `application` (`AuthActions`) por constructor, nunca el repo.
- DI por constructor; composición raíz por flavor.
- Tokens del design system; cero hex sueltos en widgets — EXCEPCIÓN documentada: el paso 3 (Rostro) es una pantalla inmersiva oscura; sus colores viven como tokens nuevos en `CuyCashColors` (nada hardcodeado en el widget).
- Copy es-PE en ARB; cero strings de UI hardcodeados. Marca "CuyCash".
- `.freezed.dart` se commitea. Codegen: `dart run build_runner build --delete-conflicting-outputs` (desde `apps/mobile`).
- Un widget público por archivo; piezas propias en `presentation/register/widgets/`.
- **PIN = 6 dígitos** en toda la app.
- Analyze scoped por task (el whole-project analyze debe quedar limpio; ya no hay `main.dart` autogenerado). Commits en español.

---

## File Structure

```
packages/design_system/lib/src/
  cuycash_text_field.dart        # + prefixIcon
  cuycash_colors.dart            # + tokens inmersivos (paso 3)

apps/mobile/lib/
  feature/auth/domain/auth_repository.dart         # register(...) firma nueva
  feature/auth/infrastructure/memory_auth_repository.dart   # PIN6 + register nuevo
  feature/auth/infrastructure/supabase_auth_repository.dart # firma nueva (skeleton)
  feature/auth/application/auth_actions.dart       # register(...) delega nuevo
  presentation/auth/bloc/auth_bloc.dart            # quita register
  presentation/auth/login_screen.dart              # PIN 6
  presentation/register/bloc/register_bloc.dart    # + register_event.dart, register_state.dart, register_bloc.freezed.dart
  presentation/register/register_flow_screen.dart
  presentation/register/widgets/
    register_progress_bar.dart
    register_data_step.dart
    register_document_step.dart
    document_capture_card.dart
    register_face_step.dart
    face_scan_ring.dart
    register_pin_step.dart
    pin_boxes.dart
    register_error_banner.dart
  core/injection/modules/register_module.dart      # provee RegisterBloc por deps
  presentation/app/router.dart                     # /registro → RegisterFlowScreen (BlocProvider)
  l10n/arb/app_es.arb                              # copy del wizard + errorWeakPin 6

apps/mobile/test/
  feature/auth/memory_auth_repository_test.dart    # PIN6 + register nuevo
  presentation/auth/auth_bloc_test.dart            # sin register
  presentation/auth/login_screen_test.dart         # PIN6
  presentation/register/register_bloc_test.dart
  presentation/register/register_data_step_test.dart
  presentation/register/register_document_step_test.dart
  presentation/register/register_pin_step_test.dart
```

Se elimina `presentation/auth/register_screen.dart` (stub) y su uso.

---

## Task 1: `register` perfil completo + PIN 6 dígitos (domain/infra/application)

**Files:**
- Modify: `apps/mobile/lib/feature/auth/domain/auth_repository.dart`
- Modify: `apps/mobile/lib/feature/auth/infrastructure/memory_auth_repository.dart`
- Modify: `apps/mobile/lib/feature/auth/infrastructure/supabase_auth_repository.dart`
- Modify: `apps/mobile/lib/feature/auth/application/auth_actions.dart`
- Test: `apps/mobile/test/feature/auth/memory_auth_repository_test.dart`

**Interfaces:**
- Produces:
  - `AuthRepository.register({required String dni, required String nombres, required String apellidos, required String email, required String pin}) → FutureResult<AuthFailure, AuthSession>` (se elimina `alias`).
  - `MemoryAuthRepository({AuthSession? initial, String validPin = '000000'})`, PIN válido = 6 dígitos.
  - `AuthActions.register({dni, nombres, apellidos, email, pin})`.

- [ ] **Step 1: Actualizar el test de contrato (RED)**

Reemplazar en `apps/mobile/test/feature/auth/memory_auth_repository_test.dart` los tests de `register` y el signIn PIN por la firma/PIN nuevos:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:cuycash/feature/auth/domain/auth_failure.dart';
import 'package:cuycash/feature/auth/domain/auth_session.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signIn con PIN válido (6) → sesión y la emite', () async {
    final repo = MemoryAuthRepository();
    final emissions = <AuthSession?>[];
    repo.sessionChanges().listen(emissions.add);
    final result = await repo.signIn(identifier: '12345678', pin: '000000');
    expect(result.isRight(), isTrue);
    expect(repo.currentSession, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.single, isA<AuthSession>());
  });

  test('signIn con PIN inválido → InvalidCredentials', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.signIn(identifier: '12345678', pin: '999999');
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<InvalidCredentials>()),
    );
  });

  test('register perfil completo con PIN 6 → sesión (identifier = dni)', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(
      dni: '87654321',
      nombres: 'Juan Carlos',
      apellidos: 'Pérez García',
      email: 'juan@correo.com',
      pin: '024689',
    );
    expect(result.isRight(), isTrue);
    expect(repo.currentSession?.identifier, '87654321');
  });

  test('register con PIN de 5 dígitos → WeakPin', () async {
    final repo = MemoryAuthRepository();
    final result = await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '12345',
    );
    expect(
      result.getLeft().toNullable(),
      isA<ServerFailure<AuthFailure>>()
          .having((f) => f.failure, 'failure', isA<WeakPin>()),
    );
  });

  test('register con DNI ya registrado → IdentifierTaken', () async {
    final repo = MemoryAuthRepository();
    await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '024689',
    );
    await repo.signOut();
    final result = await repo.register(
      dni: '87654321', nombres: 'A', apellidos: 'B',
      email: 'a@b.pe', pin: '024689',
    );
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

- [ ] **Step 2: Correr el test (RED)**

Run: `cd apps/mobile && flutter test test/feature/auth/memory_auth_repository_test.dart`
Expected: FAIL de compilación (firma de `register` vieja / `validPin` 4).

- [ ] **Step 3: Actualizar `auth_repository.dart`**

Reemplazar el método `register` de la interfaz por:

```dart
  /// Registra una cuenta nueva con el perfil completo (DNI + datos + PIN 6).
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  });
```

- [ ] **Step 4: Actualizar `memory_auth_repository.dart`**

Cambiar el default de `validPin`, la regex, y el `register`:

```dart
  MemoryAuthRepository({AuthSession? initial, this.validPin = '000000'})
      : _session = initial {
    if (initial != null) _registered.add(initial.identifier);
  }

  final String validPin;
  AuthSession? _session;
  final Set<String> _registered = {};
  final _controller = StreamController<AuthSession?>.broadcast();

  static final _pinFormat = RegExp(r'^\d{6}$');
```

```dart
  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
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
        AuthSession(userId: 'mem-${dni.hashCode}', identifier: dni);
    _emit(session);
    return right(session);
  }
```

(`signIn` queda igual; ya compara con `validPin`, ahora '000000'.)

- [ ] **Step 5: Actualizar `supabase_auth_repository.dart`** (esqueleto, firma nueva)

```dart
  @override
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  }) async =>
      left(const GlobalFailure.server(AuthFailure.authUnavailable()));
```

- [ ] **Step 6: Actualizar `auth_actions.dart`**

```dart
  FutureResult<AuthFailure, AuthSession> register({
    required String dni,
    required String nombres,
    required String apellidos,
    required String email,
    required String pin,
  }) =>
      _repo.register(
        dni: dni, nombres: nombres, apellidos: apellidos, email: email, pin: pin);
```

- [ ] **Step 7: Correr el test (GREEN)**

Run: `cd apps/mobile && flutter test test/feature/auth/memory_auth_repository_test.dart`
Expected: 6 tests PASS.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/feature/auth apps/mobile/test/feature/auth/memory_auth_repository_test.dart
git commit -m "feat: register con perfil completo + PIN de 6 dígitos (memory contract)"
```

---

## Task 2: Quitar register de AuthBloc + regresión login/l10n (PIN 6)

**Files:**
- Modify: `apps/mobile/lib/presentation/auth/bloc/auth_bloc.dart`
- Modify: `apps/mobile/lib/presentation/auth/bloc/auth_event.dart`
- Modify: `apps/mobile/lib/presentation/auth/login_screen.dart`
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Test: `apps/mobile/test/presentation/auth/auth_bloc_test.dart`
- Test: `apps/mobile/test/presentation/auth/login_screen_test.dart`

**Interfaces:**
- Consumes: `AuthActions` (ya sin usar register en AuthBloc).
- Produces: `AuthEvent` sin `registerSubmitted`; `AuthError` intacto (lo reusará `RegisterBloc`); `authErrorText` intacto.

- [ ] **Step 1: Quitar el evento register de `auth_event.dart`**

Eliminar la factory:

```dart
  const factory AuthEvent.registerSubmitted({
    required String dni,
    String? alias,
    required String pin,
  }) = AuthRegisterSubmitted;
```

- [ ] **Step 2: Quitar el handler de `auth_bloc.dart`**

Eliminar `on<AuthRegisterSubmitted>(_onRegisterSubmitted);` del constructor y el método `_onRegisterSubmitted(...)` completo. Dejar login, signOut, sessionChanged y `_errorFor` intactos.

- [ ] **Step 3: Regenerar freezed**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `auth_bloc.freezed.dart` se regenera sin `AuthRegisterSubmitted`.

- [ ] **Step 4: Actualizar `auth_bloc_test.dart`**

Eliminar el `blocTest` `'register correcto → AuthAuthenticated'`. El resto queda igual.

- [ ] **Step 5: Login a PIN 6**

En `login_screen.dart`, cambiar el hint del PIN:

```dart
                CuyCashTextField(
                  label: l10n.pinLabel,
                  hint: '••••••',
                  controller: _pin,
                  obscure: true,
                  keyboardType: TextInputType.number,
                  errorText: error == null ? null : authErrorText(l10n, error),
                ),
```

- [ ] **Step 6: Copy es-PE (PIN 6)**

En `app_es.arb`, cambiar:

```json
  "errorWeakPin": "El PIN debe tener 6 dígitos.",
```

Regenerar l10n: `cd apps/mobile && flutter gen-l10n`.

- [ ] **Step 7: Actualizar `login_screen_test.dart`**

El test de login válido usa PIN `'0000'` → cambiarlo a `'000000'`:

```dart
    await tester.enterText(find.byType(TextField).last, '000000');
```

- [ ] **Step 8: Correr tests**

Run: `cd apps/mobile && flutter test test/presentation/auth/`
Expected: auth_bloc_test + login_screen_test PASS.

- [ ] **Step 9: Commit** (incluye `.freezed.dart` + l10n)

```bash
git add apps/mobile/lib/presentation/auth apps/mobile/lib/l10n apps/mobile/test/presentation/auth
git commit -m "refactor: registro sale de AuthBloc; login y copy a PIN de 6 dígitos"
```

---

## Task 3: design_system — `prefixIcon` en input + tokens inmersivos

**Files:**
- Modify: `packages/design_system/lib/src/cuycash_text_field.dart`
- Modify: `packages/design_system/lib/src/cuycash_colors.dart`
- Test: `packages/design_system/test/components_test.dart`

**Interfaces:**
- Produces:
  - `CuyCashTextField(..., IconData? prefixIcon, int? maxLength, String? helperText)`.
  - `CuyCashColors.immersiveDark = Color(0xFF121712)`, `immersiveOnDark = Color(0xFFF3F1EA)`, `immersiveMuted = Color(0xFFA3ACA0)`, `immersiveOcre = Color(0xFFE5A34E)`, `immersivePanel = Color(0xFF1D2620)`.

- [ ] **Step 1: Añadir tokens inmersivos a `cuycash_colors.dart`**

Antes del cierre de la clase, agregar:

```dart
  // Paso inmersivo (reconocimiento facial): tema oscuro local, DESIGN.md.
  static const immersiveDark = Color(0xFF121712);
  static const immersiveOnDark = Color(0xFFF3F1EA);
  static const immersiveMuted = Color(0xFFA3ACA0);
  static const immersiveOcre = Color(0xFFE5A34E);
  static const immersivePanel = Color(0xFF1D2620);
```

- [ ] **Step 2: Extender `CuyCashTextField`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cuycash_colors.dart';
import 'cuycash_spacing.dart';
import 'cuycash_typography.dart';

/// Input con label persistente arriba (DESIGN.md). Errores en carmín.
/// Soporta ícono leading, límite de caracteres y helper text.
class CuyCashTextField extends StatelessWidget {
  const CuyCashTextField({
    required this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
    this.maxLength,
    this.helperText,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final int? maxLength;
  final String? helperText;

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
          maxLength: maxLength,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            counterText: '',
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: CuyCashColors.outline, size: 20),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Test del prefixIcon/helper**

Añadir a `packages/design_system/test/components_test.dart`:

```dart
  testWidgets('CuyCashTextField muestra prefixIcon y helperText', (tester) async {
    await tester.pumpWidget(_wrap(
      const CuyCashTextField(
        label: 'Número de DNI',
        prefixIcon: Icons.badge_outlined,
        helperText: '8 dígitos',
      ),
    ));
    expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
    expect(find.text('8 dígitos'), findsOneWidget);
  });
```

- [ ] **Step 4: Correr tests**

Run: `cd packages/design_system && flutter test`
Expected: todos PASS (los previos + el nuevo).

- [ ] **Step 5: Commit**

```bash
git add packages/design_system
git commit -m "feat: CuyCashTextField con prefixIcon/maxLength/helper + tokens inmersivos"
```

---

## Task 4: `RegisterBloc` (draft, validación, navegación, simulaciones, submit)

**Files:**
- Create: `apps/mobile/lib/presentation/register/bloc/register_bloc.dart`
- Create: `apps/mobile/lib/presentation/register/bloc/register_event.dart`
- Create: `apps/mobile/lib/presentation/register/bloc/register_state.dart`
- Generated: `apps/mobile/lib/presentation/register/bloc/register_bloc.freezed.dart`
- Test: `apps/mobile/test/presentation/register/register_bloc_test.dart`

**Interfaces:**
- Consumes: `AuthActions` (Task 1), `AuthError`/`authErrorText` (reuso).
- Produces:
  - `enum CaptureStatus { empty, captured, unreadable }`, `enum FaceScanStatus { idle, scanning, success }`, `enum RegisterField { dni, nombres, apellidos, email }`, `enum DocSide { front, back }`, `enum FieldError { dniLength, requiredField, emailInvalid }`, `enum RegisterStatus { editing, submitting }`.
  - `RegisterDraft` (freezed) con `dni, nombres, apellidos, email, dniFront, dniBack, faceStatus, pin, biometricEnabled`.
  - `RegisterErrors` (freezed) con `dni, nombres, apellidos, email` (`FieldError?`), `showBanner` (bool), getter `count`.
  - `RegisterState` (freezed) `{int step, RegisterDraft draft, RegisterErrors errors, RegisterStatus status, AuthError? submitError}` + getter `canAdvance`.
  - `RegisterBloc(AuthActions actions)` con los eventos del spec.

- [ ] **Step 1: `register_event.dart`**

```dart
part of 'register_bloc.dart';

@freezed
sealed class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.fieldChanged(RegisterField field, String value) =
      RegisterFieldChanged;
  const factory RegisterEvent.captured(DocSide side) = RegisterCaptured;
  const factory RegisterEvent.captureFailed(DocSide side) = RegisterCaptureFailed;
  const factory RegisterEvent.faceScanStarted() = RegisterFaceScanStarted;
  const factory RegisterEvent.faceScanCompleted() = RegisterFaceScanCompleted;
  const factory RegisterEvent.pinChanged(String pin) = RegisterPinChanged;
  const factory RegisterEvent.biometricToggled(bool value) =
      RegisterBiometricToggled;
  const factory RegisterEvent.stepAdvanced() = RegisterStepAdvanced;
  const factory RegisterEvent.stepBack() = RegisterStepBack;
  const factory RegisterEvent.submitted() = RegisterSubmitted;
}
```

- [ ] **Step 2: `register_state.dart`**

```dart
part of 'register_bloc.dart';

enum CaptureStatus { empty, captured, unreadable }

enum FaceScanStatus { idle, scanning, success }

enum RegisterField { dni, nombres, apellidos, email }

enum DocSide { front, back }

enum FieldError { dniLength, requiredField, emailInvalid }

enum RegisterStatus { editing, submitting }

@freezed
abstract class RegisterDraft with _$RegisterDraft {
  const factory RegisterDraft({
    @Default('') String dni,
    @Default('') String nombres,
    @Default('') String apellidos,
    @Default('') String email,
    @Default(CaptureStatus.empty) CaptureStatus dniFront,
    @Default(CaptureStatus.empty) CaptureStatus dniBack,
    @Default(FaceScanStatus.idle) FaceScanStatus faceStatus,
    @Default('') String pin,
    @Default(true) bool biometricEnabled,
  }) = _RegisterDraft;
}

@freezed
abstract class RegisterErrors with _$RegisterErrors {
  const RegisterErrors._();
  const factory RegisterErrors({
    FieldError? dni,
    FieldError? nombres,
    FieldError? apellidos,
    FieldError? email,
    @Default(false) bool showBanner,
  }) = _RegisterErrors;

  int get count =>
      [dni, nombres, apellidos, email].where((e) => e != null).length;
}

@freezed
abstract class RegisterState with _$RegisterState {
  const RegisterState._();
  const factory RegisterState({
    @Default(0) int step,
    @Default(RegisterDraft()) RegisterDraft draft,
    @Default(RegisterErrors()) RegisterErrors errors,
    @Default(RegisterStatus.editing) RegisterStatus status,
    AuthError? submitError,
  }) = _RegisterState;

  /// ¿El paso actual permite avanzar / finalizar?
  bool get canAdvance => switch (step) {
        0 => RegisterValidators.dataValid(draft),
        1 => draft.dniFront == CaptureStatus.captured &&
            draft.dniBack == CaptureStatus.captured,
        2 => draft.faceStatus == FaceScanStatus.success,
        _ => RegisterValidators.pinValid(draft.pin),
      };
}
```

- [ ] **Step 3: `register_bloc.dart`**

```dart
import 'dart:async';

import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../feature/auth/domain/auth_failure.dart';
import '../../auth/bloc/auth_bloc.dart' show AuthError;

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

/// Validadores puros del wizard (testeables sin bloc).
abstract final class RegisterValidators {
  static final _dni = RegExp(r'^\d{8}$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _pin = RegExp(r'^\d{6}$');

  static bool dataValid(RegisterDraft draft) =>
      dniError(draft.dni) == null &&
      requiredError(draft.nombres) == null &&
      requiredError(draft.apellidos) == null &&
      emailError(draft.email) == null;

  static FieldError? dniError(String value) =>
      _dni.hasMatch(value.trim()) ? null : FieldError.dniLength;

  static FieldError? requiredError(String value) =>
      value.trim().isEmpty ? FieldError.requiredField : null;

  static FieldError? emailError(String value) =>
      _email.hasMatch(value.trim()) ? null : FieldError.emailInvalid;

  /// PIN válido: 6 dígitos, no todos iguales, no secuencia trivial ascendente
  /// o descendente (123456 / 654321).
  static bool pinValid(String pin) {
    if (!_pin.hasMatch(pin)) return false;
    if (pin.split('').toSet().length == 1) return false; // 000000
    const asc = '0123456789';
    const desc = '9876543210';
    if (asc.contains(pin) || desc.contains(pin)) return false;
    return true;
  }
}

/// Bloc del wizard de registro. Consume `AuthActions` por constructor. En el
/// submit final NO navega: la sesión llega por el stream de auth y el gate del
/// router lleva a /home.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc(AuthActions actions)
      : _actions = actions,
        super(const RegisterState()) {
    on<RegisterFieldChanged>(_onFieldChanged);
    on<RegisterCaptured>((event, emit) => emit(_setSide(event.side, CaptureStatus.captured)));
    on<RegisterCaptureFailed>((event, emit) => emit(_setSide(event.side, CaptureStatus.unreadable)));
    on<RegisterFaceScanStarted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.scanning))));
    on<RegisterFaceScanCompleted>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(faceStatus: FaceScanStatus.success))));
    on<RegisterPinChanged>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(pin: event.pin), submitError: null)));
    on<RegisterBiometricToggled>((event, emit) =>
        emit(state.copyWith(draft: state.draft.copyWith(biometricEnabled: event.value))));
    on<RegisterStepAdvanced>(_onStepAdvanced);
    on<RegisterStepBack>((event, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1));
    });
    on<RegisterSubmitted>(_onSubmitted);
  }

  final AuthActions _actions;

  RegisterState _setSide(DocSide side, CaptureStatus status) => state.copyWith(
        draft: side == DocSide.front
            ? state.draft.copyWith(dniFront: status)
            : state.draft.copyWith(dniBack: status),
      );

  void _onFieldChanged(RegisterFieldChanged event, Emitter<RegisterState> emit) {
    final draft = switch (event.field) {
      RegisterField.dni => state.draft.copyWith(dni: event.value),
      RegisterField.nombres => state.draft.copyWith(nombres: event.value),
      RegisterField.apellidos => state.draft.copyWith(apellidos: event.value),
      RegisterField.email => state.draft.copyWith(email: event.value),
    };
    // Recalcula errores solo si ya se mostró el banner (no molesta al tipear
    // la primera vez), o para limpiar un error del campo tocado.
    final errors = state.errors.showBanner
        ? _validateAll(draft)
        : state.errors.copyWith(
            dni: event.field == RegisterField.dni ? null : state.errors.dni,
            nombres: event.field == RegisterField.nombres ? null : state.errors.nombres,
            apellidos: event.field == RegisterField.apellidos ? null : state.errors.apellidos,
            email: event.field == RegisterField.email ? null : state.errors.email,
          );
    emit(state.copyWith(draft: draft, errors: errors));
  }

  RegisterErrors _validateAll(RegisterDraft draft) => RegisterErrors(
        dni: RegisterValidators.dniError(draft.dni),
        nombres: RegisterValidators.requiredError(draft.nombres),
        apellidos: RegisterValidators.requiredError(draft.apellidos),
        email: RegisterValidators.emailError(draft.email),
        showBanner: true,
      );

  void _onStepAdvanced(RegisterStepAdvanced event, Emitter<RegisterState> emit) {
    if (state.step == 0 && !RegisterValidators.dataValid(state.draft)) {
      emit(state.copyWith(errors: _validateAll(state.draft)));
      return;
    }
    if (!state.canAdvance) return;
    if (state.step < 3) emit(state.copyWith(step: state.step + 1));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!RegisterValidators.pinValid(state.draft.pin)) return;
    emit(state.copyWith(status: RegisterStatus.submitting, submitError: null));
    final result = await _actions.register(
      dni: state.draft.dni,
      nombres: state.draft.nombres,
      apellidos: state.draft.apellidos,
      email: state.draft.email,
      pin: state.draft.pin,
    );
    result.match(
      (failure) => emit(state.copyWith(
          status: RegisterStatus.editing, submitError: _errorFor(failure))),
      (_) {}, // éxito → sesión por el stream → AuthBloc → gate → /home
    );
  }

  AuthError _errorFor(GlobalFailure<AuthFailure> failure) => switch (failure) {
        ServerFailure(failure: IdentifierTaken()) => AuthError.identifierTaken,
        ServerFailure(failure: WeakPin()) => AuthError.weakPin,
        _ => AuthError.generic,
      };
}
```

- [ ] **Step 4: Generar freezed**

Run: `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
Expected: `register_bloc.freezed.dart` generado sin errores.

- [ ] **Step 5: Test del bloc**

`apps/mobile/test/presentation/register/register_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/presentation/auth/bloc/auth_bloc.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

RegisterBloc build([MemoryAuthRepository? repo]) =>
    RegisterBloc(AuthActions(repo ?? MemoryAuthRepository()));

void main() {
  group('validadores', () {
    test('DNI 8 dígitos', () {
      expect(RegisterValidators.dniError('12345678'), isNull);
      expect(RegisterValidators.dniError('1234'), FieldError.dniLength);
    });
    test('email', () {
      expect(RegisterValidators.emailError('a@b.pe'), isNull);
      expect(RegisterValidators.emailError('nope'), FieldError.emailInvalid);
    });
    test('pin 6 sin secuencia', () {
      expect(RegisterValidators.pinValid('024689'), isTrue);
      expect(RegisterValidators.pinValid('12345'), isFalse);
      expect(RegisterValidators.pinValid('123456'), isFalse);
      expect(RegisterValidators.pinValid('000000'), isFalse);
    });
  });

  blocTest<RegisterBloc, RegisterState>(
    'avanzar en paso 0 con datos inválidos marca errores y no avanza',
    build: build,
    act: (b) => b.add(const RegisterEvent.stepAdvanced()),
    verify: (b) {
      expect(b.state.step, 0);
      expect(b.state.errors.showBanner, isTrue);
      expect(b.state.errors.count, 4);
    },
  );

  blocTest<RegisterBloc, RegisterState>(
    'datos válidos → avanza a paso 1',
    build: build,
    act: (b) => b
      ..add(const RegisterEvent.fieldChanged(RegisterField.dni, '12345678'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.nombres, 'Juan'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.apellidos, 'Pérez'))
      ..add(const RegisterEvent.fieldChanged(RegisterField.email, 'j@p.pe'))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'captura front+back habilita avanzar a paso 2',
    build: build,
    seed: () => const RegisterState(step: 1),
    act: (b) => b
      ..add(const RegisterEvent.captured(DocSide.front))
      ..add(const RegisterEvent.captured(DocSide.back))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 2),
  );

  blocTest<RegisterBloc, RegisterState>(
    'captura no legible no permite avanzar',
    build: build,
    seed: () => const RegisterState(step: 1),
    act: (b) => b
      ..add(const RegisterEvent.captured(DocSide.front))
      ..add(const RegisterEvent.captureFailed(DocSide.back))
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'face scan completado avanza a paso 3',
    build: build,
    seed: () => const RegisterState(step: 2),
    act: (b) => b
      ..add(const RegisterEvent.faceScanCompleted())
      ..add(const RegisterEvent.stepAdvanced()),
    verify: (b) => expect(b.state.step, 3),
  );

  blocTest<RegisterBloc, RegisterState>(
    'stepBack retrocede',
    build: build,
    seed: () => const RegisterState(step: 2),
    act: (b) => b.add(const RegisterEvent.stepBack()),
    verify: (b) => expect(b.state.step, 1),
  );

  blocTest<RegisterBloc, RegisterState>(
    'submit con PIN válido registra (repo tiene sesión)',
    build: () {
      final repo = MemoryAuthRepository();
      return RegisterBloc(AuthActions(repo));
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321', nombres: 'Juan', apellidos: 'Pérez',
        email: 'j@p.pe', pin: '024689',
      ),
    ),
    act: (b) => b.add(const RegisterEvent.submitted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.status, RegisterStatus.editing),
  );

  blocTest<RegisterBloc, RegisterState>(
    'submit con DNI duplicado → submitError identifierTaken',
    build: () {
      final repo = MemoryAuthRepository();
      // pre-registra el DNI
      repo.register(
          dni: '87654321', nombres: 'A', apellidos: 'B', email: 'a@b.pe', pin: '024689');
      return RegisterBloc(AuthActions(repo));
    },
    seed: () => const RegisterState(
      step: 3,
      draft: RegisterDraft(
        dni: '87654321', nombres: 'Juan', apellidos: 'Pérez',
        email: 'j@p.pe', pin: '135790',
      ),
    ),
    act: (b) => b.add(const RegisterEvent.submitted()),
    wait: const Duration(milliseconds: 10),
    verify: (b) => expect(b.state.submitError, AuthError.identifierTaken),
  );
}
```

- [ ] **Step 6: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/register/register_bloc_test.dart`
Expected: todos PASS.

- [ ] **Step 7: Commit** (incluye `.freezed.dart`)

```bash
git add apps/mobile/lib/presentation/register/bloc apps/mobile/test/presentation/register/register_bloc_test.dart
git commit -m "feat: RegisterBloc (draft, validación, navegación, simulaciones, submit)"
```

---

## Task 5: Copy es-PE del wizard (ARB)

**Files:**
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Generated: `apps/mobile/lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces: getters l10n usados por las pantallas de los pasos (lista abajo).

- [ ] **Step 1: Añadir claves a `app_es.arb`**

Agregar (dentro del objeto JSON, respetando comas):

```json
  "registerFlowTitle": "Crear cuenta",
  "identityTitle": "Verifica tu identidad",
  "faceTitle": "Reconocimiento facial",
  "securityTitle": "Protege tu cuenta",
  "stepData": "Paso {n} de 4 · Datos",
  "@stepData": { "placeholders": { "n": { "type": "int" } } },
  "stepDocument": "Paso {n} de 4 · Documento",
  "@stepDocument": { "placeholders": { "n": { "type": "int" } } },
  "stepFace": "Paso {n} de 4 · Rostro",
  "@stepFace": { "placeholders": { "n": { "type": "int" } } },
  "stepSecurity": "Paso {n} de 4 · Seguridad",
  "@stepSecurity": { "placeholders": { "n": { "type": "int" } } },
  "dataHeadline": "Empecemos por ti",
  "dataSubtitle": "Ingresa tus datos tal como figuran en tu DNI.",
  "dniFieldLabel": "Número de DNI",
  "dniHint": "12345678",
  "dniHelper": "8 dígitos",
  "nombresLabel": "Nombres",
  "nombresHint": "Ej. Juan Carlos",
  "apellidosLabel": "Apellidos",
  "apellidosHint": "Ej. Pérez García",
  "emailLabel": "Correo electrónico",
  "emailHint": "ejemplo@correo.com",
  "emailHelper": "Aquí te enviaremos tus constancias y el código para recuperar tu PIN.",
  "errorFixFields": "Revisa {n} campos para continuar",
  "@errorFixFields": { "placeholders": { "n": { "type": "int" } } },
  "fieldRequired": "Este campo es obligatorio.",
  "errorDniLength": "El DNI debe tener 8 dígitos numéricos.",
  "errorEmailInvalid": "Ingresa un correo válido.",
  "identityInfo": "Validaremos tu identidad con una foto de tu DNI y reconocimiento facial.",
  "continueCta": "Continuar",
  "termsNote": "Al continuar aceptas los Términos y la Política de Privacidad",
  "documentHeadline": "Escanea tu DNI",
  "documentSubtitle": "Coloca el documento sobre una superficie plana, sin reflejos y con buena luz.",
  "capturesCount": "{n} de 2 capturas",
  "@capturesCount": { "placeholders": { "n": { "type": "int" } } },
  "dniFront": "Frente del DNI",
  "dniFrontHint": "Foto y datos personales",
  "dniBack": "Reverso del DNI",
  "dniBackHint": "Código y firma",
  "takePhoto": "Tomar foto",
  "retakePhoto": "Volver a tomar",
  "captured": "Capturado",
  "notReadable": "No legible",
  "documentError": "No pudimos leer tu DNI",
  "documentTip1": "Evita reflejos y sombras sobre el documento.",
  "documentTip2": "Apoya el DNI en una superficie plana, sin doblarlo.",
  "documentTip3": "Encuadra las cuatro esquinas dentro del marco.",
  "documentSecure": "Tus documentos se cifran y solo se usan para validar tu identidad.",
  "faceHeadline": "Centra tu rostro en el círculo",
  "faceInstruction": "Gira lentamente la cabeza hacia la derecha",
  "faceCheckLight": "Buena iluminación",
  "faceCheckUncovered": "Rostro descubierto",
  "faceCheckLiveness": "Prueba de vida",
  "faceInProgress": "(En proceso)",
  "faceCaption": "No cierres la app durante la verificación.",
  "faceSimulate": "Simular verificación",
  "pinHeadline": "Crea tu PIN de seguridad",
  "pinRule6": "6 dígitos",
  "pinRuleNoSequence": "Sin secuencias como 123456",
  "pinRuleNoBirthdate": "No uses tu fecha de nacimiento",
  "biometricTitle": "Activar acceso biométrico",
  "biometricSubtitle": "Entra con tu huella o rostro sin escribir el PIN.",
  "securityNote": "CuyCash usa un solo factor de verificación por operación.",
  "finishRegister": "Finalizar registro",
```

- [ ] **Step 2: Generar l10n**

Run: `cd apps/mobile && flutter gen-l10n`
Expected: sin errores; getters nuevos disponibles.

- [ ] **Step 3: Verificar**

Run: `cd apps/mobile && flutter analyze lib/l10n`
Expected: No issues found!

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/l10n
git commit -m "feat: copy es-PE del wizard de registro"
```

---

## Task 6: Progress bar + Paso 1 (Datos)

**Files:**
- Create: `apps/mobile/lib/presentation/register/widgets/register_progress_bar.dart`
- Create: `apps/mobile/lib/presentation/register/widgets/register_error_banner.dart`
- Create: `apps/mobile/lib/presentation/register/widgets/register_data_step.dart`
- Test: `apps/mobile/test/presentation/register/register_data_step_test.dart`

**Interfaces:**
- Consumes: `RegisterBloc`, `RegisterState`, `RegisterEvent`, `FieldError`, design_system, l10n.
- Produces: `RegisterProgressBar({required int step})`, `RegisterErrorBanner({required String message})`, `RegisterDataStep()`.

- [ ] **Step 1: `register_progress_bar.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Barra de progreso de 4 segmentos (paso actual = índice 0..3, inclusive).
class RegisterProgressBar extends StatelessWidget {
  const RegisterProgressBar({required this.step, this.dark = false, super.key});

  final int step;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final active = dark ? CuyCashColors.immersiveOcre : CuyCashColors.primaryContainer;
    final inactive = dark ? CuyCashColors.immersivePanel : CuyCashColors.surfaceVariant();
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            decoration: BoxDecoration(
              color: index <= step ? active : inactive,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
```

> Nota: `CuyCashColors.surfaceVariant()` no existe; usar `CuyCashColors.surfaceContainerHighest` como inactivo claro. Reemplazar la línea `inactive` por:
> `final inactive = dark ? CuyCashColors.immersivePanel : CuyCashColors.surfaceContainerHighest;`

- [ ] **Step 2: `register_error_banner.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Banner de error del formulario (carmín suave).
class RegisterErrorBanner extends StatelessWidget {
  const RegisterErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CuyCashColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: CuyCashColors.error),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
            child: Text(message,
                style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `register_data_step.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'register_error_banner.dart';

/// Paso 1 · Datos. Formulario con validación inline vía RegisterBloc.
class RegisterDataStep extends StatelessWidget {
  const RegisterDataStep({super.key});

  String? _errorText(AppLocalizations l10n, FieldError? error) => switch (error) {
        FieldError.dniLength => l10n.errorDniLength,
        FieldError.emailInvalid => l10n.errorEmailInvalid,
        FieldError.requiredField => l10n.fieldRequired,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final errors = state.errors;
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.dataHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.dataSubtitle,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(CuyCashRadii.card),
                border: Border.all(color: CuyCashColors.outlineVariant),
              ),
              child: Column(
                children: [
                  if (errors.showBanner && errors.count > 0) ...[
                    RegisterErrorBanner(
                        message: l10n.errorFixFields(errors.count)),
                    const SizedBox(height: CuyCashSpacing.stackLg),
                  ],
                  CuyCashTextField(
                    label: l10n.dniFieldLabel,
                    hint: l10n.dniHint,
                    helperText: errors.dni == null ? l10n.dniHelper : null,
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    errorText: _errorText(l10n, errors.dni),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.dni, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.nombresLabel,
                    hint: l10n.nombresHint,
                    errorText: _errorText(l10n, errors.nombres),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.nombres, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.apellidosLabel,
                    hint: l10n.apellidosHint,
                    errorText: _errorText(l10n, errors.apellidos),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.apellidos, v)),
                  ),
                  const SizedBox(height: CuyCashSpacing.stackLg),
                  CuyCashTextField(
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    helperText: errors.email == null ? l10n.emailHelper : null,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errorText(l10n, errors.email),
                    onChanged: (v) => bloc.add(
                        RegisterEvent.fieldChanged(RegisterField.email, v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _InfoStrip(text: l10n.identityInfo),
          ],
        );
      },
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CuyCashColors.primaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(CuyCashRadii.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: CuyCashColors.primaryContainer, size: 22),
          const SizedBox(width: CuyCashSpacing.stackSm),
          Expanded(
            child: Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.primaryContainer)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Test del paso 1**

`apps/mobile/test/presentation/register/register_data_step_test.dart`:

```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_data_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterBloc bloc;
  setUp(() => bloc = RegisterBloc(AuthActions(MemoryAuthRepository())));
  tearDown(() => bloc.close());

  Widget wrap() => BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RegisterDataStep()),
        ),
      );

  testWidgets('muestra el encabezado y los 4 campos', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Empecemos por ti'), findsOneWidget);
    expect(find.byType(CuyCashTextField), findsNWidgets(4));
  });

  testWidgets('avanzar con datos inválidos muestra el banner y errores',
      (tester) async {
    await tester.pumpWidget(wrap());
    bloc.add(const RegisterEvent.stepAdvanced());
    await tester.pumpAndSettle();
    expect(find.textContaining('Revisa'), findsOneWidget);
    expect(find.text('El DNI debe tener 8 dígitos numéricos.'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/register/register_data_step_test.dart`
Expected: 2 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/presentation/register/widgets/register_progress_bar.dart apps/mobile/lib/presentation/register/widgets/register_error_banner.dart apps/mobile/lib/presentation/register/widgets/register_data_step.dart apps/mobile/test/presentation/register/register_data_step_test.dart
git commit -m "feat: paso 1 (Datos) + progress bar + banner de error"
```

---

## Task 7: Paso 2 (Documento)

**Files:**
- Create: `apps/mobile/lib/presentation/register/widgets/document_capture_card.dart`
- Create: `apps/mobile/lib/presentation/register/widgets/register_document_step.dart`
- Test: `apps/mobile/test/presentation/register/register_document_step_test.dart`

**Interfaces:**
- Consumes: `RegisterBloc`, `CaptureStatus`, `DocSide`, design_system, l10n.
- Produces: `DocumentCaptureCard({required String title, required String hint, required CaptureStatus status, required VoidCallback onCapture, required VoidCallback onRetake})`, `RegisterDocumentStep()`.

- [ ] **Step 1: `document_capture_card.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';

/// Card de captura de un lado del DNI. Simulado: onCapture marca capturado.
class DocumentCaptureCard extends StatelessWidget {
  const DocumentCaptureCard({
    required this.title,
    required this.hint,
    required this.status,
    required this.onCapture,
    required this.onRetake,
    super.key,
  });

  final String title;
  final String hint;
  final CaptureStatus status;
  final VoidCallback onCapture;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unreadable = status == CaptureStatus.unreadable;
    final captured = status == CaptureStatus.captured;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CuyCashColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
        boxShadow: const [
          BoxShadow(color: CuyCashColors.ambientShadow, blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: CuyCashTypography.titleMd.copyWith(fontSize: 16)),
          Text(hint,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.secondaryText)),
          const SizedBox(height: CuyCashSpacing.stackMd),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: CuyCashColors.surfaceContainer,
                borderRadius: BorderRadius.circular(CuyCashRadii.sm),
                border: Border.all(
                  color: unreadable
                      ? CuyCashColors.error
                      : captured
                          ? CuyCashColors.primaryContainer
                          : CuyCashColors.outlineVariant,
                  width: unreadable || captured ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: captured
                    ? _Pill(
                        label: l10n.captured,
                        color: CuyCashColors.primaryContainer,
                        icon: Icons.check_circle)
                    : unreadable
                        ? _Pill(
                            label: l10n.notReadable,
                            color: CuyCashColors.error,
                            icon: Icons.error)
                        : const Icon(Icons.photo_camera_outlined,
                            size: 28, color: CuyCashColors.secondaryText),
              ),
            ),
          ),
          if (unreadable) ...[
            const SizedBox(height: CuyCashSpacing.stackMd),
            Text(l10n.documentError,
                style: CuyCashTypography.bodyMd.copyWith(
                    color: CuyCashColors.error, fontWeight: FontWeight.w600)),
            const SizedBox(height: CuyCashSpacing.stackSm),
            _tip(l10n.documentTip1),
            _tip(l10n.documentTip2),
            _tip(l10n.documentTip3),
          ],
          const SizedBox(height: CuyCashSpacing.stackMd),
          SecondaryButton(
            label: (captured || unreadable) ? l10n.retakePhoto : l10n.takePhoto,
            onPressed: (captured || unreadable) ? onRetake : onCapture,
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: SizedBox(
                  width: 6, height: 6,
                  child: DecoratedBox(decoration: BoxDecoration(
                      color: CuyCashColors.secondaryText, shape: BoxShape.circle))),
            ),
            Expanded(
              child: Text(text,
                  style: CuyCashTypography.bodyMd
                      .copyWith(color: CuyCashColors.secondaryText)),
            ),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CuyCashColors.onPrimary),
          const SizedBox(width: 6),
          Text(label,
              style: CuyCashTypography.labelSm
                  .copyWith(color: CuyCashColors.onPrimary)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `register_document_step.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'document_capture_card.dart';

/// Paso 2 · Documento. Captura simulada de frente y reverso del DNI.
class RegisterDocumentStep extends StatelessWidget {
  const RegisterDocumentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final draft = state.draft;
        final count = [draft.dniFront, draft.dniBack]
            .where((s) => s == CaptureStatus.captured)
            .length;
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.documentHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.documentSubtitle,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackXs),
            Text(l10n.capturesCount(count),
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
            const SizedBox(height: CuyCashSpacing.stackLg),
            DocumentCaptureCard(
              title: l10n.dniFront,
              hint: l10n.dniFrontHint,
              status: draft.dniFront,
              onCapture: () => bloc.add(const RegisterEvent.captured(DocSide.front)),
              onRetake: () => bloc.add(const RegisterEvent.captured(DocSide.front)),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            DocumentCaptureCard(
              title: l10n.dniBack,
              hint: l10n.dniBackHint,
              status: draft.dniBack,
              onCapture: () => bloc.add(const RegisterEvent.captured(DocSide.back)),
              onRetake: () => bloc.add(const RegisterEvent.captured(DocSide.back)),
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: 16, color: CuyCashColors.secondaryText),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Flexible(
                  child: Text(l10n.documentSecure,
                      style: CuyCashTypography.labelSm),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 3: Test del paso 2**

`apps/mobile/test/presentation/register/register_document_step_test.dart`:

```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_document_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterBloc bloc;
  setUp(() => bloc = RegisterBloc(AuthActions(MemoryAuthRepository())));
  tearDown(() => bloc.close());

  Widget wrap() => BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RegisterDocumentStep()),
        ),
      );

  testWidgets('tomar foto marca capturado', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('0 de 2 capturas'), findsOneWidget);
    await tester.tap(find.byType(SecondaryButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Capturado'), findsOneWidget);
    expect(find.text('1 de 2 capturas'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/register/register_document_step_test.dart`
Expected: 1 test PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/presentation/register/widgets/document_capture_card.dart apps/mobile/lib/presentation/register/widgets/register_document_step.dart apps/mobile/test/presentation/register/register_document_step_test.dart
git commit -m "feat: paso 2 (Documento) con captura simulada"
```

---

## Task 8: Paso 3 (Rostro, inmersivo)

**Files:**
- Create: `apps/mobile/lib/presentation/register/widgets/face_scan_ring.dart`
- Create: `apps/mobile/lib/presentation/register/widgets/register_face_step.dart`

**Interfaces:**
- Consumes: `RegisterBloc`, `FaceScanStatus`, `CuyCashColors` (tokens inmersivos), l10n.
- Produces: `FaceScanRing({required bool active})`, `RegisterFaceStep()`.

- [ ] **Step 1: `face_scan_ring.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Anillo circular del viewport de escaneo facial (placeholder visual, sin
/// cámara real). El color ocre indica escaneo activo.
class FaceScanRing extends StatelessWidget {
  const FaceScanRing({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? CuyCashColors.immersiveOcre
                    : CuyCashColors.immersiveMuted,
                width: 3,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CuyCashColors.immersivePanel,
            ),
            child: const Icon(Icons.person_outline,
                size: 120, color: CuyCashColors.immersiveMuted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `register_face_step.dart`**

```dart
import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'face_scan_ring.dart';

/// Paso 3 · Rostro. Pantalla inmersiva oscura. En mock: al montar inicia el
/// escaneo y tras un delay lo completa (simulación de prueba de vida).
class RegisterFaceStep extends StatefulWidget {
  const RegisterFaceStep({super.key});

  @override
  State<RegisterFaceStep> createState() => _RegisterFaceStepState();
}

class _RegisterFaceStepState extends State<RegisterFaceStep> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<RegisterBloc>();
    if (bloc.state.draft.faceStatus == FaceScanStatus.idle) {
      bloc.add(const RegisterEvent.faceScanStarted());
      _timer = Timer(const Duration(seconds: 3),
          () => bloc.add(const RegisterEvent.faceScanCompleted()));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final done = state.draft.faceStatus == FaceScanStatus.success;
        return Column(
          children: [
            const SizedBox(height: CuyCashSpacing.stackXl),
            Text(l10n.faceHeadline,
                textAlign: TextAlign.center,
                style: CuyCashTypography.titleMd
                    .copyWith(color: CuyCashColors.immersiveOnDark)),
            const SizedBox(height: CuyCashSpacing.stackXl),
            FaceScanRing(active: !done),
            const SizedBox(height: CuyCashSpacing.stackLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rotate_right,
                    size: 18, color: CuyCashColors.immersiveOcre),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Flexible(
                  child: Text(l10n.faceInstruction,
                      style: CuyCashTypography.bodyLg
                          .copyWith(color: CuyCashColors.immersiveOcre)),
                ),
              ],
            ),
            const SizedBox(height: CuyCashSpacing.stackXl),
            _Checklist(livenessDone: done),
            const Spacer(),
            Text(l10n.faceCaption,
                textAlign: TextAlign.center,
                style: CuyCashTypography.labelSm
                    .copyWith(color: CuyCashColors.immersiveMuted)),
            const SizedBox(height: CuyCashSpacing.stackLg),
          ],
        );
      },
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.livenessDone});
  final bool livenessDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      decoration: BoxDecoration(
        color: CuyCashColors.immersivePanel,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
      ),
      child: Column(
        children: [
          _row(l10n.faceCheckLight, true, null),
          const SizedBox(height: CuyCashSpacing.stackMd),
          _row(l10n.faceCheckUncovered, true, null),
          const SizedBox(height: CuyCashSpacing.stackMd),
          _row(l10n.faceCheckLiveness, livenessDone,
              livenessDone ? null : l10n.faceInProgress),
        ],
      ),
    );
  }

  Widget _row(String label, bool done, String? suffix) => Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.hourglass_empty,
              size: 20,
              color: done
                  ? CuyCashColors.immersiveOcre
                  : CuyCashColors.immersiveMuted),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Text(label,
              style: CuyCashTypography.bodyMd
                  .copyWith(color: CuyCashColors.immersiveOnDark)),
          if (suffix != null) ...[
            const SizedBox(width: 6),
            Text(suffix,
                style: CuyCashTypography.labelSm
                    .copyWith(color: CuyCashColors.immersiveMuted)),
          ],
        ],
      );
}
```

- [ ] **Step 3: Verificar análisis**

Run: `cd apps/mobile && flutter analyze lib/presentation/register/widgets/register_face_step.dart lib/presentation/register/widgets/face_scan_ring.dart`
Expected: No issues found!

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/presentation/register/widgets/face_scan_ring.dart apps/mobile/lib/presentation/register/widgets/register_face_step.dart
git commit -m "feat: paso 3 (Rostro) inmersivo con verificación simulada"
```

---

## Task 9: Paso 4 (Seguridad · PIN)

**Files:**
- Create: `apps/mobile/lib/presentation/register/widgets/pin_boxes.dart`
- Create: `apps/mobile/lib/presentation/register/widgets/register_pin_step.dart`
- Test: `apps/mobile/test/presentation/register/register_pin_step_test.dart`

**Interfaces:**
- Consumes: `RegisterBloc`, `RegisterValidators`, design_system, l10n.
- Produces: `PinBoxes({required String pin, required int length})`, `RegisterPinStep()`.

- [ ] **Step 1: `pin_boxes.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Casillas visuales del PIN (una por dígito). Refleja cuántos dígitos hay.
class PinBoxes extends StatelessWidget {
  const PinBoxes({required this.pin, this.length = 6, super.key});

  final String pin;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final filled = index < pin.length;
        final active = index == pin.length;
        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: CuyCashColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(CuyCashRadii.input),
            border: Border.all(
              color: active
                  ? CuyCashColors.primaryContainer
                  : CuyCashColors.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Center(
            child: filled
                ? Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                        color: CuyCashColors.primaryContainer,
                        shape: BoxShape.circle))
                : const SizedBox.shrink(),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: `register_pin_step.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import 'pin_boxes.dart';

/// Paso 4 · Seguridad. PIN de 6 dígitos + reglas + toggle biométrico.
class RegisterPinStep extends StatefulWidget {
  const RegisterPinStep({super.key});

  @override
  State<RegisterPinStep> createState() => _RegisterPinStepState();
}

class _RegisterPinStepState extends State<RegisterPinStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final pin = state.draft.pin;
        final len6 = pin.length == 6;
        final noSeq = RegisterValidators.pinValid(pin);
        return ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: CuyCashSpacing.marginMobile),
          children: [
            Text(l10n.pinHeadline, style: CuyCashTypography.headlineSm),
            const SizedBox(height: CuyCashSpacing.stackLg),
            // Campo oculto que captura el teclado numérico; las casillas son visuales.
            Stack(
              children: [
                PinBoxes(pin: pin),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) =>
                          bloc.add(RegisterEvent.pinChanged(v)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _rule(l10n.pinRule6, len6),
            _rule(l10n.pinRuleNoSequence, noSeq),
            _ruleAdvisory(l10n.pinRuleNoBirthdate),
            const SizedBox(height: CuyCashSpacing.stackLg),
            _BiometricCard(
              enabled: state.draft.biometricEnabled,
              onChanged: (v) => bloc.add(RegisterEvent.biometricToggled(v)),
            ),
            const SizedBox(height: CuyCashSpacing.stackMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: CuyCashColors.secondaryText),
                const SizedBox(width: CuyCashSpacing.stackSm),
                Expanded(
                  child: Text(l10n.securityNote,
                      style: CuyCashTypography.labelSm),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _rule(String text, bool done) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: done
                    ? CuyCashColors.primaryContainer
                    : CuyCashColors.outlineVariant),
            const SizedBox(width: CuyCashSpacing.stackMd),
            Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.onSurface)),
          ],
        ),
      );

  Widget _ruleAdvisory(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.circle,
                size: 8, color: CuyCashColors.outlineVariant),
            const SizedBox(width: CuyCashSpacing.stackMd),
            Text(text,
                style: CuyCashTypography.bodyMd
                    .copyWith(color: CuyCashColors.secondaryText)),
          ],
        ),
      );
}

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
      decoration: BoxDecoration(
        color: CuyCashColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CuyCashRadii.card),
        boxShadow: const [
          BoxShadow(color: CuyCashColors.ambientShadow, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, color: CuyCashColors.primaryContainer),
          const SizedBox(width: CuyCashSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.biometricTitle,
                    style: CuyCashTypography.titleMd.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(l10n.biometricSubtitle,
                    style: CuyCashTypography.bodyMd
                        .copyWith(color: CuyCashColors.secondaryText)),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: CuyCashColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Test del paso 4**

`apps/mobile/test/presentation/register/register_pin_step_test.dart`:

```dart
import 'package:cuycash/feature/auth/application/auth_actions.dart';
import 'package:cuycash/feature/auth/infrastructure/memory_auth_repository.dart';
import 'package:cuycash/l10n/app_localizations.dart';
import 'package:cuycash/presentation/register/bloc/register_bloc.dart';
import 'package:cuycash/presentation/register/widgets/register_pin_step.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RegisterBloc bloc;
  setUp(() => bloc = RegisterBloc(AuthActions(MemoryAuthRepository())));
  tearDown(() => bloc.close());

  Widget wrap() => BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          theme: CuyCashTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RegisterPinStep()),
        ),
      );

  testWidgets('tipear un PIN válido marca las reglas y actualiza el draft',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '024689');
    await tester.pumpAndSettle();
    expect(bloc.state.draft.pin, '024689');
    // dos íconos check_circle (6 dígitos + sin secuencia)
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });
}
```

- [ ] **Step 4: Correr el test**

Run: `cd apps/mobile && flutter test test/presentation/register/register_pin_step_test.dart`
Expected: 1 test PASS.

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/presentation/register/widgets/pin_boxes.dart apps/mobile/lib/presentation/register/widgets/register_pin_step.dart apps/mobile/test/presentation/register/register_pin_step_test.dart
git commit -m "feat: paso 4 (Seguridad) con PIN de 6 dígitos y biométrico"
```

---

## Task 10: `RegisterFlowScreen` + wiring de ruta + integración

**Files:**
- Create: `apps/mobile/lib/presentation/register/register_flow_screen.dart`
- Create: `apps/mobile/lib/core/injection/modules/register_module.dart`
- Modify: `apps/mobile/lib/presentation/app/router.dart`
- Delete: `apps/mobile/lib/presentation/auth/register_screen.dart`
- Test: (integración) toda la suite + analyze + build

**Interfaces:**
- Consumes: `RegisterBloc`, los 4 widgets de paso, `RegisterProgressBar`, `AppDependencies`, `AuthActions`, `PrimaryButton`, l10n.
- Produces: `RegisterFlowScreen()`, `RegisterModule.blocProvider(AppDependencies)`.

- [ ] **Step 1: `register_module.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feature/auth/application/auth_actions.dart';
import '../../../presentation/register/bloc/register_bloc.dart';
import '../app_dependencies.dart';

/// Wiring del wizard de registro: arma `AuthActions` desde el repo y crea el
/// `RegisterBloc`. Se provee solo en la ruta /registro (no global).
abstract final class RegisterModule {
  static BlocProvider<RegisterBloc> blocProvider(AppDependencies deps) =>
      BlocProvider<RegisterBloc>(
        create: (_) => RegisterBloc(AuthActions(deps.authRepository)),
      );
}
```

- [ ] **Step 2: `register_flow_screen.dart`**

```dart
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'bloc/register_bloc.dart';
import 'widgets/register_data_step.dart';
import 'widgets/register_document_step.dart';
import 'widgets/register_face_step.dart';
import 'widgets/register_pin_step.dart';
import 'widgets/register_progress_bar.dart';

/// Wizard de registro. Chrome compartido + IndexedStack de 4 pasos. El paso 3
/// (Rostro) usa fondo oscuro inmersivo. En éxito no navega: el gate del router
/// lleva a /home cuando AuthBloc emite autenticado (sesión por el stream).
class RegisterFlowScreen extends StatelessWidget {
  const RegisterFlowScreen({super.key});

  static const _titles = [0, 1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final bloc = context.read<RegisterBloc>();
        final dark = state.step == 2;
        final title = switch (state.step) {
          0 => l10n.registerFlowTitle,
          1 => l10n.identityTitle,
          2 => l10n.faceTitle,
          _ => l10n.securityTitle,
        };
        final stepLabel = switch (state.step) {
          0 => l10n.stepData(1),
          1 => l10n.stepDocument(2),
          2 => l10n.stepFace(3),
          _ => l10n.stepSecurity(4),
        };
        final onSurface =
            dark ? CuyCashColors.immersiveOnDark : CuyCashColors.onSurface;

        return Scaffold(
          backgroundColor:
              dark ? CuyCashColors.immersiveDark : CuyCashColors.surfaceContainerLow,
          appBar: AppBar(
            backgroundColor: dark
                ? CuyCashColors.immersiveDark
                : CuyCashColors.surfaceContainerLow,
            foregroundColor: onSurface,
            title: Text(title, style: CuyCashTypography.titleMd.copyWith(color: onSurface, fontSize: 18)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (state.step == 0) {
                  context.pop();
                } else {
                  bloc.add(const RegisterEvent.stepBack());
                }
              },
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      CuyCashSpacing.marginMobile, 0,
                      CuyCashSpacing.marginMobile, CuyCashSpacing.stackLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegisterProgressBar(step: state.step, dark: dark),
                      const SizedBox(height: CuyCashSpacing.stackSm),
                      Text(stepLabel,
                          style: CuyCashTypography.labelSm.copyWith(
                              color: dark
                                  ? CuyCashColors.immersiveMuted
                                  : CuyCashColors.secondaryText)),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: state.step,
                    children: const [
                      RegisterDataStep(),
                      RegisterDocumentStep(),
                      RegisterFaceStep(),
                      RegisterPinStep(),
                    ],
                  ),
                ),
                _Footer(state: state, dark: dark),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.dark});
  final RegisterState state;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegisterBloc>();
    final isLast = state.step == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(CuyCashSpacing.marginMobile,
          CuyCashSpacing.stackMd, CuyCashSpacing.marginMobile, CuyCashSpacing.stackLg),
      child: PrimaryButton(
        label: isLast ? l10n.finishRegister : l10n.continueCta,
        loading: state.status == RegisterStatus.submitting,
        onPressed: state.canAdvance
            ? () => bloc.add(
                isLast ? const RegisterEvent.submitted() : const RegisterEvent.stepAdvanced())
            : (state.step == 0
                ? () => bloc.add(const RegisterEvent.stepAdvanced()) // dispara validación/banner
                : null),
      ),
    );
  }
}
```

- [ ] **Step 3: Wire de la ruta en `router.dart`**

Reemplazar el import y la ruta del registro. Cambiar:

```dart
import '../auth/register_screen.dart';
```
por:
```dart
import '../../core/injection/modules/register_module.dart';
import '../register/register_flow_screen.dart';
```

Y la `GoRoute` de `/registro`:

```dart
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => BlocProvider<RegisterBloc>.value(
          value: RegisterModule.blocProvider(deps).create!(context),
          child: const RegisterFlowScreen(),
        ),
      ),
```

> Nota: `BlocProvider.value` con `.create!` es incorrecto. Usar directamente el provider del módulo envolviendo la pantalla:
> ```dart
>       GoRoute(
>         path: AppRoutes.registro,
>         builder: (context, state) => FlutterBlocProviderWrapper(deps: deps),
>       ),
> ```
> En vez de un wrapper extra, la forma correcta y simple: dado que `RegisterModule.blocProvider(deps)` YA es un `BlocProvider` que crea el bloc, envolver así:
> ```dart
>       GoRoute(
>         path: AppRoutes.registro,
>         builder: (context, state) {
>           final provider = RegisterModule.blocProvider(deps);
>           return BlocProvider<RegisterBloc>(
>             create: provider.create!,
>             child: const RegisterFlowScreen(),
>           );
>         },
>       ),
> ```
> **Implementación definitiva a usar (evita depender de `.create`):** cambiar `RegisterModule` para exponer una fábrica del bloc en vez de un `BlocProvider`, y en el router construir el `BlocProvider` con esa fábrica:

Actualizar `register_module.dart` a:

```dart
import '../../../feature/auth/application/auth_actions.dart';
import '../../../presentation/register/bloc/register_bloc.dart';
import '../app_dependencies.dart';

abstract final class RegisterModule {
  static RegisterBloc create(AppDependencies deps) =>
      RegisterBloc(AuthActions(deps.authRepository));
}
```

Y en `router.dart`:

```dart
      GoRoute(
        path: AppRoutes.registro,
        builder: (context, state) => BlocProvider<RegisterBloc>(
          create: (_) => RegisterModule.create(deps),
          child: const RegisterFlowScreen(),
        ),
      ),
```

Añadir el import de `flutter_bloc` en `router.dart` si falta:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
```

- [ ] **Step 4: Borrar el stub**

```bash
git rm apps/mobile/lib/presentation/auth/register_screen.dart
```

Verificar que nada más lo importe: `grep -rn "register_screen" apps/mobile/lib` → sin resultados (el router ya no).

- [ ] **Step 5: Analyze whole-project**

Run: `cd apps/mobile && flutter analyze`
Expected: No issues found!

- [ ] **Step 6: Suite completa (3 paquetes)**

Run:
```bash
cd /Users/jairconislla/Projects/cuycash/packages/core_kernel && dart test
cd /Users/jairconislla/Projects/cuycash/packages/design_system && flutter test
cd /Users/jairconislla/Projects/cuycash/apps/mobile && flutter test
```
Expected: todo verde.

- [ ] **Step 7: Build de humo (flavor mock)**

Run:
```bash
cd /Users/jairconislla/Projects/cuycash/apps/mobile
flutter build apk --flavor mock -t lib/main_mock.dart --dart-define-from-file=config.mock.json --debug
```
Expected: `✓ Built ... app-mock-debug.apk`.

- [ ] **Step 8: Commit**

```bash
git add apps/mobile/lib/presentation/register/register_flow_screen.dart apps/mobile/lib/core/injection/modules/register_module.dart apps/mobile/lib/presentation/app/router.dart
git commit -m "feat: RegisterFlowScreen + ruta /registro (wizard 4 pasos); elimina stub"
```

---

## Self-Review

**1. Spec coverage:**
- Wizard 4 pasos + chrome compartido + IndexedStack → Tasks 6-10. ✓
- RegisterBloc (draft/validación/nav/simulaciones/submit) → Task 4. ✓
- PIN 6 dígitos global → Tasks 1, 2. ✓
- register firma perfil completo → Task 1; AuthBloc pierde register → Task 2. ✓
- Paso 1 validación inline + banner → Task 6. ✓
- Paso 2 captura simulada + no legible → Task 7. ✓
- Paso 3 inmersivo oscuro (tokens) → Tasks 3, 8. ✓
- Paso 4 PIN + reglas + biométrico → Task 9. ✓
- prefixIcon en input → Task 3. ✓
- Copy es-PE → Task 5. ✓
- Tests (bloc, contrato, widgets, regresión) → Tasks 1,2,4,6,7,9,10. ✓
- SupabaseAuthRepository firma nueva (skeleton) → Task 1. ✓

**2. Placeholder scan:** El Task 10 Step 3 contiene una deliberación sobre el wiring del BlocProvider que termina en una **implementación definitiva** (RegisterModule.create + BlocProvider en el router) — el implementer debe usar esa versión final; las variantes tachadas son contexto de por qué. No hay TODO/TBD reales. `FlutterBlocProviderWrapper` mencionado NO debe crearse (era una alternativa descartada); la versión definitiva no lo usa.

**3. Type consistency:** `register({dni,nombres,apellidos,email,pin})` idéntico en domain/infra/application/actions/bloc/tests. `RegisterState{step,draft,errors,status,submitError}` + `canAdvance` consistente entre bloc y widgets. `CaptureStatus/FaceScanStatus/RegisterField/DocSide/FieldError/RegisterStatus` usados igual en bloc, state y widgets. `RegisterModule.create(deps)` (versión final) usado por el router. Tokens `CuyCashColors.immersive*` definidos en Task 3 y usados en Tasks 6(progress dark),8. `CuyCashTextField` con `prefixIcon/maxLength/helperText` definido en Task 3, usado en Task 6.

**Nota de orden:** Task 3 (design_system: prefixIcon + tokens) debe ir antes de 6-10; Task 4 (bloc) antes de 6-10; Task 5 (l10n) antes de 6-10. Orden recomendado: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10.
