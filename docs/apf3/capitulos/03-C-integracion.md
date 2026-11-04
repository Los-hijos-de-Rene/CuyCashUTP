# C. Pruebas de integración automatizadas  _(Jeremy #100, #101 · Andersson #103 · contrato: Jair C. #111)_

## C.1 Sistemas externos a integrar
| Sistema | Cómo se integra | Riesgo de interoperabilidad | Mitigación |
|---|---|---|---|
| Microservicio KYC (`CuyCashKYC`) | Proxy de `services/api` (`/v1/kyc/*`); la clave vive en el backend | Se duerme en plan gratuito; cambio de contrato; red | Reintento solo si la petición no llegó (502/503/504); clave rechazada → 503; lista blanca de rutas |
| PostgreSQL (Neon) | `asyncpg` + SQLAlchemy | Neon suspende el cómputo y cierra conexiones | `pool_pre_ping=True` |
| Render (hosting) | Docker, `$PORT`, `/health` | Arranque en frío | Despliegue solo por Actions; health check; rollback |
| Telegram (OTP de demostración) | `httpx`, timeout 10 s | Cae el servicio | Un fallo no tumba el flujo; reenvío |
| ML Kit / `local_auth` | Plugins de Flutter | Cambian con el sistema operativo | Detrás de interfaces con doble `Memory*` |
| GitHub Actions | Workflows | Cambio de versión de una acción | Acciones fijadas por versión mayor |

Fuente: `docs/compatibilidad-y-coexistencia.md` §1.

## C.2 Frameworks
`pytest` + `pytest-asyncio` + `httpx.MockTransport` (servicio externo simulado); PostgreSQL 16 real en CI; `flutter test` con los repositorios `Http*` reales contra la API levantada (contrato).

## C.3 Casos de prueba de interoperabilidad
- Proxy KYC: 9 casos existentes en `services/api/tests/test_proxy_kyc.py`.
- Contrato app ↔ API real: INT-CT-01..10 en `apps/mobile/contract_test/backend_contract_test.dart`.
- Telegram, KYC (timeouts, JSON inválido), base de datos y OpenAPI: PENDIENTE (Jeremy, `docs/apf3/spec-jeremy-integracion.md`).

## C.4 Capturas de ejecución · C.5 Reportes de resultados · C.6 Métricas y observaciones
PENDIENTE — capturas de `pytest -v` y del job *Contrato app ↔ API*; `junit.xml`; tabla de casos y % de cumplimiento; límites (el KYC real no corre en CI).

## C.7 Coexistencia de la API — Andersson #103

Implementación propuesta en [PR #121](https://github.com/Los-hijos-de-Rene/CuyCashUTP/pull/121),
pendiente de aprobación independiente e integración. No se desplegó.

| Caso | Resultado real en laboratorio |
|---|---|
| COEX-01 Construir imagen y comprobar identidad | Imagen Python3.12 construida; proceso `app`, UID/GID999 |
| COEX-02 Arranque API/PostgreSQL16 | `/health` y `/health/db` HTTP200 |
| COEX-03 Memoria acotada | Límite Docker536870912 bytes (512MiB); medición puntual en recursos.txt, sin certificación de carga máxima |
| COEX-04 Pool configurable y Neon | 4 pruebas: valores de pool/overflow/timeout, rechazo de rangos inválidos y normalización TLS de URL Neon; sin conexión directa a Neon |
| COEX-05 Apagado | `exec uvicorn` como proceso1; `docker stop` termina exit0, OOMKilled=false y registro de cierre completo |
| COEX-06 Regresión | CI del código a529dee:436 pruebas PostgreSQL aprobadas,96% cobertura y10 contratos app/API |

Evidencias publicadas: [construcción](https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/feat/103-coexistencia-contenedores/docs/apf3/evidencias/andersson/coexistencia/build.txt),
[identidad](https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/feat/103-coexistencia-contenedores/docs/apf3/evidencias/andersson/coexistencia/usuario.txt),
[recursos](https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/feat/103-coexistencia-contenedores/docs/apf3/evidencias/andersson/coexistencia/recursos.txt),
[apagado](https://github.com/Los-hijos-de-Rene/CuyCashUTP/blob/feat/103-coexistencia-contenedores/docs/apf3/evidencias/andersson/coexistencia/container-final-shutdown.txt)
y [CI](https://github.com/Los-hijos-de-Rene/CuyCashUTP/actions/runs/41757142389).
Procedimiento/configuración en `docs/compatibilidad-y-coexistencia.md` §7.
No se infiere funcionamiento Android ni producción a partir de estas pruebas.
Los servicios propios quedaron detenidos y los volúmenes se conservaron.
