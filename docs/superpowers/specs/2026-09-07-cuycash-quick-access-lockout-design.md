# CuyCash — Acceso rápido, usuario recordado, intentos/bloqueo y cambiar de usuario

- **Fecha:** 2026-09-07
- **Base:** login DNI+PIN (6 díg), registro (wizard) y éxito ya construidos.
- **Flavor foco:** `mock`. Enforcement de servidor (RateLimiter por DNI/IP, tokens de dispositivo, verificación por correo) es **backend**, se difiere; el cliente **simula** el conteo/bloqueo y la biometría.

## Objetivo

Introducir el **acceso rápido para un dispositivo con usuario recordado** y su seguridad de cliente:

- **Acceso rápido**: al abrir la app, si hay un usuario recordado en este dispositivo, se muestra "Hola, {Nombre}" con teclado numérico para el PIN (6 díg) + botón biométrico (simulado).
- **Usuario recordado**: tras un login/registro exitoso se guarda el perfil mínimo cifrado; "¿No eres {Nombre}?" y "Salir de esta cuenta" lo borran.
- **Intentos + bloqueo**: 3 intentos de PIN; al fallar el 3.º, bloqueo con cuenta regresiva escalonada (15 min → 1 h → 24 h). Aplica al acceso rápido y al login DNI+PIN.
- **Cambiar de usuario**: diálogo "¿Salir de esta cuenta?" (copy corregido) que revoca la sesión local y vuelve al login.

**Diferido (próximas variantes que el usuario pasará):** "Verificar código" para dispositivo nuevo (DNI+PIN → código al correo → vincular), aviso de dispositivo nuevo (RF09), y Perfil → Seguridad → Dispositivos vinculados.

## Decisiones

1. **Persistencia local con `flutter_secure_storage`** (Keychain / EncryptedSharedPreferences), usada en TODOS los flavors (capacidad del dispositivo, no backend). Fake en memoria solo para tests.
2. **Biometría simulada**: tocar el botón huella = éxito inmediato (autentica al usuario recordado). El `local_auth` real se difiere.
3. **Intentos/bloqueo simulados en cliente**, persistidos (sobreviven reinicio). Enforcement real: backend.
4. **Copy corregido** del diálogo de salida: "… tendrá que ingresar **su DNI y su PIN de seguridad** …" (no "correo y contraseña").

## Reglas duras (heredadas)

Errores como valores; failures sellados; `Memory*` funcional = contrato de tests; estados sealed + `switch` exhaustivo (sin `when`/`maybeWhen`/`!`); DI por constructor; el Bloc consume `application`, nunca el repo; tokens del design system (cero hex sueltos); copy es-PE en ARB; un widget público por archivo; `.freezed.dart` se commitea.

---

## Arquitectura

### Feature `device` (nuevo) — estado local del dispositivo
Dart puro (domain/application) + infra con secure storage.

