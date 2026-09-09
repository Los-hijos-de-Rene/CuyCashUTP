# ADR-0002 · Backend de autenticación

- **Estado:** propuesto
- **Fecha:** 2026-09-09
- **Ámbito:** servicio nuevo ↔ `apps/mobile` (features `auth`, `otp`, `lockout`)

## Contexto

CuyCash identifica a la persona por **DNI + PIN de 6 dígitos**. No hay
contraseña ni correo como identificador de acceso; el correo solo sirve para
recuperar el PIN y para verificar un teléfono nuevo.

Se había asumido Supabase Auth. No encaja: está construido alrededor de
email+contraseña y OAuth, y forzarlo obliga a inventar un correo sintético por
usuario. En cuanto se necesitan bloqueo escalonado por DNI, vinculación de
dispositivos y revocación de sesiones al cambiar el PIN, se termina peleando
contra la herramienta.

Hoy toda esa lógica está **simulada en el cliente** (`Memory*`), y buena parte
de ella no puede vivir ahí ni siquiera en teoría: un contador de intentos que
guarda el propio teléfono se borra reinstalando la app.

## Decisión

### Stack: FastAPI + PostgreSQL, en un servicio aparte del KYC

El argumento principal es de equipo, no de rendimiento: **el servicio de KYC ya
está en FastAPI y lo mantiene el mismo equipo**. Compartir lenguaje significa
que ambos pueden revisar y tomar el código del otro, con una sola historia de
despliegue. En un proyecto con fecha de entrega, la habilidad que el equipo ya
tiene vale más que cualquier comparativa de lenguajes.

La carga —unas pocas peticiones por registro y por login— no justifica elegir
por concurrencia. Go sería una buena elección si el objetivo fuera aprenderlo o
si una sola persona fuera a mantenerlo todo.

**Servicio separado del KYC**: ese arrastra DeepFace y MediaPipe, con imágenes
de Docker grandes y builds lentos. El de auth no debe cargar con eso para
desplegar un cambio menor.

**Postgres gestionado (el de Supabase sirve)**: descartar Supabase Auth no
obliga a descartar su Postgres. Se usa la base; el auth se escribe aquí. Si se
toma ese camino, hay que quitar `supabase_flutter` de la app: dejarlo sugiere
que el cliente habla con Supabase, y dejaría de ser cierto.

## Contrato

Todo bajo `/v1`. El cliente manda siempre `X-Device-Id`, un identificador
estable que la app guarda en el almacén cifrado.

| Endpoint | Reemplaza a | Notas |
|---|---|---|
| `POST /auth/register` | `AuthRepository.register` | crea la cuenta; NO abre sesión |
| `POST /auth/authenticate` | `AuthRepository.authenticate` | valida el PIN sin abrir sesión |
| `POST /auth/sessions` | `AuthRepository.activate` / `signIn` | abre sesión; exige dispositivo de confianza o `otp_ticket` |
| `DELETE /auth/sessions/current` | `AuthRepository.signOut` | |
| `POST /auth/pin/check-current` | `AuthRepository.isCurrentPin` | ver la advertencia de abajo |
| `POST /auth/pin/reset` | `AuthRepository.resetPin` | exige `otp_ticket`; revoca todas las sesiones |
| `POST /otp/challenges` | `OtpRepository.request` | |
| `POST /otp/challenges/{id}/verify` | `OtpRepository.verify` | devuelve `otp_ticket` al pasar |
| `POST /otp/challenges/{id}/resend` | `OtpRepository.resend` | |
| `POST /kyc/*` | — | proxy del servicio de KYC (R1 del ADR-0001) |

### `authenticate` devuelve uno de tres resultados

```json
{"result": "session",  "access_token": "...", "refresh_token": "..."}
{"result": "device_verification_required", "pending_token": "...", "masked_email": "j•••••@gmail.com"}
{"result": "rejected", "attempts_left": 2, "next_lockout_seconds": 900}
```

El `pending_token` es de un solo uso y corto: acredita que el PIN fue correcto,
para que el OTP de dispositivo no tenga que volver a pedirlo.

### Errores con `code` estable

Igual que se le pidió al servicio de KYC (R2 del ADR-0001), cada error lleva un
`code` que no depende del texto:

```json
{"code": "IDENTIFIER_LOCKED", "detail": "…", "locked_until": "2026-09-09T10:15:00Z"}
```

