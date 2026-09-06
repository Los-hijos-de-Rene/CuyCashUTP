# CuyCash — Wizard de registro (4 pasos): diseño

- **Fecha:** 2026-09-06
- **Base:** Sprint 1 (ver `2026-09-05-cuycash-mobile-base-design.md`). Reemplaza el stub `register_screen.dart`.
- **State management:** Bloc + tests unitarios (patrón de `mediccuy/apps/app`).
- **Flavor foco:** `mock` (captura de documento y reconocimiento facial simulados; sin cámara/OCR/ML reales).

## Objetivo

Reemplazar el stub de registro por un **wizard de 4 pasos** con chrome compartido (app bar + barra de progreso de 4 segmentos + "Paso N de 4 · …"):

```
Paso 1 · Datos      → DNI, Nombres, Apellidos, Correo (validación inline)
Paso 2 · Documento  → captura frente + reverso del DNI (simulada)
Paso 3 · Rostro     → reconocimiento facial (pantalla inmersiva oscura, simulada)
Paso 4 · Seguridad  → crear PIN de 6 dígitos + toggle biométrico → Finalizar registro
```

Al finalizar (paso 4) se registra la cuenta vía la capa de aplicación de auth; la sesión resultante llega por el stream de `AuthRepository.sessionChanges()` → el `AuthBloc` global emite `AuthAuthenticated` → el gate del router redirige a `/home`.

## Cambio global: PIN de 6 dígitos

Hoy el mock usa PIN de 4 (`MemoryAuthRepository.validPin = '0000'`, regex `^\d{4}$`, login hint `****`). Se sube a **6 dígitos** en toda la app:
- `MemoryAuthRepository.validPin = '000000'`, regex `^\d{6}$`.
- Login: hint/campo de PIN a 6 dígitos.
- Copy es-PE actualizado (`errorWeakPin` = "El PIN debe tener 6 dígitos").

## Reglas duras (heredadas)

Errores como valores (`Either`+`GlobalFailure`); failures sellados; `Memory*` funcional = contrato de tests; estados sealed + `switch` exhaustivo (sin `when`/`maybeWhen`/`!`); DI por constructor; el Bloc consume la capa `application` (`AuthActions`), nunca el repo; tokens del design system (cero hex sueltos salvo el tema oscuro local del paso 3, documentado); copy es-PE en ARB; un widget público por archivo; `.freezed.dart` se commitea.

---

## Arquitectura

### `RegisterBloc` (presentation/register/bloc)
Un solo bloc maneja todo el wizard. Consume `AuthActions` por constructor (para el submit final). Freezed sealed para evento y estado.

`RegisterDraft` (dato inmutable con `copyWith`, en application o como parte del state):
- Paso 1: `dni`, `nombres`, `apellidos`, `email` (String, default '').
- Paso 2: `dniFront`, `dniBack` — `enum CaptureStatus { empty, captured, unreadable }`.
- Paso 3: `faceStatus` — `enum FaceScanStatus { idle, scanning, success }`.
- Paso 4: `pin` (String, default ''), `biometricEnabled` (bool, default true).

`RegisterState` (freezed sealed):
- `RegisterInProgress({ int step (0..3), RegisterDraft draft, RegisterErrors errors, RegisterStatus status })`
  - `enum RegisterStatus { editing, submitting, failure }` + `RegisterError? submitError`.
  - `RegisterErrors`: mapa/registro de errores por campo del paso 1 (`dni`, `nombres`, `apellidos`, `email` → `FieldError?`) para pintar estados de error y el banner "Revisa N campos".
- `RegisterDone(AuthSession session)` — opcional; en la práctica el éxito se refleja vía el stream de auth y el gate. El bloc puede quedarse en `RegisterInProgress` y dejar que `AuthBloc` haga la transición. **Decisión:** el bloc NO navega en éxito; el gate del router (ya existente) lleva a `/home` cuando `AuthBloc` emite autenticado.

`RegisterEvent` (freezed sealed):
- `RegisterFieldChanged(RegisterField field, String value)` — paso 1.
- `RegisterCapture(DocSide side)` / `RegisterCaptureFailed(DocSide side)` — paso 2 (simulación: capturado / no legible). `enum DocSide { front, back }`.
- `RegisterFaceScanStarted` / `RegisterFaceScanCompleted` — paso 3 (simulación).
- `RegisterPinChanged(String pin)` / `RegisterBiometricToggled(bool value)` — paso 4.
- `RegisterStepAdvanced` / `RegisterStepBack` — navegación (con validación de gating por paso).
- `RegisterSubmitted` — paso 4 → llama `AuthActions.register(...)`.

**Validación por paso (gating de "Continuar"):**
- Paso 1: DNI = exactamente 8 dígitos numéricos; Nombres no vacío; Apellidos no vacío; Correo con formato válido (regex simple). `RegisterFieldChanged` recalcula errores; `RegisterStepAdvanced` solo avanza si el paso es válido (si no, marca todos los errores y setea el banner).
- Paso 2: avanza cuando `dniFront == captured && dniBack == captured`.
- Paso 3: avanza cuando `faceStatus == success`.
- Paso 4: `Finalizar` habilitado cuando el PIN cumple reglas (6 dígitos, sin secuencia trivial tipo 123456/000000). La regla "no uses tu fecha de nacimiento" es **advisory** (no se valida: no pedimos fecha de nacimiento) — bullet gris informativo.

