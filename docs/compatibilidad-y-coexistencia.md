# Compatibilidad y coexistencia (ISO/IEC 25010)

**Sesiones 21 y 22 · Curso Integrador II.** Auditoría de CuyCash frente a lo
que piden las diapositivas: **interoperabilidad** (¿se entiende bien con otros
sistemas?, sesión 21) y **coexistencia** (¿convive sin estorbar?, sesión 22).
Incluye los tres talleres, una prueba real de dos instancias y lo que falta.

Corte: 2026-10-30, rama `feat/idoneidad-funcional-iso25010`. Es una auditoría:
**no se cambió código ni infraestructura**; las correcciones están en §6.

Método igual que [`idoneidad-funcional.md`](idoneidad-funcional.md): ✅ cumple
(existe y hay evidencia), 🟡 parcial, ❌ no cumple o no se mide. «N/A» = no
aplica a este producto.

---

## 1. Taller de la sesión 21: sistemas externos, riesgo y mitigación

| Sistema externo | Cómo se integra | Riesgo de interoperabilidad | Mitigación hoy | Falta |
|---|---|---|---|---|
| **Microservicio KYC** (`CuyCashKYC`, repo aparte) | La app habla solo con el proxy de `services/api` (`/v1/kyc/*`); la clave vive en el backend | En el plan gratuito se duerme (~1 min en despertar); cambiaría su contrato; falla de red | Reintento solo si la petición **no llegó** (502/503/504, conexión rechazada) hasta 60 s; un timeout de lectura no se reintenta; clave rechazada → 503; allowlist de rutas. Pruebas con un servicio simulado: `api/test_proxy_kyc.py` | Sin prueba contra el KYC real en CI; el contrato (ADR 0001) no tiene versión ni prueba de compatibilidad |
| **PostgreSQL en Neon** | `asyncpg` + SQLAlchemy | Neon suspende el cómputo a los 5 min y cierra conexiones | `pool_pre_ping=True` (corregido tras un 500 real, 2026-10-07; `despliegue.md`) | Pool sin ajustar (§3) |
| **Render** (hosting) | Docker + `$PORT` + `/health` | Cold start; autodeploy apagado | Despliegue solo por GitHub Actions; health check; rollback | Sin medición de disponibilidad |
| **Telegram** (OTP de demostración) | `httpx`, timeout 10 s | Cae el servicio y no llega el código | Si falla se registra y **no tumba el flujo**; el usuario puede pedir reenvío | Solo demo; no es canal de producción |
| **ML Kit / `local_auth`** (teléfono) | Plugins de Flutter | Cambian con el sistema operativo; sin probar en teléfono real | Detrás de interfaces con doble `Memory*` | Diálogo real de huella y orientación de fotogramas sin probar |
| **GitHub Actions** (CI/CD) | Workflows | Cambio de versión de una acción | Acciones fijadas por versión mayor | — |

Sistemas legados, pasarelas de pago e interbancarias: **no existen todavía**
(CCI/CCE llega con HU06 CA2), así que no hay adaptadores ni middleware que
evaluar.

## 2. Auditoría de interoperabilidad (sesión 21)

