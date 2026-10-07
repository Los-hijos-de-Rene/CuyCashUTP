# Administración, replicación y monitoreo de la base de datos

**APF2 · criterio 1.1 (Informe de Administración y Replicación) y 3.4
(Monitoreo y administración de la BD en producción).**

Motor en producción: **PostgreSQL gestionado en Neon** (plan Free), consumido
por `services/api` desplegado en Render. En desarrollo y en la suite de pruebas
se usa SQLite con el mismo esquema (SQLAlchemy abstrae la diferencia).

Estado de cada punto: **[implementado]** está en el código o en la
configuración del repositorio; **[plataforma]** lo da Neon por ser servicio
gestionado y no requiere código nuestro; **[pendiente]** no existe todavía.

---

## 1. Arquitectura de datos en producción

```
App Flutter ──HTTPS──▶ Render (FastAPI, Docker) ──TLS──▶ Neon (Postgres 16)
                        cuycashutp.onrender.com          rama principal
                        /health  /health/db              + historial (PITR)
```

- La app **nunca** habla con la base: todo pasa por la API, que es la única
  con credenciales. **[implementado]**
- La cadena de conexión (`DATABASE_URL`) vive como variable secreta en Render
  (`sync: false` en `render.yaml`), no en el repositorio. **[implementado]**
- La conexión a Neon es cifrada: `app/db/base.py` traduce `sslmode=require` de
  la cadena de Neon a `ssl=True` de asyncpg. Si se pierde esa traducción, el
  servicio no llega a conectarse, así que no puede degradar a texto plano en
  silencio. **[implementado]**

## 2. Estrategia de replicación

| Mecanismo | Qué protege | Estado |
|---|---|---|
| **Replicación del WAL en la capa de almacenamiento de Neon.** Cada escritura confirmada se persiste en varios *safekeepers* antes de responder el `COMMIT`, y el almacenamiento separa cómputo de datos. | Pérdida de datos por caída de un nodo. | [plataforma] |
| **Réplicas de lectura** (computes de solo lectura sobre el mismo almacenamiento, sin copiar datos). El plan Free admite hasta 3 por proyecto. | Escalar lecturas, consultas analíticas sin cargar el primario. | [plataforma] disponible, **no activada**: con la carga actual el primario sobra. Se activa con un clic o con la API de Neon (`type: read_only`). |
| **Una sola instancia de escritura.** El libro mayor depende de `SELECT … FOR UPDATE` para serializar movimientos de una misma cuenta; con un solo primario el bloqueo es global. | Doble gasto y carreras de saldo. | [implementado] (`app/services/ledger.py`) |

**Por qué no una réplica de escritura (multi‑primario).** El motor
transaccional necesita que dos débitos sobre la misma cuenta se ordenen en un
solo lugar. Con dos primarios, cada uno aceptaría su débito y el saldo quedaría
negativo. Por diseño, la escritura es única y la escala se gana en lecturas.

## 3. Respaldo y recuperación

| Mecanismo | Alcance | Estado |
|---|---|---|
| **Restauración a un punto en el tiempo (PITR).** Neon conserva el historial de cambios y permite crear una rama o restaurar desde cualquier instante dentro de la ventana. | Plan Free: **6 horas** (tope de 1 GB de cambios). Plan Launch: hasta 7 días. | [plataforma] |
| **Snapshot manual.** | 1 en el plan Free. | [plataforma]; se recomienda uno antes de cada `reset_schema` o despliegue con cambios de modelo. |
| **Ramas (branching).** Copia instantánea de la base para probar un cambio sin tocar producción. | 10 ramas por proyecto en Free. | [plataforma] |
| **Recrear el esquema** (`scripts/reset_schema.py`). | Solo sin datos reales: borra y crea todas las tablas. Lleva cerrojo: sin `ALLOW_DESTRUCTIVE_RESET=1` rechaza cualquier host que no sea local y `ENV=production`. | [implementado] |
| **Migraciones versionadas** (Alembic). | Cambios de esquema sin perder datos. | **[pendiente]**: hoy `create_all` crea lo que falta y no altera lo existente. |

Procedimiento de recuperación ante un borrado accidental:

1. En la consola de Neon: *Branches → Create branch → Past data*, con un
   instante anterior al incidente (dentro de las 6 h).
2. Verificar en la rama nueva con `scripts/monitoreo.sql` (consultas 6 y 7).
3. *Restore* de la rama principal a ese instante, o apuntar `DATABASE_URL` de
   Render a la rama verificada y redesplegar.

