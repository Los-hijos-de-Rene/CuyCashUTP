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
