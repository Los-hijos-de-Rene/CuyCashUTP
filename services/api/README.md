# CuyCash · servicio de API

Backend de CuyCash: identidad (registro, ingreso con DNI + PIN, verificación de
dispositivo, recuperación de PIN, biometría, proxy del servicio de KYC),
perfil y alias único, hasta 5 cuentas por titular, libro mayor con partida
doble, transferencias buscando por DNI o alias, depósito simulado, historial
por cuenta y combinado, y beneficiarios frecuentes.

Desplegado en Render: `https://cuycashutp.onrender.com` (manual en
[`docs/despliegue.md`](../../docs/despliegue.md)).

Diseño y razones: [`docs/adr/0002-backend-de-autenticacion.md`](../../docs/adr/0002-backend-de-autenticacion.md).

## Por qué existe

Casi todo lo que hace este servicio estaba **simulado en la app**, y buena parte
no puede vivir ahí ni en teoría: un contador de intentos que guarda el propio
teléfono se borra reinstalando, y una API key compilada en el binario es
extraíble.

## Levantar

### Sin instalar nada (SQLite)

Es lo más rápido y alcanza para la demo y para que la app hable con el backend:

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
DATABASE_URL="sqlite+aiosqlite:///./cuycash.db" \
  .venv/bin/python -m uvicorn app.main:app --reload --port 8001
```

El esquema es el mismo que en Postgres; SQLAlchemy se encarga de la diferencia.
Lo que cambia es la concurrencia y la durabilidad, que a esta escala no se
notan. **Postgres es lo que va a producción.**

### Con Postgres

```sh
cp .env.example .env
docker compose up --build          # API en :8001, Postgres en :5432
```

Documentación interactiva: `http://localhost:8001/docs`.

Desde el emulador de Android la IP del host es `10.0.2.2`; desde un teléfono
físico, la IP del PC en la red local.

## Tests

```sh
.venv/bin/python -m pytest
```

Corren sobre **SQLite en memoria**: no hace falta Postgres levantado. El
esquema es el mismo, y lo que se prueba es la lógica, no el motor. Incluyen
pruebas de seguridad web (`test_seguridad_web.py`) y de consistencia del DDL
(`test_consistencia_ddl.py`). Plan completo en
[`docs/plan-de-pruebas.md`](../../docs/plan-de-pruebas.md).

## Operación

| Herramienta | Para qué |
|---|---|
| `GET /health` | Vida del proceso (health check de Render; no toca la base). |
| `GET /health/db` | La base responde: `SELECT 1` y su latencia; 503 si no. |
| `scripts/smoke_prod.sh [URL]` | Prueba de humo de solo lectura contra un despliegue. |
| `scripts/monitoreo.sql` | Consultas de monitoreo e integridad del libro para la consola SQL de Neon. |
| `scripts/dump_schema.py > schema.sql` | Regenera el DDL desde los modelos. |
| `scripts/reset_schema.py` | Recrea el esquema (**borra los datos**; con cerrojo contra hosts remotos). |

## El código del OTP durante el desarrollo

Con `OTP_NOTIFIER=log` (por defecto) el código aparece en la consola:

```
WARNING [OTP:recovery] juan@correo.com -> 482167
```

Para demostrar en vivo, `OTP_NOTIFIER=telegram` con el token y el chat. **No es
equivalente al correo**: cambia el factor de posesión y, si todos los códigos
caen en el mismo chat, cualquier asistente ve el de cualquiera.

## Decisiones que conviene no revertir sin leer el ADR

- **Las respuestas tardan lo mismo** exista o no el DNI (`UNIFORM_RESPONSE_SECONDS`),
  y se verifica un hash de descarte cuando no hay usuario. Sin eso, el tiempo
  de respuesta revela qué DNI están registrados y reabre la enumeración de
  cuentas que la app cerró con el mensaje genérico.
- **Dos contadores de intentos.** Por DNI, consecutivo y escalonado
  (15 min → 1 h → 24 h): protege una cuenta contra muchos teléfonos. Por
  dispositivo, con **ventana deslizante**: protege contra barrer muchas cuentas
  desde uno. La ventana no se reinicia con un login correcto, porque si no
  bastaría con intercalar una entrada válida cada 9 intentos.
- **Tokens opacos, no JWT.** Cambiar el PIN revoca todas las sesiones, y eso con
  un JWT autocontenido exige una lista de bloqueo que anula su ventaja.
- **`pin/check-current` exige un ticket de OTP y tiene tope.** Sin eso sería un
  oráculo del PIN.
- **Del KYC se guarda el veredicto, nunca las imágenes.** Un PIN robado se
  cambia; una cara, no.

## Pendiente

- Migraciones con Alembic: hoy el esquema se crea al arrancar, lo que sirve
  para la demo pero no para una base con datos.
- Proveedor SMTP real (Mailtrap para QA).
- El proxy del KYC devuelve la respuesta completa; para respuestas grandes
  convendría también transmitirla en stream.
