# Spec · Jeremy · Pruebas de integración (capítulo C)

Tarjetas **#100** (P0, M) y **#101** (P1, S) · Revisor: Andersson · Criterio 2
(4 pts) y parte del 5.

## Qué se te pide
Demostrar con pruebas automatizadas que CuyCash **interopera y coexiste** con
sus sistemas externos aun cuando estos fallan. El docente exige 6 artefactos:

| # | Artefacto | Qué entregas |
|---|---|---|
| 1 | Sistemas externos | Tabla de [`compatibilidad-y-coexistencia.md`](../compatibilidad-y-coexistencia.md) §1 (KYC, Neon, Render, Telegram, ML Kit/`local_auth`, GitHub Actions), con el protocolo de cada uno |
| 2 | Frameworks | `pytest` + `pytest-asyncio` + `httpx.MockTransport` (servicio externo simulado) + PostgreSQL 18 real en CI. Justifica: determinista, sin red, sin gastar el KYC gratuito |
| 3 | Casos de prueba | Tabla (plantilla del [README](README.md)) con ≥ 20 casos |
| 4 | Capturas | Terminal de `pytest -v` de los archivos de integración |
| 5 | Reportes | `--junitxml` en `evidencias/jeremy/` |
| 6 | Métricas | Casos, % aprobado, cobertura de `app/services/kyc*`, `notifier.py`, `db/base.py` |

## Lo que ya existe (no lo repitas, cítalo)
`tests/test_proxy_kyc.py`: 9 pruebas del proxy KYC (sin configurar → 503; la clave
la pone el servidor; 4xx de negocio pasan tal cual; clave rechazada → 503; rutas
no permitidas no se exponen; reintento si el KYC despierta; mismo cuerpo en el
reintento; si no despierta → 503).

## Lo que falta (tu aporte)

### 1. Telegram / notificador OTP — hoy **sin pruebas** (`app/services/notifier.py`)
Archivo nuevo `tests/test_integracion_notificador.py`:
| Caso | Esperado |
|---|---|
| INT-T1 Telegram responde 200 | Se hizo **un** POST a `api.telegram.org/bot…/sendMessage` con `chat_id` y el código en el texto |
| INT-T2 Telegram da timeout / `ConnectError` | `send()` **no lanza**; se registra el error; el flujo de OTP sigue |
| INT-T3 Telegram da 500 | No lanza |
| INT-T4 `OTP_NOTIFIER=telegram` sin token o sin `chat_id` | `build_notifier()` devuelve `LogNotifier` |
| INT-T5 El log de error **no contiene el token del bot** | `caplog.text` no incluye el token (¡podría filtrarse en la URL! si falla, es un hallazgo de seguridad: corrígelo) |
| INT-T6 `LogNotifier` guarda el OTP solo con `/v1/dev` habilitado | Con dev desactivado, nada se registra |

Patrón: copia el `upstream`/`MockTransport` de `test_proxy_kyc.py`.

### 2. KYC — casos que faltan
| Caso | Esperado |
|---|---|
| INT-K1 `ReadTimeout` del KYC | **No** se reintenta (podría haber procesado); responde error claro |
| INT-K2 `verify-full` con `kyc_ticket` | El ticket nace solo si aprueba TODO (incluido cotejo del DNI) |
| INT-K3 Respuesta del KYC con JSON inválido | La API responde 502/503 limpio, sin traza |
| INT-K4 Contrato: forma de `challenge` (`token`, `steps`, `expires_in`) | Si el KYC cambia el campo, la prueba falla |

### 3. Base de datos (Neon/PostgreSQL)
| Caso | Esperado |
|---|---|
| INT-D1 `/health/db` con la base arriba | `status: ok` |
| INT-D2 `/health/db` con la base caída (monkeypatch del engine) | Error controlado, sin datos internos |
| INT-D3 Conexión muerta recuperada por `pool_pre_ping` | La siguiente petición funciona (marcar `@pytest.mark.postgres`) |

### 4. Contrato de la API (#101)
1. `python -c "import json;from app.main import app;print(json.dumps(app.openapi(),indent=1,sort_keys=True))" > openapi.json` en `services/api/`.
2. `tests/test_contrato_openapi.py`: compara `app.openapi()` con `openapi.json`; si
   difiere, falla con el mensaje «regenera con scripts/dump_openapi.py y revisa si es un cambio de contrato». Crea ese script (como `dump_schema.py`).
3. Fija `info.version` (hoy `0.1.0`) y escribe en el README de la API la política: «/v1 no se rompe; cambios incompatibles → /v2».

## Hecho cuando
- [ ] `tests/test_integracion_notificador.py` y ≥ 4 casos nuevos de KYC/DB en verde en CI (job Postgres 18).
- [ ] `openapi.json` versionado y la prueba de contrato.
- [ ] Capturas, `junit.xml` y tabla de ≥ 20 casos (9 existentes + nuevos) con métricas.
- [ ] Observaciones honestas: lo que **no** se prueba contra el KYC real (solo simulado).

## Te van a preguntar
- ¿Por qué un servicio simulado y no el real? ¿Qué riesgo queda? (cambios de contrato, cold start real)
- ¿Por qué el timeout de lectura no se reintenta pero el 502 sí?
- ¿Qué pasa con el registro si Telegram cae?
