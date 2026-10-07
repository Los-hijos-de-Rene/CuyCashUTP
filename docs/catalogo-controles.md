# Catálogo de controles de seguridad

**APF2 · criterio 2.4.** Cada control dice qué pilar de la tríada CIA protege,
dónde está implementado y qué prueba lo respalda. Rutas de código relativas a
`services/api/` (backend) o `apps/mobile/lib/` (app).

Pilar: **C** confidencialidad, **I** integridad, **D** disponibilidad.
Tipo: **P** preventivo, **D** detectivo, **R** correctivo.

## Identidad y acceso

| ID | Control | CIA | Tipo | Implementación | Evidencia (prueba) | Estado |
|---|---|---|---|---|---|---|
| AC-01 | PIN de 6 dígitos sin patrones triviales | C | P | `app/core/security.py · pin_is_valid` | `test_registro_y_login.py`, `test_cambio_de_pin.py` (`WEAK_PIN`) | ✅ |
| AC-02 | PIN hasheado con argon2id | C | P | `app/core/security.py` | Revisión de código; `users.pin_hash` en `schema.sql` | ✅ |
| AC-03 | Respuesta uniforme exista o no el DNI (mensaje y tiempo) | C | P | `routers/auth.py · _uniform_delay, _burn_cycles` | Mensaje: `test_registro_y_login.py · test_el_error_no_distingue_dni_inexistente_de_pin_equivocado`. Tiempo: revisión de código (la suite lo pone en 0 para no esperar) | ✅ |
| AC-04 | Bloqueo por DNI escalonado (3 fallos → 15 min, 1 h, 24 h) | C D | P | `app/services/lockout.py` | `test_registro_y_login.py` | ✅ |
| AC-05 | Bloqueo por dispositivo con ventana deslizante | C D | P | `app/services/lockout.py` | `test_bloqueo_por_dispositivo.py` | ✅ |
| AC-06 | OTP al correo para vincular un teléfono nuevo | C | P | `app/services/otp.py`, `routers/otp.py` | `test_otp_y_recuperacion.py` | ✅ |
| AC-07 | OTP con vigencia, intentos y reenvíos limitados; guardado como hash | C | P | `app/services/otp.py`, `core/config.py` | `test_otp_y_recuperacion.py` | ✅ |
| AC-08 | Token de sesión opaco de 256 bits, guardado como SHA‑256 | C | P | `app/services/sessions.py` | `test_sesion_requerida.py` | ✅ |
| AC-09 | Toda ruta privada exige sesión (una sola dependencia) | C I | P | `app/core/deps.py · current_user` | `test_sesion_requerida.py · test_toda_ruta_privada_exige_sesion` | ✅ |
| AC-10 | Recurso ajeno responde 404 (no confirma que exista) | C | P | `routers/accounts.py · _cuenta_propia`, `profile.py` | `test_cuentas_y_movimientos.py`, `test_dispositivos.py` | ✅ |
| AC-11 | Cambiar el PIN cierra las otras sesiones y revoca la huella | C | R | `routers/auth.py · pin/change` | `test_cambio_de_pin.py` | ✅ |
| AC-12 | Desvincular un dispositivo cierra sus sesiones | C | R | `routers/profile.py · desvincular` | `test_dispositivos.py` | ✅ |
| AC-13 | Acceso biométrico con credencial del servidor, revocable | C | P | `app/services/biometric.py`; app `feature/biometric` | `test_biometria.py` | ✅ |
| AC-14 | KYC facial en el registro (documento + liveness) | C I | P | app `feature/kyc`; ADR-0001 | Tests de `feature/kyc` | ⚠️ simulado en producción (sin clave en el binario) |
| AC-15 | Roles más allá del titular (RBAC) | C I | P | — | — | ⏳ con el dashboard |

## Datos y dinero

| ID | Control | CIA | Tipo | Implementación | Evidencia | Estado |
|---|---|---|---|---|---|---|
| DT-01 | Dinero en céntimos enteros (`BIGINT`, `Money`) | I | P | `db/models.py`; `core_kernel · Money` | `test_consistencia_ddl.py` | ✅ |
| DT-02 | Partida doble atómica (débito y crédito en la misma transacción) | I | P | `app/services/ledger.py` | `test_libro_mayor.py`, `test_motor_de_asientos.py` | ✅ |
| DT-03 | Saldo no negativo y monto positivo forzados por el motor (`CHECK`) | I | P | `db/models.py` → `schema.sql` | `test_consistencia_ddl.py` | ✅ |
| DT-04 | Bloqueo de fila (`FOR UPDATE`) contra doble gasto | I | P | `app/services/ledger.py` | `test_concurrencia_multicuenta.py`, `test_transferencias.py` (marca `postgres`, en CI contra Postgres 16) | ✅ |
| DT-05 | Idempotencia por `UNIQUE (idempotency_key)` | I | P | `db/models.py`, `ledger.py` | `test_transferencias.py`, `test_libro_mayor.py` | ✅ |
| DT-06 | DDL consistente con el modelo | I | D | `scripts/dump_schema.py` | `test_consistencia_ddl.py` | ✅ |
| DT-07 | Nombre del destinatario enmascarado | C | P | `routers/directory.py · enmascarar` | `test_directorio_y_frecuentes.py` | ✅ |
| DT-08 | Buscar por alias no revela el DNI | C | P | `routers/directory.py · resolver` | `test_directorio_y_frecuentes.py` | ✅ |
| DT-09 | Alias único y con al menos una letra | I | P | `app/services/alias.py`; app `AliasRules` | `test_alias.py`, `test_perfil.py` | ✅ |
| DT-10 | Tope de consultas de destinatario (20/10 min por usuario) | C D | P | `app/services/rate_limit.py` | `test_directorio_y_frecuentes.py` | ✅ |
| DT-11 | Correo enmascarado | C | P | `app/services/otp.py · mask_email` | `test_perfil.py` | ✅ |
| DT-12 | Del KYC se guarda el veredicto, nunca las imágenes | C | P | `db/models.py · kyc_verifications` | Revisión del modelo | ✅ |
| DT-13 | Nombre del dispositivo saneado a ASCII imprimible | I | P | app `core/env/device_name.dart`; `services/devices.py` | `test_nombre_de_dispositivo.py` | ✅ |

