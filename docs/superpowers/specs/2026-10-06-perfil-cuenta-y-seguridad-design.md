# CuyCash — Perfil: cuenta y seguridad

- **Fecha:** 2026-10-06
- **Épica:** 1 (identidad y accesos), HU02: autenticación biométrica con PIN de contingencia y
  bloqueo al 5.º intento.
- **Base:** Sprint 1 completo (DNI+PIN, OTP, KYC, bloqueo), cuentas y envío. El perfil existe pero
  sus cinco opciones de "Cuenta" y "Seguridad" solo avisan "Disponible en una próxima versión".
- **Flavor foco:** `local` y `production` (contra el backend). `mock` debe seguir arrancando entero
  con `Memory*`.

## Objetivo

Que las cinco opciones del perfil hagan lo que dicen:

1. **Datos personales:** ver los datos del titular (solo lectura).
2. **Editar mi alias.**
3. **Cambiar mi PIN** con la sesión abierta, reutilizando la mecánica de `RestablecerPinScreen`.
4. **Acceso biométrico real** con `local_auth`: entrar con huella o rostro desde el acceso rápido.
5. **Dispositivos vinculados:** verlos y desvincular los que no son este teléfono.

**Fuera de alcance (no inventar código de esto):** editar correo, nombres o DNI; alias únicos;
firma con par de claves en hardware (Secure Enclave / StrongBox); "Centro de ayuda" y "Términos y
privacidad" (siguen con el aviso de próximamente); notificaciones de seguridad (HU22).

## Estado de partida (lo que hay hoy)

- `users` guarda `nombres`, `apellidos`, `email`, `alias`, `kyc_status`, pero **ninguna ruta los
  devuelve**. La app solo conoce el `RememberedUser` local (DNI, nombre, alias).
- El alias se genera en el alta (`@` + primer nombre) y no hay ruta para cambiarlo.
- `/pin/reset` exige un ticket de OTP de *recuperación* y **cierra todas las sesiones**, incluida
  la propia: sirve para "olvidé mi PIN", no para cambiarlo con sesión abierta.
- **La biometría no existe.** El paso 4C del registro es un interruptor que no se guarda, y el botón
  de huella del acceso rápido es **simulado**: `QuickAccessBloc._onBiometric` activa una sesión
  inventada (`userId: 'mem-…'`) sin consultar al servidor. Esto se borra.
- `devices` guarda `device_id` (UUID aleatorio), `trusted_at`, `last_seen_at`; no hay nombre ni
  modelo, ni ruta para listarlos o desvincularlos.

## Decisiones

1. **Datos personales es solo lectura.** Vienen del KYC: cambiarlos exigiría re-verificar, y el
   correo es el canal del OTP de recuperación. El correo se devuelve **enmascarado**
   (`j***@gmail.com`); nunca completo.
2. **El alias no es único.** Es un nombre para mostrar; el envío identifica por DNI. Los alias
   automáticos ya colisionan hoy (`@juan`). Formato: `@` + 3–20 de `[a-z0-9_.]`.
3. **Cambiar PIN exige el PIN actual (no OTP)** y conserva la sesión de este teléfono. Revoca las
   sesiones y credenciales biométricas de los **otros** dispositivos. El PIN actual equivocado
   cuenta para el bloqueo igual que el login.
4. **El PIN actual se verifica al final, en la misma llamada** que fija el nuevo. Un endpoint que
   solo verifique el PIN sería un oráculo.
5. **La huella abre sesión con una credencial emitida por el servidor**, no guardando el PIN. Al
   activar, el servidor entrega una vez un secreto de 32 bytes ligado a (usuario, dispositivo) y
   guarda solo su hash. Desvincular el dispositivo o cambiar el PIN desde otro teléfono la revoca.
6. **Límite conocido:** `flutter_secure_storage` no exige la huella para leer el secreto; la huella
   es una puerta de la UI, no del hardware. Basta para la demo y el SLA; no resiste un teléfono
   rooteado. Cerrarlo requiere firma con claves en hardware (fuera de alcance).
7. **El dispositivo se muestra con su modelo**, que la app obtiene con `device_info_plus` y manda
   en `X-Device-Name`.
8. **Este teléfono no se desvincula desde la lista:** para eso está "Cerrar sesión".
9. **El registro activa la huella de verdad** si el usuario dejó el interruptor encendido en el
   paso 4C, con el PIN recién creado. Sin sensor, el paso no muestra el interruptor.

