# Informe técnico de seguridad y cifrado

**APF2 · criterio 2: 2.1 Módulo de autenticación y autorización, 2.2 Informe
técnico de seguridad y mecanismos de cifrado.** Las pruebas de seguridad web
(2.3) están en [`plan-de-pruebas.md`](plan-de-pruebas.md#4-pruebas-de-seguridad-web)
y el catálogo de controles (2.4) en [`catalogo-controles.md`](catalogo-controles.md).

Actualizado al 2026-10-07. Sustituye en lo que se contradigan a la
presentación `docs/index.html`, que es anterior a la biometría y al despliegue
con HTTPS.

---

## 1. Tríada CIA aplicada

| Pilar | Qué protegemos | Cómo |
|---|---|---|
| **Confidencialidad** | PIN, tokens, datos personales, saldos | HTTPS extremo a extremo; PIN con argon2id; tokens guardados solo como hash; nombres enmascarados al buscar destinatarios; correo enmascarado; DNI nunca revelado al buscar por alias; secretos fuera del repositorio. |
| **Integridad** | Saldos y movimientos | Partida doble en una sola transacción; `CHECK` de saldo y monto en el motor; bloqueo de fila; idempotencia por `UNIQUE`; dinero en céntimos enteros. |
| **Disponibilidad** | Que el servicio responda | Despliegue gestionado (Render + Neon); health checks; PITR de 6 h; topes de consultas y bloqueos para que un atacante no agote recursos; tope de hashes argon2 simultáneos para no agotar memoria. |

## 2. Módulo de autenticación y autorización (2.1)

Código: `services/api/app/api/v1/routers/auth.py`, `otp.py`,
`app/core/deps.py`, `app/services/{sessions,lockout,otp,biometric}.py`; en la
app, `lib/feature/{auth,otp,device,lockout,biometric,security}`. Diseño en
[`adr/0002-backend-de-autenticacion.md`](adr/0002-backend-de-autenticacion.md).

### Factores

| Factor | Implementación |
|---|---|
| Algo que sabes | PIN de 6 dígitos; se rechazan los triviales (`000000`, `123456`…). |
| Algo que tienes | Teléfono vinculado (`X-Device-Id`). Un teléfono nuevo exige OTP. |
| Algo que recibes | OTP de 6 dígitos al correo: 10 min de vigencia, 3 intentos, 3 reenvíos, 60 s entre reenvíos. |
| Algo que eres | KYC facial en el registro (documento + liveness, ADR-0001). Huella o rostro del teléfono para el acceso rápido (`local_auth`), que libera una credencial emitida por el servidor. |

### Flujo de ingreso

1. **Bloqueos primero**: si el DNI o el teléfono están bloqueados, se responde
   423 sin mirar el PIN.
2. **PIN contra argon2id.** Si el DNI no existe, se hashea igual un valor de
   descarte y la respuesta tarda lo mismo (`UNIFORM_RESPONSE_SECONDS`): ni el
   mensaje ni el tiempo revelan qué DNI están registrados.
3. **¿Teléfono vinculado?** Sí → sesión. No → vale temporal + OTP al correo.
4. **Sesión**: token aleatorio de 256 bits; la base guarda solo su SHA-256.
   Vence a los 30 días sin uso (vencimiento deslizante).

### Bloqueo en dos ejes

| Eje | Umbral | Escalado | Protege contra |
|---|---|---|---|
| Por DNI | 3 fallos consecutivos | 15 min → 1 h → 24 h | Muchos teléfonos atacando una cuenta |
| Por dispositivo | 10 fallos en 15 min (ventana deslizante) | 15 min | Un teléfono barriendo muchas cuentas |

El PIN de una operación (enviar, abrir cuenta, cambiar PIN) alimenta el mismo
contador: no es una segunda puerta para adivinar el PIN.

**Desviación del SLA**: el SLA pide bloqueo al 5.º intento; el código bloquea
al 3.º (`IDENTIFIER_MAX_ATTEMPTS = 3`). Es más estricto; queda documentado.

### Autorización

- Un solo rol hoy: **el titular sobre sus propios recursos**. Toda ruta de
  dinero o perfil depende de `current_user` (`app/core/deps.py`); la
  autorización vive en un solo lugar para que una ruta nueva no quede abierta
  por olvido. `tests/test_sesion_requerida.py` recorre **todas** las rutas
  `/v1` sin token y exige 401, salvo las 10 públicas declaradas (las que abren
  o recuperan una sesión, y cerrar sesión, que es idempotente): una ruta nueva
  sin protección hace fallar la suite.
- **Propiedad del recurso**: una cuenta, movimiento, frecuente o dispositivo
  ajeno responde **404** y no 403, para no confirmar que existe.
- **Revocación**: cambiar el PIN cierra las sesiones de los otros teléfonos y
  revoca la credencial biométrica; desvincular un teléfono cierra sus sesiones.
  Es posible en una sentencia porque los tokens son opacos en base, no JWT.
- **Pendiente por diseño**: roles de operador, analista o administrador
  (RBAC). Llegan con el dashboard web y la conciliación; un RBAC sin endpoints
  que proteger sería código muerto.

## 3. Mecanismos de cifrado y hash (2.2)

| Dato | Mecanismo | Dónde | Por qué así |
|---|---|---|---|
| **PIN** | **argon2id** (argon2‑cffi, perfil por defecto: 64 MiB, ~30 ms) | `app/core/security.py` | Un PIN de 6 dígitos tiene 10⁶ combinaciones: el coste del hash es lo único que separa un volcado de la base de todos los PIN en claro. Resistente a GPU. Máximo 2 hashes simultáneos para no agotar los 512 MiB del plan. |
| **Token de sesión** | 256 bits (`secrets.token_urlsafe(32)`); se guarda **SHA‑256** | `security.py`, `sessions.py` | Es aleatorio: no hay diccionario que probar, así que basta un hash rápido. Un volcado de la base no da sesiones utilizables. |
| **Código OTP y vales** | Se guarda su SHA‑256, nunca el código | `services/otp.py` | Igual que el token. |
| **Credencial biométrica** | Secreto de 256 bits emitido por el servidor; la base guarda su SHA‑256; el teléfono lo guarda en el almacén cifrado y solo lo libera tras la huella | `services/biometric.py`; app `feature/biometric` | La huella nunca sale del teléfono; el servidor solo ve un secreto revocable. |
| **Tráfico app ↔ API** | **TLS (HTTPS)**; HTTP responde 301 a HTTPS; **HSTS** de 1 año | Render + Cloudflare; cabecera en `app/main.py` | Verificado en producción (ver `despliegue.md`). |
| **Tráfico API ↔ base** | **TLS** (`sslmode=require` → `ssl=True` de asyncpg) | `app/db/base.py` | Neon solo acepta conexiones cifradas. |
| **Datos en reposo (base)** | Cifrado del almacenamiento de Neon | [plataforma] | Lo provee el servicio gestionado. |
| **Datos en el teléfono** | `flutter_secure_storage`: Keychain (iOS) y Keystore/EncryptedSharedPreferences (Android) | `feature/device/infrastructure/secure_device_store.dart` | Identidad del teléfono, usuario recordado y credencial biométrica. El token de sesión **no** se persiste: vive en memoria y se pierde al cerrar la app. |

**Hashear no es cifrar.** El PIN y los tokens se hashean: no hay forma de
recuperarlos, solo de comprobarlos. Lo que debe volver a leerse (tráfico,
almacenamiento del teléfono) se cifra.

## 4. Protección de datos personales

- **Nombre enmascarado** (`C*** A*** N***`) al buscar un destinatario por DNI o
  alias; el nombre completo solo lo ve quien **recibió** dinero.
- **Buscar por alias no revela el DNI.** El alias es público y único, y lleva
  al menos una letra para no confundirse con un DNI.
- **Tope de consultas de destinatario**: 20 cada 10 min por usuario, un solo
  presupuesto para buscar, guardar frecuentes y enviar (contra el raspado del
  padrón).
- **Correo enmascarado** en `/v1/me` y en el OTP.
- **KYC**: se guarda el veredicto, nunca las imágenes del documento ni del
  rostro.
- **Pantallas sensibles** protegidas contra capturas (`SecureScreenScope`).

## 5. Defensa perimetral

| Control | Estado |
|---|---|
| HTTPS forzado (301) + HSTS | Implementado (HSTS desde este avance). |
| Cabeceras `nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Cache-Control: no-store` en `/v1` | Implementado (`app/main.py`). |
| CORS | **Cerrado a propósito**: sin `Access-Control-Allow-Origin`, ningún navegador de otro origen puede leer la API. La app nativa no usa CORS. Se abrirá con lista blanca exacta cuando exista el dashboard. |
| Inyección SQL | Mitigada por construcción: todo acceso pasa por el ORM con parámetros. Probado con cargas clásicas. |
| XSS | La API solo devuelve JSON con `nosniff`; los textos libres son datos. El cliente es nativo, sin WebView. Probado. |
| Límite por IP / WAF | **Pendiente.** Hay topes de negocio (por DNI, dispositivo y usuario) y Cloudflare delante de Render, pero no un límite por IP propio. |

## 6. Secretos

- `DATABASE_URL`, claves de KYC y de Telegram: variables secretas de Render
  (`sync: false`), nunca en el repositorio. `config.*.json` de la app está en
  `.gitignore`.
- **KYC en producción**: el build de producción **no** lleva la clave del KYC
  (`KYC_API_KEY` vacía), así que el registro usa la verificación simulada. El
  proxy `/v1/kyc/*` del backend ya existe para que la clave viva en el
  servidor; falta apuntar la app a él.

## 7. Riesgos abiertos

| # | Riesgo | Mitigación prevista |
|---|---|---|
| 1 | KYC real aún no conectado al proxy del backend | Apuntar `HttpKycRepository` a `/v1/kyc`. |
| 2 | Sin límite de peticiones por IP | Middleware de rate limit o regla de Cloudflare. |
| 3 | Vales de ingreso y topes de consultas en memoria del proceso | Llevarlos a la base o a Redis si hay más de una instancia. |
| 4 | Logs sin estructura ni correlación | Logs JSON con id de correlación. |
| 5 | Esquema sin migraciones | Alembic. |
| 6 | Concurrencia del libro mayor sin prueba en Postgres real | Correr `pytest -m postgres` contra una rama de Neon `_test`. |
