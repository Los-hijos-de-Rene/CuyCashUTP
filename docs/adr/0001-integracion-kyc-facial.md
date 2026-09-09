# ADR-0001 · Integración del servicio de KYC facial

- **Estado:** aceptado
- **Fecha:** 2026-09-09
- **Ámbito:** `apps/mobile` (feature `kyc`) ↔ `Los-hijos-de-Rene/CuyCashKYC`

## Contexto

El registro de CuyCash tiene dos pasos que hoy están **simulados**: la captura
del DNI (paso 2) y el reconocimiento facial (paso 3, un temporizador de 3 s con
un botón "Simular verificación").

Existe un microservicio propio —FastAPI, con MediaPipe y DeepFace— que resuelve
ambos. Su premisa de diseño es que **el teléfono no ejecuta modelos**: captura
ráfagas de frames y consulta al servidor, de modo que funcione en gama baja.

El servicio nació en el repositorio personal de Jheampierre y se movió a la
organización como `CuyCashKYC`, conservando su historial. El clon local guarda
su repo como `upstream`.

## Decisión

### 1. Vertical `feature/kyc`, como cualquier otra feature

`domain` (contrato + failures sellados) → `infrastructure` (`Http*` y `Memory*`)
→ `application` (`KycActions`). El bloc consumirá `KycActions`, nunca el repo.

### 2. El orden de las tareas jamás se genera en el cliente

El servidor devuelve una secuencia aleatoria de tareas y solo desbloquea la
siguiente cuando la actual pasa. Que el cliente **no conozca** la secuencia
antes de capturar es la protección anti-replay del servicio: si la app
generara su propio orden, un atacante podría grabar los cinco movimientos por
adelantado. Por eso `LivenessStep` no tiene constructor de secuencias.

### 3. `passed:false` es un valor, no un failure

Que un movimiento no se detecte es el usuario reintentando, no un error del
sistema. Viaja como `StepEvaluation(passed: false)` dentro del `Right`.
Mezclarlo con `KycFailure` haría que la UI mostrara una falla donde solo hubo
un gesto flojo.

### 4. `KycFailure` separa tres naturalezas distintas

| Failure | Naturaleza | Qué hace la UI |
|---|---|---|
| `challengeExpired` | el usuario tardó | rehacer el desafío |
| `stepOutOfOrder` | **bug del cliente** | no debería ocurrir; registrar |
| `challengeCompleted` | desfase de estado | saltar a la verificación final |
| `unauthorized` | configuración del despliegue | fallar el flujo, revisar config |
| `invalidResponse` | contrato roto | fallar; no adivinar |
| `serviceUnavailable` | red o 5xx | reintentar |

Aplanarlas a un solo error obligaría a la UI a tratar igual un problema del
usuario y un error de despliegue.

### 5. Una tarea desconocida invalida el desafío

Si el servidor manda un paso que esta versión de la app no sabe dibujar, se
responde `invalidResponse`. Pedirle al usuario algo que no podemos representar
es peor que fallar.

### 6. El `Memory*` reproduce las reglas, no dice que sí

`MemoryKycRepository` impone el orden, el TTL de 180 s, el mínimo de frames por
segmento y el consumo del token. Si fuera un stub complaciente, el flavor
`mock` permitiría recorridos que el servidor real rechaza, y el fallo aparecería
recién en el dispositivo.

## Contrato del que depende la app

Base: `{KYC_BASE_URL}`, header `X-API-Key`.

| Endpoint | Campos que la app **exige** |
|---|---|
| `POST /api/v1/liveness/challenge` | `token:str`, `steps:[str]`, `expires_in:int` |
| `POST /api/v1/liveness/evaluate` | `passed:bool`; opcionales `reason`, `frames_analyzed` |
| `POST /api/v1/identity/verify-full` | `overall_result:bool`; opcionales `overall_reason`, `document_validation.is_valid`, `liveness.is_live`, `face_match.is_match` |

Valores válidos de `steps`: `arriba`, `abajo`, `izquierda`, `derecha`,
`parpadeo`. Los frames son JPEG en base64 **sin** el prefijo `data:`.

## Riesgos abiertos

### R1 · La `X-API-Key` viaja en el binario — **el más serio**

Todo lo compilado en la app es extraíble: basta `strings` sobre el APK o un
proxy mirando el tráfico. Esa clave protege un endpoint que hace comparación
facial, así que filtrarla permite consumir el servicio y enviar pares
documento+selfie arbitrarios.

**Hoy es un atajo de demo, explícito en `AppEnv.kycApiKey` y en `CLAUDE.md`.**
La forma correcta es que la app hable con un backend propio que guarde la clave
y llame al servicio. Mientras CuyCash no tenga backend, no debe apuntarse a un
despliegue real con datos reales.

### R2 · Los errores se distinguen por texto en español

El servicio devuelve tres casos de negocio distintos dentro del mismo `400` y
solo se diferencian por el `detail`: `"inválido o expirado"`, `"ya fue
completado"`, `"se esperaba la tarea 'X'"`. La app los mapea por substring.

Cualquier reescritura de esos mensajes rompe la app **en silencio**.

> **Petición al servicio:** añadir un campo `code` estable —
> `CHALLENGE_EXPIRED`, `STEP_OUT_OF_ORDER`, `CHALLENGE_COMPLETED`— junto al
> `detail`. Es un cambio pequeño y elimina el acoplamiento al copy.

### R3 · La captura de frames es la pieza con más riesgo técnico

`takePicture()` no entrega 8-10 frames en 1,5 s. Hace falta `startImageStream`
y convertir YUV→JPEG en el dispositivo, que es CPU intensivo justo en los
teléfonos de gama baja que el servicio dice querer soportar. Es lo que más
probablemente se atasque.

### R4 · Tráfico en claro y direcciones de desarrollo

El servicio corre en `http://<ip>:8000`. Android bloquea cleartext desde API 28:
hará falta un `network_security_config` con la IP de desarrollo. Emulador:
`10.0.2.2`; teléfono físico: IP del PC en la LAN.

### R5 · Un documento contra dos capturas

`verify-full` acepta **una** `document_image`, pero el registro de CuyCash
captura frente y reverso. Falta decidir si se envía solo el frente o si el
servicio acepta ambas.

### R6 · TTL y tamaño del envío

180 s para cinco tareas con reintentos es ajustado en red lenta, y `verify-full`
sube 5 × 10 frames en una sola petición. Hay que controlar resolución y manejar
el vencimiento reiniciando el desafío.

### R7 · Estado del desafío en RAM del proceso

El servicio guarda los tokens en memoria y su propio código anota que un
despliegue multi-instancia necesitaría Redis. Con una sola instancia no es
problema; un reinicio invalida los desafíos en curso.

## Consecuencias

- El flavor `mock` sigue funcionando sin red ni servidor levantado: sin
  `KYC_BASE_URL`/`KYC_API_KEY` se cae al `Memory*` en vez de romper el arranque.
- El paso 3 del registro deja de ser un temporizador y pasa a ser un flujo
  guiado con reintento por tarea. Es un rediseño, no un cableado.
- Los frames son datos biométricos: no se escriben a disco ni a logs, y el
  wizard de registro ya corre con `FLAG_SECURE`.
- Cambiar el servicio y la app en un mismo PR no es posible (son dos repos), así
  que este documento es el punto de acuerdo. Cualquier cambio del contrato de
  arriba debe reflejarse aquí.
