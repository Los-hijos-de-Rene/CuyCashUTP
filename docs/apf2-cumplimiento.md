# APF2 · matriz de cumplimiento (criterios 1 a 3)

Verificación del repositorio frente a la *Guía y Rúbrica de Evaluación del
Avance de Proyecto Final 2* (`APF2.pdf`), criterios 1 a 3, al 2026-10-07. Cada
fila dice qué artefacto lo cubre, dónde está y qué evidencia falta capturar
para el PDF. Los criterios 4 a 6 no aplican a este avance.

Leyenda: ✅ cubierto en el repositorio · 📸 falta solo la captura para el PDF ·
⚠️ cubierto con una limitación declarada.

## Criterio 1 · Integración con base de datos (4 pts)

| # | Elemento exigido | Artefacto | Estado | Evidencia para el PDF |
|---|---|---|---|---|
| 1.1 | Informe de Administración y Replicación | [`administracion-bd.md`](administracion-bd.md) §1–4 | ✅ 📸 | Consola de Neon: *Branches* (ventana de restauración) y *Monitoring* |
| 1.2 | Diseño físico (diagrama relacional final) | [`modelo-datos.md`](modelo-datos.md) (diagrama ER en Mermaid, tablas implementadas y diseñadas) | ✅ | Render del diagrama (GitHub lo dibuja) |
| 1.3 | Patrón de acceso a datos, justificación ORM/SQL | [`modelo-datos.md`](modelo-datos.md#patrón-de-acceso-a-datos): ORM SQLAlchemy 2.0 en el backend y Repository con `Memory*`/`Http*` en la app | ✅ | Fragmento de `services/api/app/services/ledger.py` y de un `*_repository.dart` |
| 1.4 | Consistencia entre el modelo y el DDL | `services/api/schema.sql`, generado por `scripts/dump_schema.py`; **`tests/test_consistencia_ddl.py`** falla si divergen | ✅ | Salida de `pytest tests/test_consistencia_ddl.py` (4 passed) |

## Criterio 2 · Medidas de seguridad (4 pts)

| # | Artefacto exigido | Artefacto | Estado | Evidencia para el PDF |
|---|---|---|---|---|
| 2.1 | Módulo de autenticación y autorización funcional | [`seguridad.md`](seguridad.md#2-módulo-de-autenticación-y-autorización-21); código en `routers/auth.py`, `core/deps.py`; `test_sesion_requerida.py` recorre todas las rutas | ✅ 📸 | Capturas del login, OTP de dispositivo nuevo, bloqueo al 3.er intento y acceso con huella |
| 2.2 | Informe técnico de seguridad y cifrado | [`seguridad.md`](seguridad.md) §1, 3–6: argon2id, SHA‑256 de tokens, TLS app↔API y API↔BD, almacén cifrado del teléfono | ✅ | Fragmento de `app/core/security.py` |
| 2.3 | Pruebas de seguridad web (CORS, XSS, SQLi) | [`plan-de-pruebas.md`](plan-de-pruebas.md#4-pruebas-de-seguridad-web); **`tests/test_seguridad_web.py`** (33 pruebas) | ✅ | Salida de `pytest tests/test_seguridad_web.py -v` |
| 2.4 | Catálogo de controles | [`catalogo-controles.md`](catalogo-controles.md): 47 controles con pilar CIA, tipo, código y prueba | ✅ | La tabla misma |

## Criterio 3 · Despliegue de la aplicación (4 pts)

| # | Artefacto exigido | Artefacto | Estado | Evidencia para el PDF |
|---|---|---|---|---|
| 3.1 | Plan de pruebas | [`plan-de-pruebas.md`](plan-de-pruebas.md): niveles, cobertura por módulo, entornos, criterios de entrada/salida y lo no probado | ✅ | — |
| 3.2 | Manual de despliegue (paso a paso, arquitectura cloud) | [`despliegue.md`](despliegue.md) §1–7: Render + Neon, **pipeline CI/CD en GitHub Actions** con aprobación, **rollback** y guion de la demostración; `render.yaml`, `Dockerfile`, `.github/workflows/` | ✅ 📸 | Pestaña *Actions* con un despliegue y un rollback en verde; environment `production` esperando aprobación |
| 3.3 | Evidencia de pruebas de despliegue | [`despliegue.md`](despliegue.md#8-evidencia-de-pruebas-de-despliegue); **`scripts/smoke_prod.sh`** | ✅ 📸 | Corrida del 2026-10-07 con el avance desplegado: **0 fallos**. Faltan las capturas listadas y la del job de CD |
| 3.4 | Monitoreo y administración de la BD en producción | [`administracion-bd.md`](administracion-bd.md#5-monitoreo-en-producción-criterio-34); **`/health/db`**; **`scripts/monitoreo.sql`** | ✅ 📸 | Neon *Monitoring* + consultas 1, 2, 6 y 7 ejecutadas en la consola SQL |

## Qué se agregó en este avance para cerrar huecos

| Hueco detectado | Cierre |
|---|---|
| No había prueba de que `schema.sql` coincide con los modelos | `tests/test_consistencia_ddl.py` |
| No había pruebas de SQLi, XSS ni CORS | `tests/test_seguridad_web.py` |
| La prueba de "rutas con sesión" usaba una ruta sonda, no las reales | `test_toda_ruta_privada_exige_sesion` recorre todas las `/v1` |
| Sin HSTS ni cabeceras de seguridad en producción | Middleware en `app/main.py` |
| Sin forma de monitorear la base desde fuera | `GET /health/db` y `scripts/monitoreo.sql` |
| Sin prueba de humo del despliegue | `scripts/smoke_prod.sh` |
| **500 intermitente en producción** tras el reposo de Neon | `pool_pre_ping=True` en `app/db/base.py` (confirmar tras desplegar) |
| La suite del backend solo corría sobre SQLite; las 3 de concurrencia nunca contra Postgres | **Toda** la suite (305) corre en CI contra PostgreSQL 16. Encontró un 500 real: un DNI o `X-Device-Id` más largo que su columna; corregido con validación de entrada |
| Informes de administración, seguridad, catálogo, plan de pruebas y despliegue inexistentes o dispersos | Los cinco documentos de esta carpeta |

## Pendientes antes de entregar

1. Fusionar el PR del pipeline y aprobar el primer *CD backend* en *Actions*.
2. Tomar las capturas marcadas con 📸 (las listas están al final de
   `administracion-bd.md` y `despliegue.md`).
3. Limitaciones que conviene **decir** en la sustentación, no esconder:
   rendimiento bajo carga sin medir, verificación E2E
   en emulador sin ejecutar, KYC simulado en producción, migraciones pendientes.