| # | Lo que pide la clase | Veredicto | Evidencia / brecha |
|---|---|---|---|
| 1 | Lista de sistemas externos con riesgo y plan | ✅ | §1 de este documento |
| 2 | Protocolos estándar (HTTP/HTTPS, REST) | ✅ | REST sobre HTTPS; HSTS y redirección 301 (`seguridad.md` §5) |
| 3 | Formatos estándar (JSON) | ✅ | Todo el contrato es JSON; errores con `code` estable |
| 4 | Documentación OpenAPI/Swagger | ✅ | FastAPI genera OpenAPI **3.1**: 36 rutas y 38 operaciones en local (incluye las de desarrollo), 19 esquemas, todas con respuesta 2xx documentada |
| 5 | Versionamiento (v1, v2) | 🟡 | Todas las rutas de negocio cuelgan de `/v1`. Pero `info.version` está fija en `0.1.0`, no hay política de cambios ni de retiro, y no existe `/v2` |
| 6 | Estabilidad de contratos / pruebas de contrato | 🟡 | Contrato de repositorios `Memory*` ↔ `Http*` en la app (27 archivos) y proxy KYC con servicio simulado. **No hay** una prueba que compare lo que espera la app con lo que responde el backend real, ni un `openapi.json` versionado que detecte un cambio accidental. `verificacion-manual.md` lo reconoce: es «la brecha que ningún test cubre» |
| 7 | Mocks y stubs de integración | ✅ | `Memory*` en la app; `upstream` simulado del KYC en el backend |
| 8 | Pruebas de caja negra con servicios externos | 🟡 | `docker compose --profile kyc` levanta el KYC real en local, pero no corre en CI y no hay registro de haberlo ejecutado de punta a punta |
| 9 | Reintentos y timeouts | 🟡 | Timeouts definidos en todos los clientes (app: 20 s conexión / 70 s lectura, KYC 120 s; backend: KYC 120 s, Telegram 10 s). Reintento **solo** para el despertar del KYC; no encontré reintento general en la app |
| 10 | Manejo robusto de errores de red | ✅ | «Ningún `throw` cruza la capa»: red caída y timeout son `GlobalFailure` (`security_failure.dart`); el cambio de PIN trata el resultado desconocido aparte |
| 11 | Métrica: tasa de fallos de comunicación | ❌ | No se mide. Riesgo abierto n.º 4 de `seguridad.md`: logs sin estructura ni correlación |
| 12 | Métrica: estándares implementados | ✅ | HTTPS/TLS, REST, JSON, OpenAPI 3.1, HSTS, RFC de cabeceras de seguridad |
| — | Desacoplar con *message brokers* | N/A | Operaciones síncronas e idempotentes; un broker sería prematuro |

**Resumen sesión 21:** 6 ✅ · 4 🟡 · 1 ❌ (de 11, sin contar N/A).

## 3. Taller de la sesión 22 y auditoría de coexistencia

Las tres preguntas del taller:

**1. ¿Qué librerías externas podrían generar conflicto?** Todas están fijadas en
`requirements.txt` salvo `starlette>=1.3.1`, que es un **piso** deliberado (deja
fuera versiones con avisos de seguridad). No hay archivo de bloqueo con
*hashes*: una instalación nueva podría traer una `starlette` posterior.
`pip-audit` en CI y CD vigila los avisos. El runtime es el mismo en la imagen y
en CI (Python 3.10); el entorno local de desarrollo usa 3.9.

**2. ¿Cómo aseguran que no agote la memoria del servidor?**
- Tope de 2 hashes argon2 simultáneos (`PIN_HASH_CONCURRENCY`), pensado para los 512 MiB del plan gratuito.
- Topes de negocio (consultas por usuario, intentos por DNI y dispositivo).
- Sin archivos temporales: los cuerpos del KYC pasan por memoria y se descartan.
- Faltan: tope de memoria del contenedor de la API en `docker-compose.yml` (solo el KYC lo tiene, 512 MB) y el ajuste del pool de conexiones, hoy por defecto (5 + 10 de desborde por proceso).

**3. ¿Es posible desplegar dos instancias en el mismo host?** Sí, con matices.
Ver la prueba de §4.

