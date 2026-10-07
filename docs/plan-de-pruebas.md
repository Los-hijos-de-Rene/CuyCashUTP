# Plan de pruebas del sistema

**APF2 · criterio 3.1.** Qué se prueba, con qué, en qué entorno y con qué
criterio se da por bueno. Incluye las pruebas de seguridad web (criterio 2.3)
y las de despliegue (criterio 3.3).

Estado al 2026-10-07: **1 178 pruebas automatizadas en verde** (305 del
backend, 838 de la app, 23 de `core_kernel`, 12 de `design_system`) y 2
omitidas a propósito (los frecuentes ocultos, §7).

---

## 1. Objetivo y alcance

Verificar que lo implementado (identidad y accesos, cuentas, libro mayor,
envíos, depósito simulado, perfil) cumple su historia de usuario, sus reglas de
negocio, los SLA de `docs/sla-kpi.md` que se pueden medir y los controles de
`docs/catalogo-controles.md`.

**Fuera de alcance**: lo que aún no existe (interbancarias, QR, préstamos,
antifraude, conciliación) y el dashboard web.

## 2. Niveles de prueba

| Nivel | Qué valida | Herramienta | Dónde | Cantidad |
|---|---|---|---|---|
| **Unitarias** | Reglas puras: dinero, PIN, alias, fechas, formateo | `flutter test`, `pytest` | `packages/*/test`, `apps/mobile/test/core`, `services/api/tests/test_alias.py` | 35 (paquetes) + parte de la app |
| **Contrato de repositorios** | Que el `Memory*` (demo) y el `Http*` (real) se comportan IGUAL ante la misma batería | `flutter test` | `apps/mobile/test/feature/*/…_contract.dart` | 27 archivos |
| **Bloc / estado** | Flujos de pantalla sin UI: carga, errores, paginación, carreras | `bloc_test` | `apps/mobile/test/presentation/**/bloc*` | Incluido en 838 |
| **Widgets** | Pantallas: qué se ve, qué se habilita, a dónde navega | `flutter_test` | `apps/mobile/test/presentation` | 54 archivos |
| **Flujo por el router real** | Recorridos completos con el grafo `mock` (ingresar, enviar, depositar, abrir cuenta) | `flutter_test` + `createAppRouter` | `…/send_flow_test.dart`, `topup_flow_test.dart`, `open_account_flow_test.dart` | 4 archivos |
| **API (integración)** | Cada endpoint por HTTP contra una base real: **PostgreSQL 16 en el CI** (el motor de producción), SQLite en memoria en local | `pytest` + `httpx` | `services/api/tests` | 305 |
| **Base de datos** | Consistencia DDL ↔ modelo, restricciones del motor, partida doble | `pytest` | `test_consistencia_ddl.py`, `test_libro_mayor.py`, `test_motor_de_asientos.py` | 29 |
| **Seguridad web** | SQLi, XSS, CORS, cabeceras, fuga de errores, rutas sin sesión | `pytest` | `test_seguridad_web.py`, `test_sesion_requerida.py` | 43 |
| **Concurrencia** | Bloqueo de fila e idempotencia con peticiones simultáneas | `pytest -m postgres` contra Postgres 16 en GitHub Actions | `test_concurrencia_multicuenta.py`, `test_transferencias.py` | 3 (corren en el job *Backend (PostgreSQL 16)* del workflow *CI*) |
| **Despliegue (humo)** | Que producción responde, cifra y protege | `scripts/smoke_prod.sh` | Contra Render | 9 verificaciones |
| **Manual E2E** | La app real contra el backend en un emulador | Guion | `docs/verificacion-manual.md` | ⚠️ sin ejecutar (§7) |

## 3. Cobertura por módulo del backend