## Backend

Todas las rutas bajo `/api/v1`. Salvo `POST /sessions/biometric`, todas exigen `Bearer` y usan
`current_user`.

| Ruta | Entrada | Salida | Reglas |
|---|---|---|---|
| `GET /me` | — | `{dni, nombres, apellidos, email_masked, alias, kyc_status, created_at}` | Correo enmascarado: primera letra del usuario + `***` + `@dominio`. |
| `PATCH /me/alias` | `{alias}` | `{alias}` | Normaliza a minúsculas y antepone `@` si falta. Fuera de formato → 422 `INVALID_ALIAS`. |
| `POST /pin/change` | `{current_pin, new_pin}` | `{revoked_sessions}` | Ver abajo. |
| `GET /devices` | — | `[{id, nombre, plataforma, vinculado_el, ultimo_uso, es_este, con_huella}]` | `es_este` compara con `X-Device-Id`. Orden: este primero, luego por `ultimo_uso` desc. |
| `DELETE /devices/{id}` | — | 204 | Ver abajo. |
| `POST /biometric/enroll` | `{pin}` | `{credential}` | Ver abajo. |
| `DELETE /biometric/current` | — | 204 | Revoca la credencial de este dispositivo. 204 aunque no haya. |
| `POST /sessions/biometric` | `X-Device-Id`, `{dni, credential}` | `{result: "session", session_token, user}` | Ver abajo. |

**`POST /pin/change`:**
1. Si el DNI o el dispositivo están bloqueados → 423 con `locked_until`.
2. Verifica `current_pin`. Si falla: `lockout.register_failure(dni, device)`; si eso bloquea → 423
   y **revoca la sesión actual**; si no → 401 `INVALID_CREDENTIALS` con `attempts_left`.
3. `pin_is_valid(new_pin)` o 422 `WEAK_PIN`; igual al actual → 422 `PIN_UNCHANGED`.
4. Guarda el hash, `pin_updated_at`, `lockout.register_success`.
5. Revoca sesiones y credenciales biométricas de los **otros** `device_id` del usuario. Devuelve
   cuántas sesiones revocó.

**`DELETE /devices/{id}`:**
- No es de este usuario → 404. Es el dispositivo de la petición → 409 `CANNOT_UNLINK_CURRENT`.
- Revoca las sesiones de ese `device_id` del usuario, revoca su credencial biométrica y borra la
  fila de `devices`: la próxima entrada desde ahí pedirá el OTP de dispositivo.

**`POST /biometric/enroll`:**
- Mismo bloqueo y conteo de intentos que `/pin/change` paso 1–2.
- Revoca la credencial vigente de (usuario, este dispositivo) y crea una nueva con
  `secret_hash = sha256(secret)`. El secreto (`new_token()`) se devuelve una sola vez.

**`POST /sessions/biometric`:**
- Bloqueo vigente del DNI o del dispositivo → 423.
- Busca el usuario por DNI, la credencial vigente de (usuario, `X-Device-Id`) y compara hashes en
  tiempo constante. El dispositivo debe seguir en `devices` para ese usuario.
- **Cualquier fallo → 401 `BIOMETRIC_REVOKED`, el mismo para todos los casos** (no delata si el DNI
  existe). No suma intentos al bloqueo: el secreto tiene 256 bits.
- Éxito: abre sesión como `authenticate` y actualiza `last_seen_at`.

**Esquema:**
- Tabla nueva `biometric_credentials`: `id`, `user_id` (FK), `device_id`, `secret_hash` (único),
  `created_at`, `revoked_at` (nullable).
- `devices` gana `nombre` (String 80, nullable) y `plataforma` (String 20, nullable).
- `X-Device-Name` (opcional, se trunca a 80) en `register`, `authenticate`, `sessions` y
  `sessions/biometric`: se guarda o actualiza en la fila del dispositivo. La plataforma se deduce
  del prefijo que manda la app (`android` / `ios`).
- `create_all` no altera tablas existentes: **las columnas nuevas de `devices` exigen
  `scripts/reset_schema.py`** en bases ya creadas. `schema.sql` se regenera con
  `scripts/dump_schema.py`. `docs/modelo-datos.md` se actualiza.

## App

### Features nuevas

Cada una con `domain/application/infrastructure` y su `Memory*` funcional (regla 3).