`INVALID_CREDENTIALS`, `IDENTIFIER_LOCKED`, `DEVICE_LOCKED`,
`CHALLENGE_EXPIRED`, `CHALLENGE_CANCELLED`, `STEP_OUT_OF_ORDER`,
`PIN_UNCHANGED`, `WEAK_PIN`.

## Esquema

```
users          (id, dni UNIQUE, nombres, apellidos, email, alias,
                pin_hash, pin_updated_at, kyc_status, created_at)
devices        (id, user_id, device_id, label, trusted_at, last_seen_at)
sessions       (id, user_id, device_id, token_hash, created_at,
                expires_at, revoked_at)
lockouts       (subject_type, subject_value, level, locked_until, updated_at)
login_attempts (id, dni, device_id, ip, succeeded, created_at)
otp_challenges (id, purpose, identifier, user_id NULL, code_hash,
                expires_at, cooldown_until, attempts_left, resends_left,
                consumed_at, cancelled_reason)
audit_log      (id, user_id NULL, event, metadata, ip, created_at)
```

`lockouts.subject_type` es `dni`, `device` o `ip`: es lo que permite tener los
dos contadores que hoy faltan sin duplicar tablas.

## Garantías que el servicio debe cumplir

Estas no son detalles de implementación: son la razón de que el backend exista.

1. **El PIN se guarda con argon2id y nunca se registra en logs.** Tampoco
   aparece en trazas de error.
2. **El código OTP también se guarda hasheado.** Es una credencial de un solo
   uso, no un dato.
3. **Respuestas indistinguibles.** Un DNI inexistente y un PIN equivocado deben
   devolver lo mismo, y **tardar lo mismo**. Si validar un DNI que no existe es
   más rápido, el canal temporal reabre la enumeración de cuentas que se cerró
   en el cliente.
4. **El contador corre igual para DNI inexistentes.** Si solo contara para
   cuentas reales, el propio bloqueo delataría cuáles lo son.
5. **Dos contadores, no uno** (el hueco abierto hoy):
   - por DNI: protege una cuenta contra muchos teléfonos. 3 intentos,
     escalado 15 min → 1 h → 24 h.
   - por dispositivo/IP: protege contra barrer muchas cuentas desde un
     teléfono. Umbral más alto (≈10 fallos en 15 min) y **ventana deslizante,
     no contador que se reinicia**: si un login correcto lo pusiera a cero,
     bastaría con intercalar una entrada válida cada 9 intentos.
6. **Cambiar el PIN revoca todas las sesiones**, incluida la del teléfono que lo
   cambió: restablecer no otorga acceso.
7. **La `X-API-Key` del KYC vive solo aquí.** La app deja de conocerla.

### Advertencia sobre `check-current`

Existe para que el paso 1 de "Restablecer PIN" rechace el PIN actual sin
esperar doce dígitos. Preguntado a discreción **es un oráculo del PIN**: hay que
exigir un `otp_ticket` válido y limitarlo a unos pocos intentos por ticket. Si
no se puede garantizar, es preferible quitarlo y volver a validar al guardar.

## Sesiones: tokens opacos, no JWT

La revocación es un requisito duro (garantía 6), y un JWT autocontenido no se
puede revocar sin una lista de bloqueo que anula su ventaja. Se recomiendan
**tokens opacos guardados hasheados** en `sessions`, validados contra la base.
El volumen de este proyecto lo permite de sobra.

## Consecuencias para la app

Ninguna pantalla ni ningún bloc cambia. `AuthRepository`, `OtpRepository` e
`IdentifierLockoutStore` ya son interfaces con implementación `Memory*`; se
suma una `Http*` y se cablea por flavor. Eso era el propósito de la regla 3 del
`CLAUDE.md`.

Sí cambian tres cosas:

- El bloqueo por DNI deja de vivir en RAM del cliente: el `lockedUntil` llega en
  la respuesta. `MemoryIdentifierLockoutStore` queda solo para el flavor `mock`.
- La app pasa a mandar `X-Device-Id`.
- `supabase_flutter` sale de las dependencias.

## Decisiones abiertas

- **Proveedor de correo** para el OTP (hoy no se envía nada).
- **Dónde vive el proxy del KYC**: dentro de este servicio o como uno tercero.
  Lo simple es aquí.
- **Rotación del refresh token** y su vida útil.
- **Qué se guarda del KYC**: aprobado/rechazado basta. Guardar los frames sería
  almacenar datos biométricos, con todo lo que eso implica; la recomendación es
  no hacerlo.
