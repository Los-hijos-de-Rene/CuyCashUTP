# Manual de despliegue en la nube

**APF2 · criterio 3.2 (Manual de despliegue, CI/CD y rollback) y 3.3
(Evidencia de pruebas de despliegue).** El monitoreo de la base (3.4) está en
[`administracion-bd.md`](administracion-bd.md#5-monitoreo-en-producción-criterio-34)
y el plan de pruebas (3.1) en [`plan-de-pruebas.md`](plan-de-pruebas.md).

---

## 1. Arquitectura cloud

```
┌──────────────┐  HTTPS   ┌────────────┐  HTTPS  ┌───────────────────────┐  TLS  ┌──────────────┐
│ App Flutter  │ ───────▶ │ Cloudflare │ ──────▶ │ Render · Web Service  │ ────▶ │ Neon         │
│ flavor       │          │ (borde)    │         │ Docker python:3.10    │       │ PostgreSQL   │
│ production   │          └────────────┘         │ FastAPI + uvicorn     │       │ gestionado   │
└──────────────┘                                 │ cuycashutp.onrender…  │       │ (plan Free)  │
                                                 └───────────────────────┘       └──────────────┘
                                                   secretos: DATABASE_URL,
                                                   KYC_*, TELEGRAM_*
```

| Pieza | Servicio | Plan | Configuración versionada |
|---|---|---|---|
| API | Render, Web Service con Docker | Free (512 MiB, región Oregón) | `render.yaml`, `services/api/Dockerfile` |
| Base de datos | Neon, Postgres gestionado | Free (0.5 GB, PITR 6 h) | Ninguna en el repo: la cadena es un secreto |
| Borde / TLS | Cloudflare (lo pone Render) | — | — |
| App | APK/IPA con el flavor `production` | — | `apps/mobile/config.production.json` (no versionado) |

Por qué esta combinación: los planes gratuitos alcanzan para un proyecto de
aula, Render despliega desde el repositorio sin servidores que administrar y
Neon separa cómputo y almacenamiento, lo que da restauración a un punto en el
tiempo sin configurar respaldos.

## 2. Requisitos previos

- Cuenta en GitHub con acceso al repositorio `Los-hijos-de-Rene/CuyCashUTP`.
- Cuenta en [Render](https://render.com) y en [Neon](https://neon.tech).
- Flutter estable y Android SDK (o Xcode) para compilar la app.

## 3. Paso a paso

### Paso 1 · Crear la base en Neon

1. Neon → *New project* → nombre `cuycash`, Postgres 16, la región más cercana
   a Render (US West, Oregón).
2. En *Connection details* copiar la cadena **con** `?sslmode=require`:
   `postgresql://<usuario>:<clave>@<host>.neon.tech/<base>?sslmode=require`.
   Se pega tal cual: `app/db/base.py` la convierte al driver asyncpg y traduce
   `sslmode` a TLS.
3. (Recomendado) *Branches* → crear una rama `cuycash_test` para correr las
   pruebas de concurrencia sin tocar producción.

### Paso 2 · Crear el servicio en Render

1. Render → *New* → *Blueprint* → conectar el repositorio. Render lee
   `render.yaml` de la raíz:
   - `rootDir: services/api` (despliega solo el backend del monorepo),
   - `runtime: docker` con `services/api/Dockerfile`,
   - `healthCheckPath: /health`.
2. Render pide las variables marcadas `sync: false`. Cargar:

   | Variable | Valor |
   |---|---|
   | `DATABASE_URL` | La cadena de Neon del paso 1 |
   | `OTP_NOTIFIER` | `log` (el código aparece en *Logs*) o `telegram` para demostrar en vivo |
   | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | Solo si `OTP_NOTIFIER=telegram` |
   | `KYC_BASE_URL`, `KYC_API_KEY` | Solo si se usa el proxy del KYC |

3. *Apply*. Render construye la imagen y la arranca. Al arrancar, el servicio
   crea las tablas que falten (`create_all` en `app/main.py`).
4. Render → servicio → *Settings* → **Deploy Hook**: copiar la URL y guardarla
   en GitHub como secreto `RENDER_DEPLOY_HOOK_URL` (*Settings → Secrets and
   variables → Actions*). Es como una contraseña: quien la tiene, despliega.
5. A partir de aquí **Render no despliega solo** (`autoDeployTrigger: "off"`
   en `render.yaml`): lo hace el pipeline de GitHub Actions (§4).

### Paso 3 · Esquema limpio (solo si cambió un modelo)

`create_all` no altera tablas existentes. Si un cambio de modelo lo exige y
**no hay datos reales**, se recrea el esquema contra Neon desde una máquina con
el repositorio:

```sh
cd services/api
# 1) Snapshot o rama de respaldo en Neon antes de esto (ver administracion-bd.md)
DATABASE_URL='<cadena de Neon>' ALLOW_DESTRUCTIVE_RESET=1 \
  .venv/bin/python scripts/reset_schema.py
```

Sin `ALLOW_DESTRUCTIVE_RESET=1` el script se niega a tocar un host remoto.
**Esto borra todos los datos.**

### Paso 4 · Verificar el despliegue

```sh
services/api/scripts/smoke_prod.sh https://cuycashutp.onrender.com
```

Debe terminar con `== 0 fallo(s)`. La documentación interactiva queda en
`https://cuycashutp.onrender.com/docs`.

### Paso 5 · Compilar la app contra producción

```sh
cd apps/mobile
cp config.example.json config.production.json
# editar: "AUTH_BASE_URL": "https://cuycashutp.onrender.com"
#         KYC_BASE_URL / KYC_API_KEY vacíos (la clave no va en el binario)
flutter build apk --flavor production -t lib/main_production.dart \
  --dart-define-from-file=config.production.json
# APK en build/app/outputs/flutter-apk/app-production-release.apk
```

Instalar el APK en el teléfono y registrarse: el registro abre sesión y
vincula ese teléfono.

## 4. Pipeline CI/CD (GitHub Actions)

```
PR ──▶ CI backend ─┐   (solo si cambia services/api)
   └─▶ CI app ─────┤   (solo si cambia apps/ o packages/)
                   ▼
merge a main ──▶ CD backend: CI ─▶ aprobación ─▶ deploy hook ?ref=<sha> ─▶ esperar /health = <sha> ─▶ smoke
                                   (environment production)
tag v* ─────────▶ Build APK ─▶ Release con el APK
a mano ─────────▶ Rollback backend: validar commit ─▶ aprobación ─▶ deploy hook ?ref=<estable> ─▶ esperar ─▶ smoke
```

| Workflow | Archivo | Se dispara | Qué hace |
|---|---|---|---|
| CI backend | `.github/workflows/ci-backend.yml` | PR que toca `services/api/**` (y el CD lo llama en `main`) | `pytest` sobre SQLite **y** las pruebas de concurrencia contra un Postgres 16 real (servicio de Actions) |
| CI app | `.github/workflows/ci-app.yml` | PR o push que toca `apps/**`, `packages/**` | `flutter analyze` y los tests de la app y los dos paquetes |
| CD backend | `.github/workflows/cd-backend.yml` | Push a `main` que toca el backend o `render.yaml`; o a mano | CI → **aprobación** → despliega **el commit probado** → espera a que `/health` lo reporte → `smoke_prod.sh` |
| Rollback backend | `.github/workflows/rollback-backend.yml` | A mano, con el commit estable y el motivo | Valida que el commit estuvo en `main` → **aprobación** → lo despliega → espera → humo |
| Build APK | `.github/workflows/build-apk.yml` | Tag `v*` o a mano | APK `production` (firmado con la clave de depuración) adjunto a un Release |

**App y backend en el mismo repositorio no chocan**: cada CI se filtra por
carpeta, y un PR que toca ambos corre los dos. La app no tiene rollback remoto
(un APK instalado no se retrocede); por eso el backend debe seguir aceptando lo
que envían las versiones anteriores de la app.

**Aprobación**: el environment `production` (*Settings → Environments*) exige
que un colaborador apruebe antes de desplegar o retroceder, y solo admite la
rama `main`. Quien lanzó el workflow puede aprobarlo él mismo.

**Saber qué versión corre**: `GET /health` → `{"status":"ok","version":"<commit>"}`
(Render pone el commit en `RENDER_GIT_COMMIT`).

## 5. Rollback

Hay dos caminos, y conviene conocer los dos:

| | Rollback backend (Actions) | Botón *Rollback* de Render |
|---|---|---|
| Dónde | GitHub → *Actions* → *Rollback backend* → *Run workflow* | Render → servicio → *Deploys* → *Rollback* |
| A qué versión | Cualquier commit que haya estado en `main` | Solo los **2 despliegues previos** (plan gratuito) |
| Velocidad | Minutos (reconstruye la imagen) | Segundos (reutiliza la imagen) |
| Trazabilidad | Queda el motivo, quién aprobó y el resultado del humo | Queda en *Events* de Render |
| Verificación | Espera la versión y corre `smoke_prod.sh` | Manual |

Paso a paso con Actions:

1. Copiar el commit de la última versión estable: lo dice el **resumen** de su
   ejecución de *CD backend* ("Antes / Ahora"), o `GET /health` antes de
   desplegar lo nuevo.
2. *Actions → Rollback backend → Run workflow*: pegar el commit y el motivo.
3. Aprobar en el environment `production`.
4. Esperar el verde: el resumen muestra la versión retirada y la restaurada.
5. **En `main`, `git revert` del cambio malo** y PR: si no, el siguiente
   despliegue lo trae de vuelta.
6. **Los datos no vuelven atrás.** Lo que la versión mala escribió sigue en la
   base: revisarlo con `scripts/monitoreo.sql` y corregirlo con un asiento de
   ajuste o, si hace falta, con la restauración a un punto en el tiempo de
   Neon (`administracion-bd.md` §3).

## 6. Guion de la demostración de rollback

Un mismo error contado en tres actos: el CI protege, un error que el CI no ve
llega a producción y se retrocede, y el rollback no arregla los datos.

**Preparación** (antes de la clase): abrir `/health` para despertar el
servicio; anotar el commit estable que devuelve; tener la app `production`
instalada con una cuenta y saldo.

1. **El CI protege.** Rama con el depósito simulado al doble en
   `services/api/app/api/v1/routers/transfers.py` (`recargar`: acreditar
   `monto * 2`). PR → *CI backend* en rojo
   (`test_una_recarga_acredita_y_deja_el_libro_cuadrado` y otras) → no se puede
   desplegar.
2. **Un error que las pruebas no ven.** El desarrollador cree que el doble es
   una promoción y cambia también las pruebas para que esperen el doble. CI en
   verde → merge → *CD backend* → aprobar → producción. En la app: depositar
   S/ 10 y la constancia dice S/ 20. Las pruebas verifican lo que el equipo
   cree correcto, no lo que el negocio pide: para eso existe el rollback.
   *Rollback backend* con el commit estable → aprobar → verde. Depositar
   S/ 10: entran S/ 10. `/health` muestra el commit restaurado.
3. **El rollback no deshace los datos.** El saldo sigue inflado con los S/ 10
   de más: se muestra en el historial y con la consulta 7 de
   `monitoreo.sql`. Se corrige con un asiento de ajuste, y en `main` se hace
   `git revert` del cambio.

Tiempos aproximados: CI backend ~2 min, build de Render ~3 min, rollback por
Actions ~4 min (el botón de Render, segundos).

## 7. Operación

| Situación | Qué pasa | Qué hacer |
|---|---|---|
| El servicio duerme (plan Free de Render, 15 min sin tráfico) | La primera petición tarda ~1 min | Abrir `/health` antes de una demostración |
| Neon suspende el cómputo (5 min sin uso) | La primera consulta lo despierta (~1 s) | Nada: `pool_pre_ping` descarta las conexiones muertas |
| Despliegue fallido | Render mantiene la versión anterior | Ver *Events* y *Logs* en Render |
| Volver a una versión anterior | — | §5 (Actions o botón de Render) |
| Datos dañados | — | Restauración PITR (ver `administracion-bd.md` §3) |

## 8. Evidencia de pruebas de despliegue

### Ejecución del 2026-10-07 15:40 UTC (antes de desplegar este avance)

```
== https://cuycashutp.onrender.com  2026-10-07T15:40:41Z
OK    API viva (/health) (200)
FALLO Base de datos responde (/health/db): esperaba ok, llegó {"detail":"Not Found"}
OK    HTTP redirige a HTTPS (301)
OK    Ruta protegida sin token (401)
FALLO Token inventado: esperaba 401, llegó 500
FALLO falta la cabecera strict-transport-security
FALLO falta la cabecera x-content-type-options
FALLO falta la cabecera x-frame-options
OK    sin CORS abierto
INFO  latencia de /health en caliente: 0.299190s
== 5 fallo(s)
```

Lectura de los fallos:

- `/health/db` y las tres cabeceras **todavía no estaban desplegados**: se
  añadieron en este avance (`app/main.py`).
- **El 500 con un token inventado fue un hallazgo real.** Repetida la
  petición segundos después, todas las rutas respondieron 401. Causa probable:
  Neon había suspendido el cómputo y el pool de la API entregó una conexión
  cerrada. Se corrigió con `pool_pre_ping=True` en `app/db/base.py`.
  **Pendiente de confirmar en producción**: desplegar, dejar el servicio 5 min
  sin tráfico y volver a correr el script.

Otras comprobaciones del mismo día: `GET /openapi.json` lista 29 rutas, entre
ellas `/v1/movements` y `/v1/me/alias` (lo último fusionado está en
producción); `GET /health` respondió en 0,68 s en frío y 0,30 s en caliente.

### Ejecución después de desplegar este avance

> Pegar aquí la salida de `scripts/smoke_prod.sh` tras el despliegue; se
> espera `== 0 fallo(s)` y `"database":"postgresql"` en `/health/db`.

### Capturas para el PDF

- [ ] Render → *Dashboard* del servicio en estado *Live*, con el último deploy.
- [ ] Render → *Events* (historial de despliegues).
- [ ] Render → *Logs* durante un ingreso.
- [ ] Navegador en `https://cuycashutp.onrender.com/docs` (candado HTTPS).
- [ ] Terminal con `scripts/smoke_prod.sh` en `0 fallo(s)`.
- [ ] Teléfono con la app `production`: registro, inicio con saldo, envío y su
      constancia.
- [ ] Neon → *Tables* mostrando los datos creados desde el teléfono.