| Feature | Interfaz | Contenido |
|---|---|---|
| `profile` | `ProfileRepository` | `me()` → `PersonalData`; `updateAlias(String)` → `String`. Actions: `ProfileActions`. |
| `security` | `SecurityRepository` | `changePin({current, nuevo})` → `int` revocadas; `devices()` → `List<LinkedDevice>`; `unlinkDevice(id)`; `enrollBiometric(pin)` → `String` credencial; `revokeBiometric()`. Actions: `SecurityActions`. |
| `biometric` | `BiometricGate` | `isAvailable()` (sensor + huellas registradas) y `authenticate(reason)` → `BiometricOutcome {success, cancelled, unavailable, failed}`. Implementación `LocalAuthBiometricGate`; `MemoryBiometricGate` configurable para tests y `mock`. |

### Cambios en lo existente

- `AuthRepository.signInWithBiometric({dni, credential})`: emite sesión igual que `signIn`.
  `AuthFailure` gana `biometricRevoked`.
- `DeviceStore` gana `readBiometricCredential`, `saveBiometricCredential`,
  `clearBiometricCredential`. Se borra también al cerrar sesión con cambio de usuario
  (`clearUser`).
- `buildAuthenticatedDio` y el `dio` de auth mandan `X-Device-Name`. El nombre se resuelve una vez
  con `device_info_plus` al armar el grafo en `envs/shared` (formato `android · Samsung SM-A546E` /
  `ios · iPhone14,5`).
- `AppDependencies` gana `profileRepository`, `securityRepository`, `biometricGate`; módulos
  `ProfileModule`, `SecurityModule`, `BiometricModule`.
- Dependencias: `local_auth`, `device_info_plus`. Android: `MainActivity` hereda de
  `FlutterFragmentActivity`, permiso `USE_BIOMETRIC`. iOS: `NSFaceIDUsageDescription`.

### Pantallas

Rutas en `AppRoutes`, abiertas con `push` sobre la pestaña de perfil (como `/movimientos/:id`).

1. **`/perfil/datos` — Datos personales.** `PersonalDataBloc` → skeleton (`SkeletonBox`) mientras
   carga, filas de solo lectura (nombres, apellidos, DNI, correo enmascarado, alias, cliente desde)
   y sello "Identidad verificada" / "Verificación pendiente". Error con "Reintentar".
2. **`/perfil/alias` — Editar alias.** Campo con prefijo `@` fijo, validación en vivo con la misma
   regla que el backend; "Guardar" deshabilitado si no cambió o es inválido. Al guardar actualiza el
   `RememberedUser` (`DeviceActions.saveUser`) para que perfil e inicio lo muestren sin reentrar, y
   vuelve con un aviso.
3. **`/perfil/pin` — Cambiar PIN.** `ChangePinBloc` con tres pasos sobre la misma ruta, siguiendo
   `RestablecerPinScreen`: **actual → nuevo (con checklist `PinRule`) → confirmar**. Reutiliza
   `PinEntryView`, las reglas y su validación (se extraen de `ResetPinBloc`/registro a un helper
   compartido si hoy están duplicadas). Sexto dígito = avanzar; en el paso de confirmar, si no
   coincide, vuelve a "nuevo". La llamada al servidor ocurre al confirmar.
   - PIN actual errado → vuelve al paso 1 con "Te quedan N intentos".
   - 423 → `/bloqueado` con `BlockedArgs`.
   - Red → resultado desconocido: "No sabemos si tu PIN cambió. Intenta entrar con el nuevo o el
     anterior." Sin reintento automático.
   - Éxito → constancia: "Tu PIN cambió" + "Cerramos tu sesión en N dispositivos" si N > 0.
4. **`/perfil/biometria` — Acceso biométrico.** `BiometricSettingsBloc`. Interruptor con estado
   real (hay credencial guardada).
   - Sin sensor o sin huellas: explicación y el interruptor deshabilitado.
   - Encender: pedir PIN (`PinEntryView`) → `BiometricGate.authenticate` → `enroll` → guardar
     secreto. Si guardar falla, `revokeBiometric` y avisar. Cancelar el diálogo del sistema no es
     error: vuelve al estado apagado sin mensaje.
   - Apagar: `revokeBiometric` + borrar el secreto local. Sin red se borra igual el local (el
     servidor queda con una credencial que nadie tiene; se revoca en el próximo `enroll`).