| Módulo | Archivo(s) | Pruebas |
|---|---|---|
| Registro, ingreso, bloqueo | `test_registro_y_login.py`, `test_bloqueo_por_dispositivo.py` | 15 |
| OTP y recuperación de PIN | `test_otp_y_recuperacion.py` | 10 |
| Cambio de PIN, biometría, dispositivos | `test_cambio_de_pin.py`, `test_biometria.py`, `test_dispositivos.py`, `test_nombre_de_dispositivo.py` | 29 |
| Perfil y alias | `test_perfil.py`, `test_alias.py`, `test_nombre_del_titular.py` | 27 |
| Cuentas (abrir, renombrar, multicuenta) | `test_apertura_de_cuenta.py`, `test_abrir_y_renombrar_cuenta.py`, `test_modelo_multicuenta.py` | 30 |
| Libro mayor | `test_libro_mayor.py`, `test_motor_de_asientos.py` | 25 |
| Movimientos (por cuenta y combinados) | `test_cuentas_y_movimientos.py`, `test_movimientos_combinados.py` | 30 |
| Envíos y depósito | `test_transferencias.py`, `test_envio_por_cuenta.py` | 44 |
| Directorio y frecuentes | `test_directorio_y_frecuentes.py` | 44 |
| Seguridad transversal | `test_seguridad_web.py`, `test_sesion_requerida.py` | 43 |
| Base de datos y operación | `test_consistencia_ddl.py`, `test_reset_schema.py` | 7 |

**Cobertura de líneas** (`pytest --cov`, la imprime el job *Backend (PostgreSQL
16)* al final de su log): **96 %** del backend (1588 sentencias, 62 sin
ejecutar), medida el 07/10/2026 en macOS sobre SQLite. Módulos críticos:
`services/ledger.py` 99 %, `core/security.py` 98 %, `services/lockout.py` 97 %,
`services/otp.py` 96 %, `routers/auth.py` 94 %. Hace falta
`concurrency = greenlet` (`.coveragerc`): sin ella coverage no sigue el código
que corre dentro de SQLAlchemy async y reporta ~72 %.

## 4. Pruebas de seguridad web

Criterio 2.3. `services/api/tests/test_seguridad_web.py` ataca la API por HTTP.
Para cada caso exige que el ataque **no tenga efecto** y que la respuesta sea un
error controlado, nunca un 500.

| Ataque | Casos | Resultado esperado y obtenido |
|---|---|---|
| **SQLi** en el login (`' OR '1'='1`, `'; DROP TABLE users; --`, `pg_sleep`…) | 5 cargas | 401/422, sin `session_token` |
| **SQLi** en la búsqueda por DNI y por alias | 5 × 2 | 404/422, sin datos de nadie |
| **SQLi** en ids de la ruta (`/v1/movements/{id}`, `/v1/accounts/{id}/movements`) | 5 × 2 | 404 |
| **SQLi** en el cursor de paginación | 5 | Se trata como cursor inválido: primera página |
| **SQLi** guardada como dato (nombre de cuenta `'); DROP TABLE users;--`) | 1 | Se guarda literal; la tabla `users` sigue ahí |
| **XSS** en el alias (`<script>…`) | 1 | 422 `INVALID_ALIAS` |
| **XSS** en nombre de cuenta y apodo de frecuente | 2 | Se devuelve como dato JSON, `Content-Type: application/json` + `nosniff` |
| **CORS** desde `https://atacante.example` (preflight y GET con sesión) | 2 | Sin `Access-Control-Allow-Origin` ni `…-Credentials` |
| **Cabeceras** HSTS, `nosniff`, `X-Frame-Options`, `Referrer-Policy` | 3 rutas | Presentes en toda respuesta |
| **Caché** de datos privados | 1 | `Cache-Control: no-store` en `/v1` |
| **Fuga de detalles** en errores | 1 | Sin `traceback`, `sqlalchemy`, SQL ni motor |
| **Rutas sin sesión** (`test_sesion_requerida.py`) | todas las `/v1` | 401 salvo las 10 públicas declaradas |
| **Entradas más largas que su columna** (DNI de 50 dígitos, `X-Device-Id` de 500, identificador de OTP de 1000) | 3 | 422 en la entrada. Antes daban **500 en Postgres** (SQLite no hace cumplir el largo de `VARCHAR`): lo encontró el CI |

Ejecutar solo estas: `cd services/api && .venv/bin/python -m pytest -q tests/test_seguridad_web.py tests/test_sesion_requerida.py`.

Además de la suite, dos verificaciones automáticas fuera de pytest:

| Verificación | Dónde corre | Qué hace |
|---|---|---|
| **`pip-audit`** sobre `requirements.txt` | CI y CD (`.github/actions/pruebas-backend`), en cada cambio del backend | Falla si una dependencia de producción tiene un aviso publicado. El primer run encontró 7 en starlette 0.38.6; FastAPI 0.142.4 los cierra |
| **OWASP ZAP activo** (`zap-api-scan`) | `.github/workflows/seguridad.yml`, a mano y cada lunes | Ataca cada ruta del OpenAPI, con y sin sesión, en una copia efímera del backend (SQLite). Nunca contra producción |
| **OWASP ZAP pasivo** (`zap-baseline`) | El mismo workflow | Lee las respuestas de producción: cabeceras, TLS, filtraciones. No escribe |

## 5. Pruebas de despliegue

`services/api/scripts/smoke_prod.sh` es **solo lectura** (no registra ni mueve
dinero) y se puede correr contra producción cuando haga falta:

| # | Verificación | Esperado |
|---|---|---|
| 1 | `GET /health` | 200 |
| 2 | `GET /health/db` | `"status":"ok"`, `"database":"postgresql"` |
| 3 | `http://` → `https://` | 301 |
| 4 | `/v1/me` sin token | 401 |
| 5 | Token inventado | 401 |
| 6–8 | Cabeceras HSTS, `nosniff`, `X-Frame-Options` | Presentes |
| 9 | CORS | Ausente |

Resultado más reciente en [`despliegue.md`](despliegue.md#8-evidencia-de-pruebas-de-despliegue).

## 6. Entornos y datos

| Entorno | App | API | Base | Uso |
|---|---|---|---|---|
| Local / CI | flavor `mock` (repos en memoria) | — | — | Suite de la app |
| Local | — | `pytest` | SQLite en memoria, una base nueva por prueba | Suite del backend (rápida, sin Docker) |
| CI | — | `pytest` | PostgreSQL 16 de servicio, esquema recreado por prueba | La misma suite, con el motor de producción |
| Local integrado | flavor `local` | uvicorn :8001 | SQLite en archivo | Guion manual |
| Concurrencia | — | `pytest -m postgres` | Postgres cuyo nombre termina en `_test` | Bloqueo de fila |
| Producción | flavor `production` | Render | Neon | Humo y demostración |

**Datos de prueba**: los fixtures `registrado` (DNI `71234567`) y
`otro_registrado` (`45678912`) del backend; en la app, el titular de demo con
3 cuentas (PIN `000000`). Ninguna prueba usa datos personales reales.

## 7. Lo que NO está probado (riesgo conocido)

| Qué | Por qué | Cómo cerrarlo |
|---|---|---|
| Recorrido E2E app ↔ backend en emulador | `docs/verificacion-manual.md` nunca se ejecutó | Ejecutar el guion y anotar el resultado |
| Diálogo real de `local_auth` en un teléfono | Los tests usan `MemoryBiometricGate` | Prueba manual en un dispositivo |
| SLA de 200 ms por operación y 1.5 s de autenticación | Sin medición automatizada | Medir con carga en el despliegue |
| 2 pruebas de frecuentes | Ocultos con `FeatureToggles.frecuentesEnEnvio`; vuelven solas al encenderlo | — |

## 8. Criterios de entrada y salida

**Entrada a un merge**: `flutter analyze` sin issues, `flutter test` y
`pytest` en verde, `schema.sql` regenerado si cambió un modelo (lo exige
`test_consistencia_ddl.py`). Lo verifica **en cada PR** el workflow *CI* de GitHub Actions; la regla de
`main` exige su check *CI listo*.

**Salida a producción**: el workflow *CD backend* vuelve a correr el CI, pide
aprobación, despliega el commit probado y corre `scripts/smoke_prod.sh`; si el
humo falla, la ejecución queda en rojo y se aplica el rollback
(`despliegue.md` §5).

## 9. Cómo ejecutar

```sh
# App y paquetes (en la raíz del repo)
flutter analyze
(cd apps/mobile && flutter test)
(cd packages/core_kernel && flutter test)
(cd packages/design_system && flutter test)

# Backend
cd services/api && .venv/bin/python -m pytest -q

# Concurrencia (exige Postgres; la base DEBE terminar en _test)
TEST_POSTGRES_URL="postgresql+asyncpg://user:pass@host/cuycash_test" \
  .venv/bin/python -m pytest -m postgres -q

# Despliegue
services/api/scripts/smoke_prod.sh https://cuycashutp.onrender.com
```
