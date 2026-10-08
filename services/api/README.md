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

Con el KYC facial real (Postgres + API + KYC), con el repo `CuyCashKYC`
clonado junto a `CuyCashUTP`:

```sh
docker compose --profile kyc up --build   # + KYC en 127.0.0.1:8000
```

La API llama al KYC por la red interna (`http://kyc:8000`) con una clave
compartida solo entre los dos contenedores; la app nunca habla con el KYC.
La primera construcción del KYC tarda (TensorFlow y los pesos de los modelos).

Documentación interactiva: `http://localhost:8001/docs`.

Desde el emulador de Android la IP del host es `10.0.2.2`; desde un teléfono
físico, la IP del PC en la red local.

## Datos de prueba en local

**Para qué sirve:** en local hay un solo teléfono y un solo DNI real. Sin otros
usuarios no hay a quién enviar dinero, y para volver a probar el registro
(con KYC) hay que vaciar la base. Estas herramientas hacen las dos cosas sin
tocar SQL.

**Qué crea:** dos usuarios ficticios con cuenta de ahorros en soles y
**S/ 1,000.00** de saldo (entra por el libro mayor, como una recarga). No pasan
por el KYC.

| Nombre | DNI | Alias | PIN |
|---|---|---|---|
| Ana Prueba | `11111111` | `@ana` | `258036` |
| Luis Prueba | `22222222` | `@luis` | `258036` |

### Desde la terminal

En `services/api`, con `docker compose` levantado (igual en PowerShell y Git Bash):

```sh
docker compose exec auth python -m scripts.dev reset-y-seed   # base vacía + usuarios de prueba
docker compose exec auth python -m scripts.dev seed           # solo agrega los que falten (no borra)
docker compose exec auth python -m scripts.dev reset          # solo vacía la base
```

Después de `reset-y-seed` te registras de nuevo con tu DNI real desde la app.

### Desde la app (botón DEV)

En el flavor `local` aparece un botón **DEV** flotante en todas las pantallas:

- **Reiniciar todo**: lo mismo que `reset-y-seed`, y además borra la sesión y el
  usuario recordado del teléfono (si no, la app abriría el acceso rápido de un
  DNI que ya no existe y el servidor respondería 401).
- **Crear usuarios de prueba**: lo mismo que `seed`.
- **Ver últimos códigos OTP**: para entrar como Ana o Luis desde tu teléfono
  (es un teléfono nuevo para ellos, así que piden el código) sin leer los logs.

Configuración, **una sola vez**: la misma clave en los dos archivos (ninguno
se sube a git).

1. `services/api/.env` → `DEV_TOOLS_KEY=<clave>` (genérala con `openssl rand -hex 16`).
2. `apps/mobile/config.local.json` → `"DEV_TOOLS_KEY": "<clave>"`.
3. `docker compose up -d auth` y vuelve a compilar la app `local`.

### Por qué no puede borrar producción

Todo es destructivo, así que hay un cerrojo de lista de **permitidos**
(`app/services/dev_tools.py`):

- el comando de terminal solo corre con una base **local** (SQLite, `localhost`,
  `127.0.0.1` o `db`, el Postgres de compose) y sin `ENV=production`;
- las rutas `/v1/dev/*` además exigen `DEV_TOOLS=true` (solo en
  `docker-compose.yml`, nunca en `render.yaml`) y la clave en `X-Dev-Key`. Si
  falta algo, responden **404** como si no existieran;
- en la app, el botón solo se arma en el flavor `local` con la clave; en
  `production` y `mock` no existe.

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
| `scripts/dev.py` | Datos de prueba en local: vaciar la base y sembrar usuarios ficticios (ver arriba). |

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