5. **`/perfil/dispositivos` — Dispositivos vinculados.** `LinkedDevicesBloc`. Lista: modelo,
   plataforma, "Este teléfono", vinculado el, último uso, ícono de huella si `con_huella`.
   "Desvincular" (no en este teléfono) pide confirmación; 404 se trata como éxito; refresca la
   lista.

`ProfileScreen`: las cinco opciones navegan; "Ayuda" sigue con próximamente.

### Acceso rápido

- Se borra la biometría simulada de `QuickAccessBloc`.
- El botón de huella aparece solo si hay credencial guardada **y** `BiometricGate.isAvailable()`.
- Tocarlo: `authenticate` → `signInWithBiometric(dni, credential)`.
  - `biometricRevoked` → borrar credencial, ocultar el botón, "Usa tu PIN".
  - 423 → `/bloqueado`.
  - Cancelado → nada.
- El teclado de PIN siempre está en pantalla (contingencia).

### Registro

Paso 4C: si `isAvailable()` es falso, no se muestra el interruptor. Si queda encendido, al terminar
el alta (con sesión abierta) se hace `enroll` con el PIN creado; un fallo ahí no rompe el alta:
se avisa que puede activarla desde el perfil.

## Errores

Failures sellados por feature (reglas 1 y 2):

- `ProfileFailure`: `network`, `unauthenticated`, `invalidAlias`, `unexpected`.
- `SecurityFailure`: `wrongPin(attemptsLeft)`, `locked(until)`, `weakPin`, `pinUnchanged`,
  `cannotUnlinkCurrent`, `deviceNotFound`, `biometricUnavailable`, `network`, `unauthenticated`,
  `unexpected`. (`biometricCancelled` es un `BiometricOutcome`, no un failure.)
- `AuthFailure.biometricRevoked`.

Copy es-PE en el ARB (regla 7).

## SLA

- **Autenticación biométrica < 1.5 s:** diálogo del sistema + una petición con SHA-256 (sin
  bcrypt/argon del PIN). **Sin medición automatizada**, como los 200 ms del motor transaccional.
- **PIN de contingencia siempre visible** en el acceso rápido.
- **Bloqueo al 5.º intento:** `/pin/change` y `/biometric/enroll` usan el mismo contador que el
  login.

## Pruebas

**Backend (pytest, SQLite):**
- `/me`: devuelve los datos; el correo nunca completo; sin token → 401.
- `/me/alias`: normaliza, rechaza formato, persiste.
- `/pin/change`: éxito; PIN actual errado descuenta intentos y al 5.º → 423 y sesión revocada;
  `WEAK_PIN`; `PIN_UNCHANGED`; revoca sesiones y credenciales de **otros** dispositivos y conserva
  las de este.
- `/devices`: lista con `es_este` y `con_huella`; desvincular otro → sus sesiones y credencial
  revocadas y su próxima entrada pide OTP; propio → 409; ajeno → 404.
- Biometría: `enroll` reemplaza la anterior; `/sessions/biometric` abre sesión; revocada, de otro
  dispositivo, de otro DNI o con dispositivo desvinculado → 401 idéntico; bloqueado → 423.
- `X-Device-Name` se guarda y se actualiza.

**App:**
- Contrato compartido `Memory*` / `Http*` (dio simulado) para `ProfileRepository` y
  `SecurityRepository`; `signInWithBiometric` en el contrato de auth.
- `bloc_test` de cada bloc nuevo.
- Widgets: cada pantalla; cambio de PIN en tres pasos con fallo, vuelta y bloqueo; biometría con
  `MemoryBiometricGate` (éxito, cancelado, no disponible, guardar falla).
- Acceso rápido: botón visible/oculto según credencial y sensor; credencial revocada la borra.
- Recorrido por el router real (flavor `mock`) desde el perfil a cada pantalla.

**Manual (no ejecutable aquí):** el diálogo real de `local_auth` en Android e iOS. Se agrega a
`docs/verificacion-manual.md` marcado como **no ejecutado**.

## Orden de implementación

Cada paso deja la app arrancando y la suite en verde.

1. `X-Device-Name` + columnas de `devices`.
2. Datos personales (`GET /me` + pantalla).
3. Alias.
4. Cambiar PIN.
5. Dispositivos vinculados.
6. Biometría: backend → `BiometricGate` → pantalla del perfil → acceso rápido → registro.