## Aplicación web y transporte

| ID | Control | CIA | Tipo | Implementación | Evidencia | Estado |
|---|---|---|---|---|---|---|
| WB-01 | Consultas parametrizadas (ORM): sin inyección SQL | I C | P | SQLAlchemy en todo `app/` | `test_seguridad_web.py` (cargas SQLi) | ✅ |
| WB-02 | Respuestas solo JSON con `nosniff` (XSS) | C | P | `app/main.py` | `test_seguridad_web.py` (cargas XSS) | ✅ |
| WB-03 | CORS cerrado (sin `Access-Control-Allow-Origin`) | C | P | `app/main.py` (sin middleware CORS) | `test_seguridad_web.py` | ✅ |
| WB-04 | HTTPS forzado (301) + HSTS | C | P | Render; `app/main.py` | `scripts/smoke_prod.sh` | ✅ |
| WB-05 | `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` | C | P | `app/main.py` | `test_seguridad_web.py` | ✅ |
| WB-06 | `Cache-Control: no-store` en `/v1` | C | P | `app/main.py` | `test_seguridad_web.py` | ✅ |
| WB-07 | Errores con `code` estable, sin trazas internas | C | P | `app/core/errors.py`, `app/main.py` | `test_seguridad_web.py` | ✅ |
| WB-08 | Conexión cifrada a la base (TLS) | C | P | `app/db/base.py` | Configuración de Neon | ✅ |
| WB-09 | Límite de peticiones por IP / WAF | D | P | Cloudflare delante de Render (sin reglas propias) | — | ⏳ |
| WB-10 | Dependencias sin vulnerabilidades conocidas (`pip-audit`, bloquea CI y CD) | C I D | P | `.github/actions/pruebas-backend` | Paso `pip-audit` del job *Backend (PostgreSQL 16)*. Encontró 7 avisos en starlette 0.38.6 (vía FastAPI 0.115); se subió a FastAPI 0.142.4 y starlette ≥ 1.3.1: 0 avisos | ✅ |
| WB-11 | Escaneo DAST con OWASP ZAP: activo sobre una copia efímera (con y sin sesión) y pasivo sobre producción | C I | D | `.github/workflows/seguridad.yml` (a mano y cada lunes) | Reportes HTML/JSON como artefactos del run | ⏳ |

## Operación y secretos

| ID | Control | CIA | Tipo | Implementación | Evidencia | Estado |
|---|---|---|---|---|---|---|
| OP-01 | Secretos fuera del repositorio | C | P | `render.yaml` (`sync: false`), `.gitignore` | Revisión del repositorio | ✅ |
| OP-02 | Reset del esquema con cerrojo contra producción | I D | P | `scripts/reset_schema.py` | `test_reset_schema.py` | ✅ |
| OP-03 | Health check de vida y de base | D | D | `app/main.py · /health, /health/db` | `test_seguridad_web.py`, `smoke_prod.sh` | ✅ |
| OP-04 | Integridad del libro auditable (débitos = créditos, saldo = asientos) | I | D | `scripts/monitoreo.sql` (6 y 7) | Ejecución en Neon | ✅ |
| OP-05 | Restauración a un punto en el tiempo (6 h) | D I | R | Neon [plataforma] | Consola de Neon | ✅ |
| OP-06 | Registro de intentos de ingreso y bloqueos | C | D | `login_attempts`, `lockouts` | `monitoreo.sql` (8) | ✅ |
| OP-07 | Hashes argon2 limitados (no agotar memoria) | D | P | `core/security.py · PIN_HASH_CONCURRENCY` | Revisión de código | ✅ |
| OP-08 | Pantallas sensibles sin captura | C | P | app `core/security/secure_screen*.dart`, usado en 9 pantallas (login, PIN, confirmación, depósito…) | Revisión de código; sin prueba automatizada | ✅ |
| OP-09 | Logs estructurados con correlación | C D | D | — | — | ⏳ |
| OP-10 | Migraciones versionadas | I D | P | — | — | ⏳ |

**Resumen**: 49 controles; 43 implementados (✅), 1 parcial (⚠️) y 5
pendientes (⏳). Los pendientes y parciales están detallados con su
mitigación en [`seguridad.md`](seguridad.md#7-riesgos-abiertos).