- **domain/**
  - `RememberedUser { String dni; String fullName; String alias; }` con `initials` derivadas (2 letras) y `firstName`.
  - `LockoutState { int failedAttempts; DateTime? lockedUntil; }` — `bool isLocked(DateTime now)`.
  - `DeviceStore` (interface): 
    - `Future<RememberedUser?> readUser()` · `Future<void> saveUser(RememberedUser)` · `Future<void> clearUser()`
    - `Future<LockoutState> readLockout()` · `Future<void> saveLockout(LockoutState)` · `Future<void> clearLockout()`
    - Nunca lanza; en error de lectura devuelve null / estado vacío (dato local no crítico).
- **infrastructure/**
  - `SecureDeviceStore implements DeviceStore` — `flutter_secure_storage`, claves JSON. Usada en `mock`/`local`/`production`.
  - `MemoryDeviceStore implements DeviceStore` — en memoria, para tests.
- **application/**
  - `DeviceActions(DeviceStore)` — delegación fina (readUser/saveUser/clearUser/readLockout/saveLockout/clearLockout).

> El reloj (`DateTime.now`) se inyecta en la capa que evalúa el bloqueo (bloc) como `DateTime Function()` para poder testear la cuenta regresiva sin esperar tiempo real.

### Escalonado de bloqueo
`failedAttempts` cuenta fallos consecutivos. Al llegar a 3, se fija `lockedUntil = now + duración`, donde la duración escala por nº de bloqueos previos: 1.º = 15 min, 2.º = 1 h, 3.º+ = 24 h. (El "nº de bloqueos" se guarda como parte de `LockoutState` — campo `lockoutLevel`.) Un login exitoso limpia `LockoutState`.

### Integración con auth existente
- **Guardar recordado**: cuando el usuario queda autenticado tras login o registro, se guarda `RememberedUser` (dni, fullName, alias). El nombre completo: en login no lo tenemos (solo DNI) → derivar del alias/DNI; en registro sí (nombres+apellidos). Para login, `fullName` = alias sin `@` capitalizado, o "Usuario"; se refina cuando el backend devuelva el perfil. (Placeholder documentado.)
- **Verificación de PIN**: el acceso rápido usa `AuthActions.signIn(identifier: rememberedUser.dni, pin: enteredPin)`.
- **Biometría (sim)**: éxito → `AuthActions.activate(AuthSession(userId, identifier: dni, alias))` con los datos del recordado (sin PIN).
- **Salir/cambiar usuario**: `AuthActions.signOut()` + `DeviceActions.clearUser()` → login.

### Presentación (blocs + pantallas)
- **`QuickAccessBloc`** (`presentation/quick_access/bloc/`): consume `AuthActions` + `DeviceActions` + reloj inyectado.
  - Estado: `RememberedUser user`, `String pin` (0–6 díg), `QuickAccessStatus {idle, verifying}`, `int attemptsLeft`, `bool lastAttemptWrong`, `DateTime? lockedUntil`.
  - Eventos: `DigitPressed(d)`, `BackspacePressed`, `BiometricPressed`, `PinCompleted` (auto al llegar a 6), `Cleared`. Al completar 6 díg → `signIn`; éxito → sesión emitida → gate → home; fallo → `attemptsLeft--`, limpia PIN, marca error; al 3.º → fija lockout y navega a bloqueado.
- **Pantallas** (`presentation/quick_access/`):
  - `QuickAccessScreen`: avatar con iniciales, "Hola, {firstName}", 6 dots, keypad (`PinKeypad`), botón biométrico, "¿No eres {firstName}?" (→ switch-user), "Olvidé mi PIN" (→ recuperación, placeholder). Estado de error: banner carmín "PIN incorrecto. Te quedan N intentos. Tras 3 intentos fallidos tu acceso se bloqueará por 15 minutos."
  - `AccessBlockedScreen`: ícono candado, "Tu acceso está bloqueado", card con cuenta regresiva (mm:ss, `tabular figures`) hacia `lockedUntil` + "Último intento", "Recuperar mi PIN", "Escribir a soporte por WhatsApp". Al expirar el contador → vuelve a acceso rápido/login.
  - `SwitchUserDialog`: "¿Salir de esta cuenta?" + copy **"{Nombre} tendrá que ingresar su DNI y su PIN de seguridad para volver a entrar en este teléfono."** + tira de consecuencias (huella/​sesión) + "Salir de esta cuenta" (primario) / "Cancelar". Confirmar → signOut + clearUser → login.
- **Componentes design_system nuevos**: `PinKeypad` (grid 3×4: 1-9, biométrico, 0, backspace; teclas circulares con ripple), `PinDots({count,filled})` (indicador de 6 puntos rellenos/vacíos, distinto de `PinBoxes`). `InitialsAvatar({initials})`.

### Flujo / router
- **Splash decide** (leyendo DeviceStore): 
  - `lockout.isLocked(now)` → `/bloqueado`
  - `rememberedUser != null` → `/acceso-rapido`
  - si no → `/onboarding`.
- **Gate** (`app_redirect`): añadir `/acceso-rapido` y `/bloqueado` al conjunto permitido para NO autenticados (como onboarding/login/registro). Autenticado en cualquiera de ellas → `/home`.
- **Login DNI+PIN**: también cuenta intentos/bloqueo (comparte `DeviceStore`/lógica). 3 fallos → `/bloqueado`.
- **Tras autenticar** (login/registro "Ir a mi cuenta"): guardar `RememberedUser` + limpiar lockout.
- **Rutas nuevas:** `AppRoutes.quickAccess = '/acceso-rapido'`, `AppRoutes.blocked = '/bloqueado'`.

## Plan de tests
- `MemoryDeviceStore` (contrato: user save/read/clear; lockout save/read/clear).
- `DeviceActions` (delegación).
- Escalonado de bloqueo (función pura con reloj inyectado): 15m/1h/24h por nivel; `isLocked`.
- `QuickAccessBloc` (`bloc_test`, reloj fake): digit/backspace; PIN correcto → autentica; PIN incorrecto → attemptsLeft baja y limpia; 3.º fallo → lockedUntil fijado; biométrico → autentica.
- Widget: `QuickAccessScreen` (dots reflejan pin, keypad dispara dígitos, error banner), `AccessBlockedScreen` (muestra countdown), `SwitchUserDialog` (copy correcto, confirmar → callbacks).
- Regresión: login DNI+PIN con lockout; splash redirige según DeviceStore.

## Fuera de alcance
- `local_auth` real (biometría simulada).
- Verificación de dispositivo por código al correo (próxima variante).
- Aviso de dispositivo nuevo (RF09) y pantalla de Dispositivos vinculados.
- Enforcement real de rate-limit / tokens (backend).
- Persistencia real del perfil completo del usuario en login (fullName placeholder hasta backend).