| # | Lo que pide la clase | Veredicto | Evidencia / brecha |
|---|---|---|---|
| 1 | Empaquetar con contenedor | ✅ | `services/api/Dockerfile` (`python:3.10-slim`) y `docker-compose.yml` |
| 2 | Mismo entorno en dev y producción | 🟡 | Imagen y CI en Python 3.10, y CI corre la suite contra PostgreSQL 16 como producción. Local usa 3.9 y SQLite (`CLAUDE.md` lo declara) |
| 3 | No ejecutar como root | ❌ | El `Dockerfile` no declara `USER`: el proceso corre como root dentro del contenedor |
| 4 | Límites de recursos | 🟡 | KYC con `mem_limit: 512m`; la API no tiene tope en compose (en Render lo da el plan) |
| 5 | Pool de conexiones | 🟡 | Existe, con valores por defecto y `pool_pre_ping`; sin ajustar al límite de conexiones de Neon ni al número de instancias |
| 6 | Configuración externa | ✅ | Todo por variables de entorno; los secretos fuera del repositorio |
| 7 | Sin rutas fijas ni archivos temporales | ✅ | No hay `open(`, `tempfile` ni rutas absolutas en `app/` |
| 8 | Dependencias con gestor y versiones | ✅ | `requirements.txt` fijado, `pip-audit` en CI/CD; ver el piso de `starlette` |
| 9 | Puerto configurable | ✅ | `${PORT:-8001}` en el `Dockerfile`; en compose el 8001 es fijo |
| 10 | Dos instancias en el mismo host | 🟡 | Funciona, con dos hallazgos (§4) |
| 11 | Topes a procesos costosos | ✅ | Argon2 limitado a 2 simultáneos |
| 12 | Métricas de «buen vecino» (memoria a 24 h, latencia vecina, caídas) | ❌ | No se miden. Solo la medición breve de §4 |
| — | Multi-tenancy y autoescalado | N/A | Producto de un solo cliente; el plan gratuito de Render no escala |

**Resumen sesión 22:** 6 ✅ · 4 🟡 · 2 ❌ (de 12, sin contar N/A).

## 4. Prueba realizada: dos instancias en el mismo equipo

Se levantaron dos procesos `uvicorn` de la API (puertos 8101 y 8102) sobre el
**mismo** archivo SQLite, y se les enviaron 400 + 400 peticiones a `/health` y
`/v1/accounts` cada una.

| Observación | Resultado |
|---|---|
| Ambas responden `/health` | Sí, 200 y en ~1 ms |
| Memoria residente al arrancar | ~64–70 MB cada una |
| Memoria tras 800 peticiones por instancia | Sin crecimiento (~35–60 MB) |
| **Arranque simultáneo sobre base vacía** | **Una falló**: `table users already exists`. Ambas ejecutan `create_all` a la vez (`lifespan` en `app/main.py`). Arrancando una tras otra, ambas funcionan |

Lecturas honestas:
- La falla es del **primer arranque con la base vacía**; con el esquema ya creado no ocurre. Es la consecuencia práctica de «esquema sin migraciones» (riesgo n.º 5 de `seguridad.md`).
- **No es una prueba de fugas de memoria**: 800 peticiones no equivalen a las 24 h de la clase, y la memoria residente en macOS fluctúa. Es un punto de partida.
- Con dos instancias, los **topes en memoria del proceso** (consultas de destinatarios, vales de ingreso) no se comparten: el tope real se multiplica. Está declarado como riesgo n.º 3 en `seguridad.md`.
- No se probó Docker (no está instalado en esta máquina): lo del contenedor viene de leer el `Dockerfile`.

## 5. Resumen

| Sesión | ✅ | 🟡 | ❌ | Total |
|---|---|---|---|---|
| 21 · Interoperabilidad | 6 | 4 | 1 | 11 |
| 22 · Coexistencia | 6 | 4 | 2 | 12 |
| **Total** | **12** | **8** | **3** | **23** |

Cumple 12 de 23 (0.52); contando parciales como ½, 0.70. La lista de 23 puntos
sale de las diapositivas y de los talleres: **no es una métrica oficial** de la
norma, es una lista de verificación propia. Lo construido es sólido donde se
pidió estándar y aislamiento; lo que falta es **medir** (fallos, memoria,
contrato) y endurecer el contenedor.

## 6. Qué falta para llegar a lo que piden las clases (por costo/beneficio)