### Navegación / pantalla
- `RegisterFlowScreen` (`presentation/register/`): `BlocProvider<RegisterBloc>` + `BlocBuilder`. Chrome compartido salvo el paso 3 (inmersivo). Contenido por `IndexedStack(index: step)` con los 4 widgets de paso. Botón atrás: `RegisterStepBack` (o `context.pop()`/ir a login en el paso 1). Ruta `/registro` monta `RegisterFlowScreen` (reemplaza el stub).
- El paso 3 (`RegisterFaceStep`) usa **tema oscuro local** (fondo `#121712`, textos claros, acentos ocre `#D98C2B`) — colores locales a esa pantalla, documentados; no altera `CuyCashTheme`. (Se añaden tokens oscuros a `CuyCashColors` para no hardcodear: `immersiveDark`, `immersiveOnDark`, etc.)
- Widgets de paso en `presentation/register/widgets/` (un widget público por archivo): `register_data_step.dart`, `register_document_step.dart`, `register_face_step.dart`, `register_pin_step.dart`, más piezas propias (`register_progress_bar.dart`, `document_capture_card.dart`, `pin_boxes.dart`, `face_scan_ring.dart`, `register_error_banner.dart`).

### Capa de datos (submit)
`AuthRepository.register` se **expande** para el perfil completo:

```dart
FutureResult<AuthFailure, AuthSession> register({
  required String dni,
  required String nombres,
  required String apellidos,
  required String email,
  required String pin,
});
```

(Se elimina `alias` del registro — el alias no forma parte de este flujo.) Actualiza:
- `MemoryAuthRepository.register`: valida PIN 6 dígitos (`WeakPin`), DNI único (`IdentifierTaken`), crea sesión (`identifier: dni`), emite.
- `SupabaseAuthRepository.register`: esqueleto (mantiene `AuthUnavailable`).
- `AuthActions.register`: delega con la nueva firma.
- **`AuthBloc`**: se le quita el registro (evento `registerSubmitted`, `_onRegisterSubmitted`, `AuthError.identifierTaken/weakPin` si solo las usaba register — se mantienen las que login usa). El registro ahora lo maneja `RegisterBloc`. `AuthBloc` conserva login, signOut y el estado de sesión global (que refleja el registro exitoso vía stream).

`AuthSession` no cambia (sigue `{userId, identifier, alias?}`); `identifier` = DNI.

## Los 4 pasos (UI)

1. **Datos** — card blanca con 4 inputs (`CuyCashTextField` extendido con `prefixIcon`): DNI (ícono `badge`, `inputmode numeric`, maxLength 8, helper "8 dígitos"), Nombres, Apellidos, Correo (ícono `mail`, helper sobre constancias/recuperación). Banner de error carmín cuando hay campos inválidos ("Revisa N campos para continuar"). Estado ok por campo (check verde) opcional. Strip informativo: "Validaremos tu identidad con una foto de tu DNI y reconocimiento facial." Footer: "Continuar" + nota de Términos/Privacidad.
2. **Documento** — dos cards: "Frente del DNI" y "Reverso del DNI". Cada una: marco punteado con esquinas, ícono cámara, botón "Tomar foto" (mock: → capturado) / "Volver a tomar". Estado capturado: pill verde "Capturado". Estado no legible: borde/pill carmín + tips ("Evita reflejos…", "Apoya el DNI…", "Encuadra las cuatro esquinas…"). Contador "N de 2 capturas". Footer de seguridad ("Tus documentos se cifran…"). "Continuar" habilita con ambas capturadas.
3. **Rostro** — pantalla inmersiva oscura: título "Centra tu rostro en el círculo", anillo de escaneo (viewport circular), instrucción ocre ("Gira lentamente la cabeza…"), checklist (Buena iluminación ✓ / Rostro descubierto ✓ / Prueba de vida — en proceso → ✓). Mock: al montar, `RegisterFaceScanStarted`; tras un delay simulado, `RegisterFaceScanCompleted` (o botón para simular). Caption "No cierres la app durante la verificación."
4. **Seguridad** — "Crea tu PIN de seguridad", 6 casillas de PIN (activa con cursor parpadeante), checklist de reglas (6 dígitos ✓, sin secuencias tipo 123456 ✓, "no uses tu fecha de nacimiento" gris/advisory), card de acceso biométrico con toggle (default ON), nota "CuyCash usa un solo factor…", footer "Finalizar registro" → `RegisterSubmitted`.

## Plan de tests

- `RegisterBloc` (`bloc_test`): validación paso 1 por campo (DNI no numérico/≠8, nombres/apellidos vacíos, email inválido); gating de avance por paso; simulación de captura (front/back → captured/unreadable) y gating; simulación facial; reglas de PIN (6 díg, secuencia); `RegisterSubmitted` OK → sesión emitida (vía Memory repo) y DNI duplicado → `IdentifierTaken`.
- `MemoryAuthRepository.register` (contrato): nueva firma, PIN 6 díg → WeakPin, DNI único, emite.
- Widget: `RegisterDataStep` (muestra errores + banner, "Continuar" deshabilitado/ habilitado), `RegisterDocumentStep` (captura → pill capturado), `RegisterPinStep` (reglas + habilita Finalizar). `RegisterFlowScreen` smoke (avanza de paso).
- Regresión: actualizar `auth_bloc_test` (quitar casos de register), `memory_auth_repository_test` (PIN 6, firma register), `login_screen_test` (PIN 6).

## Fuera de alcance

- Cámara real, OCR de DNI, ML de liveness/reconocimiento facial (todo simulado en mock).
- Backend Supabase real del registro (`SupabaseAuthRepository` sigue esqueleto).
- Persistencia del draft entre sesiones (el wizard es en memoria).
- Biometría real del dispositivo (el toggle solo guarda la preferencia en el draft).