**Riesgo asumido.** Con el plan Free, un incidente detectado después de 6 horas
no se puede revertir. Para datos reales, el plan Launch (7 días) es el mínimo.

## 4. Administración

| Tarea | Cómo | Estado |
|---|---|---|
| Crear/actualizar esquema | Al arrancar el servicio (`create_all` en `app/main.py`). | [implementado] |
| DDL de referencia | `services/api/schema.sql`, generado de los modelos con `scripts/dump_schema.py`. Un test garantiza que coinciden (ver `docs/modelo-datos.md`). | [implementado] |
| Integridad en el motor | `CHECK` de saldo no negativo (salvo la caja), `CHECK (monto > 0)` en asientos, `UNIQUE` en DNI, alias, número de cuenta y `idempotency_key`. | [implementado] |
| Credenciales | Rol de Neon con contraseña en `DATABASE_URL` (secreto de Render). La app no tiene credenciales de base. | [implementado] |
| Pool de conexiones | `create_async_engine` con el pool por defecto de SQLAlchemy (5 conexiones + 10 de desborde) por proceso. | [implementado] |
| Escala a cero | Neon suspende el cómputo tras 5 min sin uso; la primera consulta lo despierta (~1 s). Por eso el health check de Render (`/health`) **no** toca la base. | [plataforma] |

## 5. Monitoreo en producción (criterio 3.4)

Tres fuentes, de la más inmediata a la más profunda:

1. **`GET /health/db`** (nuevo): ejecuta `SELECT 1` y devuelve el motor y la
   latencia; `503` si la base no responde, sin filtrar la cadena de conexión.
   Lo consume `scripts/smoke_prod.sh` y cualquier monitor externo.
   ```sh
   curl https://cuycashutp.onrender.com/health/db
   # {"status":"ok","database":"postgresql","latency_ms":…}
   ```
2. **Consola de Neon → Monitoring**: CPU, RAM, conexiones, filas
   leídas/escritas y tamaño de la base. En el plan Free se retiene 1 día de
   historial.
3. **`services/api/scripts/monitoreo.sql`**: consultas de solo lectura para la
   consola SQL de Neon:

   | # | Consulta | Qué vigila | Esperado |
   |---|---|---|---|
   | 1 | `pg_database_size` | Tamaño frente al tope de 0.5 GB del plan Free | Muy por debajo |
   | 2 | `pg_stat_user_tables` | Filas y tamaño por tabla | `ledger_entries` y `transactions` lideran |
   | 3 | `pg_stat_activity` por estado | Fuga de conexiones | Pocas `idle` |
   | 4 | Consultas de más de 5 s | Bloqueos retenidos | 0 filas |
   | 5 | `pg_blocking_pids` | Esperas por `FOR UPDATE` | 0 filas |
   | 6 | Débitos = créditos por transacción | Partida doble | **0 filas** |
   | 7 | Saldo de la columna = suma de asientos | La caché del saldo no se desvió | **0 filas** |
   | 8 | Intentos fallidos y bloqueos de 24 h | Ataques de fuerza bruta | Tendencia estable |

   Las consultas 6 a 8 se validaron contra el esquema real; las 1 a 5 usan
   vistas propias de Postgres y se ejecutan en Neon.

**Logs de la API**: Render → *Logs* muestra cada petición (método, ruta,
código) y las excepciones. No se registran PIN, OTP ni tokens.

## 6. Pendientes conocidos

- Migraciones con Alembic antes de tener datos que no se puedan recrear.
- Alertas automáticas (hoy el monitoreo es a demanda). Neon envía alertas de
  consumo en planes de pago.
- Los tests de concurrencia (`pytest -m postgres`) se ejecutan con toda la suite en el job *Pruebas (PostgreSQL 16)* de *CI backend* (GitHub Actions) desde el 2026-10-07, en verde. Lo que sigue
  sin medir es el rendimiento bajo carga (SLA de 200 ms).

## Evidencias a capturar para el PDF

- [ ] Consola de Neon: *Monitoring* (gráficos de la última hora).
- [ ] Consola de Neon: *Branches* mostrando la ventana de restauración.
- [ ] Consola SQL de Neon con el resultado de las consultas 1, 2, 6 y 7.
- [ ] `curl …/health/db` con `"database":"postgresql"`.
- [ ] Render → *Environment* con `DATABASE_URL` como secreto (valor oculto).