| # | Acción | Cierra | Esfuerzo |
|---|---|---|---|
| 1 | Añadir `USER` sin privilegios al `Dockerfile` y un `.dockerignore` (hoy no existe) | S22 #3 | Bajo; **probar la imagen antes de desplegar** |
| 2 | Guardar `openapi.json` en el repo y una prueba que falle si cambia sin querer | S21 #6 | Bajo |
| 3 | Prueba de contrato app ↔ backend (respuestas reales contra los `Http*`) | S21 #6, #8 | Medio |
| 4 | `mem_limit` a la API en compose y ajustar `pool_size`/`max_overflow` al límite de Neon × instancias | S22 #4, #5 | Bajo |
| 5 | Logs JSON con ID de correlación y contador de errores por integración | S21 #11 | Medio |
| 6 | Quitar el `create_all` del arranque (migraciones con Alembic) | Arranque simultáneo, §4 | Medio |
| 7 | Medir memoria y latencia durante 24 h en el despliegue | S22 #12 | Bajo, pero lleva tiempo |
| 8 | Fijar versión de contrato (`info.version`) y política de retiro de `/v1` | S21 #5 | Bajo |

Las acciones 1, 2, 4 y 8 son de esfuerzo bajo, no tocan la lógica de negocio y
mejoran cinco filas de las tablas de arriba (S22 #3, #4, #5 y S21 #5, #6, esta
última solo en parte).

## 7. Correcciones de #103 (2026-11-04 UTC; pendientes de revisión)

La imagen usa Python 3.12 y `USER app` (UID 999 verificado en la construcción
local). `.dockerignore` excluye entornos, bases locales, secretos `.env`, pruebas
y reportes del contexto. Compose limita `auth` a 512 MiB. No se desplegó.

El pool PostgreSQL toma `DB_POOL_SIZE=2`, `DB_MAX_OVERFLOW=2` y
`DB_POOL_TIMEOUT=30` por defecto; valores inválidos detienen el arranque.
SQLite no recibe opciones de QueuePool. Se conserva `pool_pre_ping` y la
normalización TLS de URLs Neon. Máximo por proceso: size + overflow; multiplicar
por procesos e instancias y reservar conexiones de administración antes de
ajustar al límite del plan. No se afirma haber conectado a Neon desde el laboratorio.

Validación local reproducible: `scripts/validate_local.sh`, después de iniciar
Compose con nombre aislado y definir `TEST_POSTGRES_URL` (base desechable
terminada en `_test`). Usa `CUYCASH_PYTHON` para un venv fuera de este checkout.
Ejecuta verificaciones en secuencia; sale 3 si falta Flutter, sin declarar esa
prueba aprobada. No arranca ni detiene servicios ajenos. Para el arranque desde
PR #95 aplicar Alembic según `migraciones.md`; esta rama parte de `main`, que
actualmente conserva `create_all`.

Evidencia: `apf3/evidencias/andersson/coexistencia/`. Las auditorías históricas de
§1–§6 conservan su fecha y no representan el estado de esta propuesta.


El apagado del contenedor inicial terminaba forzado (137): el shell del CMD
no reenviaba SIGTERM. El CMD final usa `exec uvicorn`, verificado como proceso1,
y `docker stop` termina con **exit0**, `OOMKilled=false`, registrando cierre
completo de Uvicorn. Se reconstruyó la imagen y se repitieron health/db200
contra PostgreSQL16; ver `container-final-shutdown.txt` y `container-final-log.txt`.
No se borraron las bases ni los volúmenes y todos los servicios propios quedaron
detenidos después del ensayo.

El capítulo C.7 de APF3 enlaza las evidencias verificables y se exportó con el
generador existente a `APF3-coexistencia.pdf` (borrador, no PDF oficial de #106).
Los pendientes de otros responsables se conservan; la validación de nube y su
capítulo E están en PR #122. La aprobación e integración de ambos siguen siendo
externas a esta implementación.
