# Cuentas reales, envío de dinero y recarga — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el saldo y los movimientos del home salgan del libro mayor, y que el usuario pueda enviar dinero a otra persona de CuyCash por DNI y recargar su propia cuenta.

**Architecture:** El backend existente (`services/api`, renombrado a `services/api`) expone routers nuevos sobre las tablas de libro mayor que ya están modeladas. Un único módulo, `app/services/ledger.py`, escribe asientos de partida doble dentro de una transacción de base de datos, con idempotencia arbitrada por la restricción única. La app añade tres features verticales (`account`, `transfer`, `beneficiary`), cada una con su `Memory*` para que el flavor `mock` siga arrancando sin red.

**Tech Stack:** FastAPI + SQLAlchemy 2.0 async + Postgres (Neon) / SQLite en tests · Flutter + flutter_bloc + fpdart + freezed + dio + go_router.

**Spec:** `docs/superpowers/specs/2026-10-05-cuentas-y-transferencias-design.md`

## Global Constraints

- **Todo el dinero es un `int` de céntimos.** Ni un `double` en el dominio, en la red ni en la base. En la app va envuelto en `Money`.
- **Rango de monto:** mínimo `1` céntimo, máximo `200_000` céntimos (S/ 2,000.00). Fuera de rango → `AMOUNT_OUT_OF_RANGE`.
- **Errores como valores.** En Dart, `FutureResult<Failure, T>` de `core_kernel`; ningún `throw` cruza capas. En Python, `ApiError(ErrorCode.X, detail)`.
- **Failures sellados:** factory nombrado + subclase, para poder hacer `switch` exhaustivo. Prohibido `when`/`maybeWhen`/`!`.
- **El Bloc consume `application` (Actions/UseCase) por constructor**, nunca el repositorio.
- **Toda interfaz nace con su `Memory*` funcional**, y la misma batería de casos corre contra el `Memory*` y contra el HTTP.
- **Colores y tipografía solo desde `design_system`.** Cero hex sueltos.
- **Copy es-PE en `apps/mobile/lib/l10n/arb/app_es.arb`.** Cero strings de UI hardcodeados. Tras tocar el ARB: `flutter gen-l10n` dentro de `apps/mobile`.
- **Generados se commitean:** `.freezed.dart` y `app_localizations*.dart`.
- **Un widget público por archivo.**
- **PIN del flavor `mock`: `000000`.**
- **Antes de cada commit:** `flutter analyze` con cero issues (raíz del repo) y `flutter test`. En backend: `pytest` dentro de `services/api`.
- **Códigos de error del backend son estables**; el cliente programa contra `code`, nunca contra `detail`.

## Review Focus

Cinco cosas que el spec implica, que ninguna tarea testearía por inercia, y que muerden a un usuario real. Cada una tiene su test asignado a la tarea que posee el código.

1. **Misma `idempotency_key` con un monto distinto.** El usuario edita el monto en la pantalla de confirmación y reenvía: la base devolvería la transacción original y la app le diría "enviaste S/ 500" cuando cobró S/ 250. El servidor debe guardar una huella de la petición junto a la clave y responder `IDEMPOTENCY_KEY_REUSED` (409) si no coincide. → *Tarea 6 y Tarea 9*.
2. **Doble toque en "Confirmar" antes de que vuelva la primera respuesta.** Dos POST en vuelo con la misma clave. La base lo absorbe, pero la UI debe deshabilitar el botón al primer toque, o el usuario ve dos constancias. → *Tarea 16*.
3. **Destinatario con cuenta `bloqueada` o `cerrada`.** Existe el usuario, pero su cuenta no puede recibir. `resolve` debe tratarlo como `RECIPIENT_NOT_FOUND`, no devolver un destinatario al que luego falla el envío. → *Tarea 8*.
4. **La concurrencia del motor no es testeable en SQLite.** `with_for_update()` es un no-op en el dialecto SQLite, que es el que usa `tests/conftest.py`. El test de envíos cruzados no prueba lo que dice probar. → *Tarea 6*: el test se escribe marcado `@pytest.mark.postgres` y se documenta como no cubierto por la suite por defecto. Fingir cobertura aquí es peor que no tenerla.
5. **La sesión vence a mitad del envío.** El interceptor recibe un 401, cierra sesión y navega al login — potencialmente mientras una transferencia está en vuelo. El usuario debe acabar en el login con el envío *no* ejecutado, nunca en una constancia en blanco. → *Tarea 12*.

---

# Parte A — Backend

### Tarea 1: Renombrar `services/api` → `services/api`

El nombre dejó de ser cierto en el momento en que el servicio pasa a mover dinero. Se hace primero y solo, para que el diff del motor no quede sepultado bajo movimientos de archivos.

**Files:**
- Move: `services/api/` → `services/api/`
- Modify: `render.yaml`, `CLAUDE.md`, `README.md`, `docs/adr/0002-backend-de-autenticacion.md`
- Modify: `apps/mobile/lib/feature/auth/infrastructure/http_auth_repository.dart` (solo el comentario que cita la ruta)

**Interfaces:**
- Consumes: nada.
- Produces: la ruta `services/api/` para todas las tareas siguientes. Los imports Python (`app.*`) **no cambian**.

- [ ] **Step 1: Mover el directorio con git**

```bash
cd /Users/jairconislla/Projects/cuycash
git mv services/api services/api
```

- [ ] **Step 2: Comprobar que los tests siguen pasando desde la ruta nueva**

```bash
cd services/api && .venv/bin/python -m pytest -q
```

Expected: PASS, el mismo número de tests que antes del movimiento.

- [ ] **Step 3: Actualizar las referencias textuales**

Buscar y sustituir `services/api` por `services/api` en:

```bash
cd /Users/jairconislla/Projects/cuycash
grep -rln "services/api" --exclude-dir=.git --exclude-dir=.venv --exclude-dir=build .
```

Revisar cada resultado a mano. En `render.yaml` cambia el `rootDir`/`dockerfilePath`; en `CLAUDE.md` la tabla de estructura; en el ADR-0002 las menciones a la ruta. **No** cambiar el nombre de la *feature* `auth` de la app, que sigue llamándose así con razón.

- [ ] **Step 4: Verificar que no queda ninguna referencia**

```bash
grep -rn "services/api" --exclude-dir=.git --exclude-dir=.venv --exclude-dir=build . ; echo "exit=$?"
```

Expected: sin resultados (`exit=1`).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: renombrar services/api a services/api

El servicio deja de ser solo identidad: pasa a exponer cuentas, libro
mayor y transferencias. El nombre viejo mentiría en cada import."
```

---

### Tarea 2: Esquema — cuenta de sistema, beneficiarios, transferencias y reset

**Files:**
- Modify: `services/api/app/db/models.py`
- Create: `services/api/scripts/reset_schema.py`
- Test: `services/api/tests/test_libro_mayor.py` (añadir casos)

**Interfaces:**
- Consumes: la ruta `services/api/` (Tarea 1).
- Produces: `Account.tipo == 'sistema'` con `user_id` nullable y saldo negativo permitido; `Transaction.tipo == 'recarga'`; modelos `Beneficiary(id, user_id, beneficiario_dni, apodo, created_at)` y `Transfer(id, transaction_id, cuenta_origen, cuenta_destino, monto, motivo, estado)`; `Transaction.request_fingerprint: str`.

- [ ] **Step 1: Escribir los tests que fallan**

Añadir al final de `services/api/tests/test_libro_mayor.py`:

```python
async def test_la_cuenta_de_sistema_puede_quedar_en_negativo(db):
    """
    Una recarga crea dinero: lo debita de la caja de CuyCash. Esa cuenta es la
    única que puede estar en rojo, y su saldo es justo lo inyectado en la demo.
    """
    caja = Account(
        user_id=None, numero="19100000000000", tipo="sistema",
        saldo_disponible=0, saldo_contable=0,
    )
    db.add(caja)
    await db.flush()

    caja.saldo_disponible = -50_000
    caja.saldo_contable = -50_000
    await db.commit()

    assert caja.saldo_disponible == -50_000


async def test_una_cuenta_normal_sigue_sin_poder_quedar_en_negativo(db):
    """Relajar el CHECK para la caja no puede relajarlo para los titulares."""
    cuenta = await _cuenta(db, "10000007", "00000000000007", 1_000)
    cuenta.saldo_disponible = -1

    with pytest.raises(IntegrityError):
        await db.commit()


async def test_recarga_es_un_tipo_de_transaccion_valido(db):
    """Una recarga no es un ajuste: mezclarlas ensucia la auditoría."""
    db.add(Transaction(tipo="recarga", idempotency_key="recarga-001"))
    await db.commit()


async def test_un_beneficiario_no_se_duplica_para_el_mismo_titular(db):
    """Guardar dos veces el mismo DNI actualiza el apodo, no crea otra fila."""
    from app.db.models import Beneficiary

    cuenta = await _cuenta(db, "10000008", "00000000000008", 0)
    db.add(Beneficiary(user_id=cuenta.user_id, beneficiario_dni="71234567", apodo="Jenny"))
    await db.commit()

    db.add(Beneficiary(user_id=cuenta.user_id, beneficiario_dni="71234567", apodo="Jenny 2"))
    with pytest.raises(IntegrityError):
        await db.commit()
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_libro_mayor.py -q
```

Expected: FAIL. `test_recarga_...` y los de sistema por `IntegrityError` del CHECK; el de beneficiarios por `ImportError: cannot import name 'Beneficiary'`.

- [ ] **Step 3: Modificar `models.py`**

En `Account`, `user_id` pasa a nullable y el bloque `__table_args__` queda así:

```python
    user_id: Mapped[Optional[str]] = mapped_column(
        ForeignKey("users.id"), index=True, nullable=True
    )
```

```python
    __table_args__ = (
        CheckConstraint(
            "tipo IN ('ahorro','corriente','sistema')", name="ck_accounts_tipo"
        ),
        CheckConstraint("moneda IN ('PEN','USD')", name="ck_accounts_moneda"),
        CheckConstraint(
            "estado IN ('activa','bloqueada','cerrada')", name="ck_accounts_estado"
        ),
        # La caja de CuyCash es la contraparte de cada recarga: su saldo es, por
        # definición, el dinero inyectado en la demo, y por eso va en negativo.
        # Para cualquier cuenta de un titular, el tope sigue siendo la última
        # defensa contra el doble gasto.
        CheckConstraint(
            "tipo = 'sistema' OR saldo_disponible >= 0",
            name="ck_accounts_saldo_no_negativo",
        ),
    )
```

En `Transaction`, el CHECK de tipo y una columna nueva:

```python
    # Huella de los parámetros de la petición. Repetir una clave de
    # idempotencia con OTROS datos no es un reintento, es una operación
    # distinta: devolver la original haría creer al usuario que envió lo que
    # acaba de escribir. Ver Review Focus 1.
    request_fingerprint: Mapped[str] = mapped_column(String(64), default="")
```

```python
        CheckConstraint(
            "tipo IN ('transferencia','recarga','pago_qr','desembolso','cuota','ajuste')",
            name="ck_transactions_tipo",
        ),
```

Y al final del archivo, las dos tablas nuevas:

```python
class Beneficiary(Base):
    """
    Destinatario guardado por un titular. Solo el DNI y un apodo: el nombre y
    la cuenta se resuelven al usarlo, para que un cambio en el destinatario no
    deje copias desactualizadas aquí.
    """

    __tablename__ = "beneficiaries"
    __table_args__ = (UniqueConstraint("user_id", "beneficiario_dni"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    beneficiario_dni: Mapped[str] = mapped_column(String(8), index=True)
    apodo: Mapped[str] = mapped_column(String(40))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Transfer(Base):
    """
    Lo que una transferencia tiene y un asiento no: a quién, desde dónde y por
    qué. Los asientos son el dinero; esta fila es la intención.

    `destino_externo` y `canal` (interbancaria, CCI) son del sprint 3 y no se
    crean todavía.
    """

    __tablename__ = "transfers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    transaction_id: Mapped[str] = mapped_column(
        ForeignKey("transactions.id"), unique=True, index=True
    )
    cuenta_origen: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    cuenta_destino: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    monto: Mapped[int] = mapped_column(BigInteger)
    motivo: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    estado: Mapped[str] = mapped_column(String(12), default="confirmada")
```

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_libro_mayor.py -q
```

Expected: PASS.

- [ ] **Step 5: Escribir el script de reset**

Crear `services/api/scripts/reset_schema.py`:

```python
"""
Borra y recrea el esquema completo.

Existe porque el servicio crea tablas con `Base.metadata.create_all`, que NO
altera las que ya existen: un CHECK modificado no llega nunca a una base ya
desplegada. Mientras no haya datos reales, recrear es más barato que migrar.

Es DESTRUCTIVO. El cerrojo de abajo está puesto para el día en que sí haya
datos y alguien lo ejecute por costumbre.
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings  # noqa: E402
from app.db.base import Base  # noqa: E402
from sqlalchemy.ext.asyncio import create_async_engine  # noqa: E402


async def main() -> None:
    destino = settings.DATABASE_URL
    produccion = "neon.tech" in destino or os.getenv("ENV") == "production"
    if produccion and os.getenv("ALLOW_DESTRUCTIVE_RESET") != "1":
        print(
            "Rechazado: el destino parece producción.\n"
            "Esto BORRA todos los datos. Si es lo que quieres, repite con "
            "ALLOW_DESTRUCTIVE_RESET=1.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    engine = create_async_engine(destino)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    print(f"Esquema recreado en {destino.split('@')[-1]}")


if __name__ == "__main__":
    asyncio.run(main())
```

- [ ] **Step 6: Probar el cerrojo**

```bash
cd services/api
ENV=production .venv/bin/python scripts/reset_schema.py
```

Expected: sale con código 1 y el mensaje de rechazo, sin tocar nada.

- [ ] **Step 7: Commit**

```bash
git add services/api/app/db/models.py services/api/scripts/reset_schema.py services/api/tests/test_libro_mayor.py
git commit -m "feat(api): cuenta de sistema, beneficiarios y transferencias en el esquema

La recarga crea dinero y necesita una contraparte o el asiento no cuadra.
Se recrea el esquema en vez de migrarlo: aún no hay datos que conservar."
```

---

### Tarea 3: `current_user` — autorización en un solo sitio

**Files:**
- Create: `services/api/app/core/deps.py`
- Modify: `services/api/app/api/v1/routers/auth.py` (la validación manual de la línea ~204)
- Test: `services/api/tests/test_sesion_requerida.py`

**Interfaces:**
- Consumes: `app.services.sessions.resolve`, `app.db.models.User`.
- Produces: `async def current_user(authorization: str | None = Header(None), session: AsyncSession = Depends(get_session)) -> User`, importable como `from app.core.deps import current_user`.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_sesion_requerida.py`:

```python
"""
La dependencia que protege todo lo que mueve dinero.

Vive en un solo sitio a propósito: repetida en cada router, el día que alguien
añada una ruta se olvidará de ponerla, y esa ruta quedará abierta.
"""

import pytest
from fastapi import Depends, FastAPI
from httpx import ASGITransport, AsyncClient

from app.core.deps import current_user
from app.db.base import get_session
from app.db.models import User


@pytest.mark.asyncio
async def test_sin_cabecera_responde_401(client):
    r = await client.get("/v1/accounts")
    assert r.status_code == 401
    assert r.json()["detail"]["code"] == "UNAUTHENTICATED"


@pytest.mark.asyncio
async def test_con_token_inventado_responde_401(client):
    r = await client.get("/v1/accounts", headers={"Authorization": "Bearer inventado"})
    assert r.status_code == 401
    assert r.json()["detail"]["code"] == "UNAUTHENTICATED"


@pytest.mark.asyncio
async def test_con_token_valido_devuelve_el_usuario(client, registrado):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    assert r.status_code == 200
```

Y en `services/api/tests/conftest.py`, un fixture que registra y devuelve sesión — lo usarán todas las tareas siguientes:

```python
from dataclasses import dataclass


@dataclass
class Registrado:
    dni: str
    token: str
    user_id: str

    @property
    def auth(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"}


@pytest_asyncio.fixture
async def registrado(client):
    """Un titular con sesión abierta y su cuenta ya creada."""
    return await registrar(client, dni="71234567", nombres="Jenny Marisol", apellidos="Ruiz")


async def registrar(client, *, dni: str, nombres: str, apellidos: str) -> "Registrado":
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": dni,
            "nombres": nombres,
            "apellidos": apellidos,
            "email": f"{dni}@correo.pe",
            "pin": "839201",
        },
        headers={"X-Device-Id": f"dev-{dni}"},
    )
    assert r.status_code == 201, r.text
    user_id = r.json()["id"]

    s = await client.post(
        "/v1/auth/session",
        json={"identifier": dni, "pin": "839201"},
        headers={"X-Device-Id": f"dev-{dni}"},
    )
    assert s.status_code == 200, s.text
    return Registrado(dni=dni, token=s.json()["token"], user_id=user_id)
```

> **Nota al implementador:** los nombres exactos del payload de `/v1/auth/register` y de la ruta de login salen de `app/schemas.py` y `app/api/v1/routers/auth.py`. Léelos y ajusta el fixture a lo que el servicio ya acepta; no cambies el contrato de auth para que encaje el fixture.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_sesion_requerida.py -q
```

Expected: FAIL con `ModuleNotFoundError: No module named 'app.core.deps'`.

- [ ] **Step 3: Escribir la dependencia**

Crear `services/api/app/core/deps.py`:

```python
"""
Dependencias compartidas por los routers que mueven dinero.
"""

from typing import Optional

from fastapi import Depends, Header, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import User
from app.services import sessions


async def current_user(
    authorization: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
) -> User:
    """
    El titular de la sesión del `Authorization: Bearer`, o 401.

    Se valida contra la tabla `sessions`, no contra un JWT autocontenido: es lo
    que permite cerrar todas las sesiones de un usuario en una sentencia
    cuando cambia su PIN.
    """
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ApiError(
            ErrorCode.UNAUTHENTICATED,
            "Tu sesión no es válida. Vuelve a entrar.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    row = await sessions.resolve(session, authorization[7:])
    if row is None:
        raise ApiError(
            ErrorCode.UNAUTHENTICATED,
            "Tu sesión venció. Vuelve a entrar.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    user = (
        await session.execute(select(User).where(User.id == row.user_id))
    ).scalar_one_or_none()
    if user is None:
        raise ApiError(
            ErrorCode.UNAUTHENTICATED,
            "Tu sesión no es válida. Vuelve a entrar.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    return user
```

- [ ] **Step 4: Reescribir la validación manual de `auth.py`**

Sustituir el bloque de `routers/auth.py` que hace `sessions.resolve(session, authorization[7:])` a mano (alrededor de la línea 204) por `user: User = Depends(current_user)`. Si ese endpoint necesita la *fila* de sesión y no el usuario, extraer también `current_session_row` en `deps.py` con el mismo patrón, en lugar de dejar la validación duplicada.

- [ ] **Step 5: Ejecutar la suite entera**

```bash
cd services/api && .venv/bin/python -m pytest -q
```

Expected: los dos primeros tests de `test_sesion_requerida.py` PASAN; el tercero sigue fallando con 404 porque `/v1/accounts` no existe aún. Marcar ese test con `@pytest.mark.xfail(reason="/v1/accounts llega en la Tarea 5")` y quitar la marca en la Tarea 5. El resto de la suite PASA.

- [ ] **Step 6: Commit**

```bash
git add services/api/app/core/deps.py services/api/app/api/v1/routers/auth.py services/api/tests/
git commit -m "feat(api): current_user como dependencia compartida"
```

---

### Tarea 4: Apertura de cuenta y cuenta de sistema

**Files:**
- Create: `services/api/app/services/accounts.py`
- Modify: `services/api/app/api/v1/routers/auth.py` (el handler de `register`)
- Modify: `services/api/app/main.py` (crear la caja al arrancar)
- Test: `services/api/tests/test_apertura_de_cuenta.py`

**Interfaces:**
- Consumes: `Account`, `User`, `current_user`.
- Produces:
  - `async def generar_numero(session) -> str`
  - `async def abrir_cuenta(session, user_id: str) -> Account`
  - `async def cuenta_de_sistema(session) -> Account`

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_apertura_de_cuenta.py`:

```python
"""
HU05: al registrarse, el titular ya tiene dónde recibir dinero.

La apertura va en el MISMO COMMIT que el alta: una identidad sin cuenta es un
estado que luego nadie sabría reparar.
"""

import pytest
from sqlalchemy import select

from app.db.models import Account
from app.services.accounts import cuenta_de_sistema, generar_numero


@pytest.mark.asyncio
async def test_registrarse_abre_una_cuenta_de_ahorros_en_cero(client, registrado):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    cuentas = r.json()["cuentas"]

    assert len(cuentas) == 1
    assert cuentas[0]["tipo"] == "ahorro"
    assert cuentas[0]["moneda"] == "PEN"
    assert cuentas[0]["estado"] == "activa"
    assert cuentas[0]["saldo_disponible"] == 0


@pytest.mark.asyncio
async def test_el_numero_de_cuenta_no_contiene_el_dni(client, registrado):
    """Un número de cuenta no debe filtrar el documento de su titular."""
    r = await client.get("/v1/accounts", headers=registrado.auth)
    numero = r.json()["cuentas"][0]["numero"]

    assert len(numero) == 14
    assert numero.startswith("191")
    assert registrado.dni not in numero


@pytest.mark.asyncio
async def test_la_caja_del_sistema_se_crea_una_sola_vez(db):
    primera = await cuenta_de_sistema(db)
    segunda = await cuenta_de_sistema(db)

    assert primera.id == segunda.id
    assert primera.tipo == "sistema"
    assert primera.user_id is None


@pytest.mark.asyncio
async def test_dos_numeros_generados_no_colisionan(db):
    numeros = {await generar_numero(db) for _ in range(50)}
    assert len(numeros) == 50
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_apertura_de_cuenta.py -q
```

Expected: FAIL con `ModuleNotFoundError: No module named 'app.services.accounts'`.

- [ ] **Step 3: Escribir el servicio**

Crear `services/api/app/services/accounts.py`:

```python
"""
Apertura y numeración de cuentas.
"""

import secrets

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Account

# Prefijo de CuyCash. El resto es aleatorio: derivar el número del DNI haría
# que publicar una cuenta publicara el documento de su titular.
PREFIJO = "191"
NUMERO_SISTEMA = "19100000000000"


async def generar_numero(session: AsyncSession) -> str:
    """14 dígitos: prefijo + 11 aleatorios, reintentando ante colisión."""
    for _ in range(20):
        candidato = PREFIJO + "".join(str(secrets.randbelow(10)) for _ in range(11))
        existe = (
            await session.execute(select(Account.id).where(Account.numero == candidato))
        ).scalar_one_or_none()
        if existe is None:
            return candidato
    raise RuntimeError("No se pudo generar un número de cuenta libre")


async def abrir_cuenta(session: AsyncSession, user_id: str) -> Account:
    """Cuenta de ahorros en soles, activa y en cero. No hace commit."""
    cuenta = Account(
        user_id=user_id,
        numero=await generar_numero(session),
        tipo="ahorro",
        moneda="PEN",
        estado="activa",
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(cuenta)
    await session.flush()
    return cuenta


async def cuenta_de_sistema(session: AsyncSession) -> Account:
    """
    La caja de CuyCash: contraparte de toda recarga.

    Su saldo es, por construcción, el negativo del dinero inyectado en la
    demo. Es la única cuenta a la que el CHECK le permite estar en rojo.
    """
    caja = (
        await session.execute(select(Account).where(Account.tipo == "sistema"))
    ).scalar_one_or_none()
    if caja is not None:
        return caja

    caja = Account(
        user_id=None,
        numero=NUMERO_SISTEMA,
        tipo="sistema",
        moneda="PEN",
        estado="activa",
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(caja)
    await session.flush()
    return caja
```

- [ ] **Step 4: Abrir la cuenta al registrar**

En el handler `register` de `routers/auth.py`, después del `session.add(user)` y su `flush()`, y **antes** del `commit`:

```python
    await accounts.abrir_cuenta(session, user.id)
```

con `from app.services import accounts` arriba. Va antes del commit a propósito: si la apertura falla, el alta entera revierte.

- [ ] **Step 5: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_apertura_de_cuenta.py -q
```

Expected: los dos tests que usan `/v1/accounts` siguen fallando con 404 (el router llega en la Tarea 5) — marcarlos `@pytest.mark.xfail(reason="/v1/accounts llega en la Tarea 5")`. Los dos de `db` PASAN.

- [ ] **Step 6: Commit**

```bash
git add services/api/app/services/accounts.py services/api/app/api/v1/routers/auth.py services/api/tests/test_apertura_de_cuenta.py
git commit -m "feat(api): abrir cuenta al registrarse y caja del sistema"
```

---

### Tarea 5: `GET /v1/accounts` y el historial paginado

**Files:**
- Create: `services/api/app/api/v1/routers/accounts.py`
- Modify: `services/api/app/main.py` (registrar el router)
- Modify: `services/api/app/schemas.py`
- Test: `services/api/tests/test_cuentas_y_movimientos.py`

**Interfaces:**
- Consumes: `current_user` (Tarea 3), `accounts.abrir_cuenta` (Tarea 4).
- Produces: `GET /v1/accounts`, `GET /v1/accounts/{id}/movements`, `GET /v1/movements/{transaction_id}` con la forma exacta del spec.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_cuentas_y_movimientos.py`:

```python
"""
HU05: consulta de saldos y movimientos, < 1 s.

La paginación es por CURSOR y no por offset: con offset, un movimiento nuevo
mientras el usuario hace scroll duplica o salta filas.
"""

import pytest


@pytest.mark.asyncio
async def test_solo_devuelve_las_cuentas_propias(client, registrado, otro_registrado):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    numeros = [c["numero"] for c in r.json()["cuentas"]]

    otra = await client.get("/v1/accounts", headers=otro_registrado.auth)
    numeros_ajenos = [c["numero"] for c in otra.json()["cuentas"]]

    assert set(numeros).isdisjoint(numeros_ajenos)


@pytest.mark.asyncio
async def test_el_historial_de_una_cuenta_ajena_responde_404(
    client, registrado, otro_registrado
):
    """No 403: confirmar que la cuenta existe ya es filtrar información."""
    ajena = (await client.get("/v1/accounts", headers=otro_registrado.auth)).json()
    ajena_id = ajena["cuentas"][0]["id"]

    r = await client.get(f"/v1/accounts/{ajena_id}/movements", headers=registrado.auth)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_una_cuenta_recien_abierta_no_tiene_movimientos(client, registrado):
    cuenta_id = (
        await client.get("/v1/accounts", headers=registrado.auth)
    ).json()["cuentas"][0]["id"]

    r = await client.get(f"/v1/accounts/{cuenta_id}/movements", headers=registrado.auth)
    assert r.status_code == 200
    assert r.json() == {"movimientos": [], "next_cursor": None}


@pytest.mark.asyncio
async def test_un_cursor_corrupto_no_rompe_la_pantalla(client, registrado):
    """Un cursor que no se puede leer devuelve la primera página, no un 500."""
    cuenta_id = (
        await client.get("/v1/accounts", headers=registrado.auth)
    ).json()["cuentas"][0]["id"]

    r = await client.get(
        f"/v1/accounts/{cuenta_id}/movements?cursor=basura",
        headers=registrado.auth,
    )
    assert r.status_code == 200
```

Y en `conftest.py`, el segundo titular:

```python
@pytest_asyncio.fixture
async def otro_registrado(client):
    """La contraparte: sin alguien a quien enviarle, no hay transferencia."""
    return await registrar(client, dni="40123456", nombres="Carlos Alberto", apellidos="Nina")
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_cuentas_y_movimientos.py -q
```

Expected: FAIL con 404 en todas (el router no existe).

- [ ] **Step 3: Escribir el router**

Crear `services/api/app/api/v1/routers/accounts.py`:

```python
"""
Consulta de cuentas y movimientos (HU05).

Nada de aquí escribe. El saldo que se devuelve es la COLUMNA, no la suma del
historial: sumar miles de asientos en cada apertura del home no sostiene el
SLA de 1 s.
"""

import base64
import binascii
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, LedgerEntry, Transaction, Transfer, User

router = APIRouter(prefix="/v1", tags=["Cuentas"])

LIMITE_MAXIMO = 50


def _cuenta_json(c: Account) -> dict:
    return {
        "id": c.id,
        "numero": c.numero,
        "tipo": c.tipo,
        "moneda": c.moneda,
        "estado": c.estado,
        "saldo_disponible": c.saldo_disponible,
        "saldo_contable": c.saldo_contable,
    }


def _codificar_cursor(entry: LedgerEntry) -> str:
    crudo = f"{entry.created_at.isoformat()}|{entry.id}"
    return base64.urlsafe_b64encode(crudo.encode()).decode()


def _decodificar_cursor(cursor: Optional[str]) -> Optional[tuple]:
    """
    Un cursor ilegible devuelve None, no un error.

    El cursor es un detalle de transporte: si llega corrupto, lo correcto es
    empezar por el principio, no dejar al usuario mirando una pantalla rota.
    """
    if not cursor:
        return None
    try:
        crudo = base64.urlsafe_b64decode(cursor.encode()).decode()
        fecha, entry_id = crudo.split("|", 1)
        return datetime.fromisoformat(fecha), entry_id
    except (ValueError, binascii.Error, UnicodeDecodeError):
        return None


async def _cuenta_propia(session: AsyncSession, user: User, cuenta_id: str) -> Account:
    cuenta = (
        await session.execute(
            select(Account).where(Account.id == cuenta_id, Account.user_id == user.id)
        )
    ).scalar_one_or_none()
    if cuenta is None:
        # 404 y no 403: distinguirlos confirmaría que la cuenta existe.
        raise ApiError(
            ErrorCode.ACCOUNT_NOT_FOUND,
            "No encontramos esa cuenta.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return cuenta


@router.get("/accounts")
async def listar_cuentas(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    filas = (
        await session.execute(
            select(Account)
            .where(Account.user_id == user.id)
            .order_by(Account.created_at)
        )
    ).scalars().all()
    return {"cuentas": [_cuenta_json(c) for c in filas]}


@router.get("/accounts/{cuenta_id}/movements")
async def listar_movimientos(
    cuenta_id: str,
    cursor: Optional[str] = None,
    limit: int = Query(20, ge=1, le=LIMITE_MAXIMO),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    cuenta = await _cuenta_propia(session, user, cuenta_id)

    consulta = (
        select(LedgerEntry)
        .where(LedgerEntry.account_id == cuenta.id)
        .order_by(LedgerEntry.created_at.desc(), LedgerEntry.id.desc())
        .limit(limit + 1)
    )
    marca = _decodificar_cursor(cursor)
    if marca is not None:
        fecha, entry_id = marca
        consulta = consulta.where(
            or_(
                LedgerEntry.created_at < fecha,
                (LedgerEntry.created_at == fecha) & (LedgerEntry.id < entry_id),
            )
        )

    filas = (await session.execute(consulta)).scalars().all()
    hay_mas = len(filas) > limit
    pagina = filas[:limit]

    movimientos = [await _movimiento_json(session, e, cuenta) for e in pagina]
    return {
        "movimientos": movimientos,
        "next_cursor": _codificar_cursor(pagina[-1]) if hay_mas and pagina else None,
    }


async def _movimiento_json(
    session: AsyncSession, entry: LedgerEntry, cuenta: Account
) -> dict:
    tx = (
        await session.execute(
            select(Transaction).where(Transaction.id == entry.transaction_id)
        )
    ).scalar_one()

    contraparte, motivo = await _contraparte(session, tx, cuenta)
    return {
        "transaction_id": tx.id,
        "tipo": tx.tipo,
        "estado": tx.estado,
        "direccion": entry.direccion,
        "monto": entry.monto,
        "contraparte": contraparte,
        "motivo": motivo,
        "saldo_posterior": entry.saldo_posterior,
        "created_at": entry.created_at.isoformat(),
    }


async def _contraparte(
    session: AsyncSession, tx: Transaction, cuenta: Account
) -> tuple:
    """
    Quién está al otro lado, con nombre COMPLETO.

    Aquí no se enmascara: ya hubo una operación entre ambos, el nombre dejó de
    ser un dato privado entre ellos. El enmascarado es de `/directory/resolve`,
    donde aún no hay relación.
    """
    if tx.tipo == "recarga":
        return "Recarga de saldo", None

    transfer = (
        await session.execute(select(Transfer).where(Transfer.transaction_id == tx.id))
    ).scalar_one_or_none()
    if transfer is None:
        return None, None

    otra_id = (
        transfer.cuenta_destino
        if transfer.cuenta_origen == cuenta.id
        else transfer.cuenta_origen
    )
    otro = (
        await session.execute(
            select(User)
            .join(Account, Account.user_id == User.id)
            .where(Account.id == otra_id)
        )
    ).scalar_one_or_none()
    nombre = f"{otro.nombres} {otro.apellidos}" if otro else None
    return nombre, transfer.motivo


@router.get("/movements/{transaction_id}")
async def detalle_movimiento(
    transaction_id: str,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    La ficha de un movimiento, para la constancia.

    Se exige que al menos un asiento de la transacción toque una cuenta del
    solicitante: sin eso, cualquiera con un id leería operaciones ajenas.
    """
    entry = (
        await session.execute(
            select(LedgerEntry)
            .join(Account, Account.id == LedgerEntry.account_id)
            .where(
                LedgerEntry.transaction_id == transaction_id,
                Account.user_id == user.id,
            )
        )
    ).scalars().first()
    if entry is None:
        raise ApiError(
            ErrorCode.MOVEMENT_NOT_FOUND,
            "No encontramos ese movimiento.",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    cuenta = (
        await session.execute(select(Account).where(Account.id == entry.account_id))
    ).scalar_one()
    base = await _movimiento_json(session, entry, cuenta)

    transfer = (
        await session.execute(
            select(Transfer).where(Transfer.transaction_id == transaction_id)
        )
    ).scalar_one_or_none()
    if transfer is not None:
        destino = (
            await session.execute(
                select(Account).where(Account.id == transfer.cuenta_destino)
            )
        ).scalar_one()
        base["cuenta_destino_masked"] = f"••••{destino.numero[-4:]}"
    return base
```

Añadir a `app/core/errors.py`: `ACCOUNT_NOT_FOUND = "ACCOUNT_NOT_FOUND"` y `MOVEMENT_NOT_FOUND = "MOVEMENT_NOT_FOUND"`.

Y en `app/main.py`, registrar el router junto a los demás:

```python
from app.api.v1.routers import accounts as accounts_router
app.include_router(accounts_router.router)
```

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_cuentas_y_movimientos.py tests/test_apertura_de_cuenta.py tests/test_sesion_requerida.py -q
```

Expected: PASS. Quitar los `@pytest.mark.xfail` de las Tareas 3 y 4 en este paso y comprobar que esos tres tests pasan de verdad.

- [ ] **Step 5: Ejecutar la suite entera**

```bash
cd services/api && .venv/bin/python -m pytest -q
```

Expected: PASS, sin xfail pendientes.

- [ ] **Step 6: Commit**

```bash
git add services/api/app services/api/tests
git commit -m "feat(api): consulta de cuentas, historial paginado y detalle"
```

---

### Tarea 6: `ledger.post` — el motor de asientos

El corazón del sprint. Ninguna ruta vuelve a insertar un `LedgerEntry` por su cuenta.

**Files:**
- Create: `services/api/app/services/ledger.py`
- Test: `services/api/tests/test_motor_de_asientos.py`

**Interfaces:**
- Consumes: `Account`, `Transaction`, `LedgerEntry`, `cuenta_de_sistema`.
- Produces:
  - `@dataclass(frozen=True) class Asiento: account_id: str; direccion: str; monto: int`
  - `async def post(session, *, tipo: str, asientos: list[Asiento], idempotency_key: str, fingerprint: str, referencia: str | None = None) -> tuple[Transaction, bool]` — el `bool` es `reutilizada`: `True` cuando la clave ya existía y se devuelve la transacción original sin cobrar.
  - Excepciones de negocio: `ApiError(ErrorCode.INSUFFICIENT_FUNDS)`, `ApiError(ErrorCode.IDEMPOTENCY_KEY_REUSED)`.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_motor_de_asientos.py`:

```python
"""
HU17, HU18 y HU16: libro mayor atómico y una sola autorización por pago.

Lo que se prueba aquí es el ÚNICO camino por el que entra dinero al libro.
Si algún día otra ruta escribe asientos sin pasar por `ledger.post`, estas
garantías dejan de valer y nadie se entera: por eso el motor es uno solo.
"""

import pytest
from sqlalchemy import func, select

from app.core.errors import ApiError
from app.db.models import Account, LedgerEntry, Transaction, User
from app.services.ledger import Asiento, post


async def _cuenta(db, dni: str, numero: str, saldo: int) -> Account:
    user = User(
        dni=dni, nombres="Ada", apellidos="Lovelace",
        email=f"{dni}@correo.pe", alias="@ada", pin_hash="x",
    )
    db.add(user)
    await db.flush()
    cuenta = Account(
        user_id=user.id, numero=numero, saldo_disponible=saldo, saldo_contable=saldo
    )
    db.add(cuenta)
    await db.flush()
    return cuenta


@pytest.mark.asyncio
async def test_una_transferencia_mueve_el_saldo_y_cuadra(db):
    origen = await _cuenta(db, "20000001", "19100000000001", 50_000)
    destino = await _cuenta(db, "20000002", "19100000000002", 0)

    tx, reutilizada = await post(
        db,
        tipo="transferencia",
        asientos=[
            Asiento(origen.id, "debito", 15_000),
            Asiento(destino.id, "credito", 15_000),
        ],
        idempotency_key="k-001",
        fingerprint="f-001",
    )
    await db.commit()

    assert reutilizada is False
    assert origen.saldo_disponible == 35_000
    assert destino.saldo_disponible == 15_000

    total = lambda d: select(func.coalesce(func.sum(LedgerEntry.monto), 0)).where(
        LedgerEntry.transaction_id == tx.id, LedgerEntry.direccion == d
    )
    debitos = (await db.execute(total("debito"))).scalar_one()
    creditos = (await db.execute(total("credito"))).scalar_one()
    assert debitos == creditos == 15_000


@pytest.mark.asyncio
async def test_sin_saldo_no_escribe_nada(db):
    """Atomicidad: o débito y crédito, o ninguno (HU18)."""
    origen = await _cuenta(db, "20000003", "19100000000003", 1_000)
    destino = await _cuenta(db, "20000004", "19100000000004", 0)

    with pytest.raises(ApiError) as exc:
        await post(
            db,
            tipo="transferencia",
            asientos=[
                Asiento(origen.id, "debito", 5_000),
                Asiento(destino.id, "credito", 5_000),
            ],
            idempotency_key="k-002",
            fingerprint="f-002",
        )
    assert exc.value.detail["code"] == "INSUFFICIENT_FUNDS"

    asientos = (await db.execute(select(LedgerEntry))).scalars().all()
    assert asientos == []
    assert origen.saldo_disponible == 1_000


@pytest.mark.asyncio
async def test_repetir_la_clave_devuelve_la_original_sin_cobrar_de_nuevo(db):
    """HU16. El cliente reintenta tras un timeout; no puede cobrarse dos veces."""
    origen = await _cuenta(db, "20000005", "19100000000005", 50_000)
    destino = await _cuenta(db, "20000006", "19100000000006", 0)
    asientos = [Asiento(origen.id, "debito", 10_000), Asiento(destino.id, "credito", 10_000)]

    primera, _ = await post(
        db, tipo="transferencia", asientos=asientos,
        idempotency_key="k-003", fingerprint="f-003",
    )
    await db.commit()

    segunda, reutilizada = await post(
        db, tipo="transferencia", asientos=asientos,
        idempotency_key="k-003", fingerprint="f-003",
    )
    await db.commit()

    assert reutilizada is True
    assert segunda.id == primera.id
    assert origen.saldo_disponible == 40_000


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_monto_es_rechazada(db):
    """
    Review Focus 1. El usuario corrige el monto en la pantalla de confirmación
    y reenvía. Devolverle la transacción original le haría creer que envió lo
    que acaba de escribir, cuando se cobró lo anterior.
    """
    origen = await _cuenta(db, "20000007", "19100000000007", 50_000)
    destino = await _cuenta(db, "20000008", "19100000000008", 0)

    await post(
        db, tipo="transferencia",
        asientos=[Asiento(origen.id, "debito", 10_000), Asiento(destino.id, "credito", 10_000)],
        idempotency_key="k-004", fingerprint="monto=10000",
    )
    await db.commit()

    with pytest.raises(ApiError) as exc:
        await post(
            db, tipo="transferencia",
            asientos=[Asiento(origen.id, "debito", 25_000), Asiento(destino.id, "credito", 25_000)],
            idempotency_key="k-004", fingerprint="monto=25000",
        )
    assert exc.value.detail["code"] == "IDEMPOTENCY_KEY_REUSED"
    assert origen.saldo_disponible == 40_000


@pytest.mark.asyncio
async def test_unos_asientos_descuadrados_son_un_error_de_programacion(db):
    """No es un fallo de negocio: es un bug. Debe reventar, no devolverse."""
    origen = await _cuenta(db, "20000009", "19100000000009", 50_000)
    destino = await _cuenta(db, "20000010", "19100000000010", 0)

    with pytest.raises(AssertionError):
        await post(
            db, tipo="transferencia",
            asientos=[Asiento(origen.id, "debito", 10_000), Asiento(destino.id, "credito", 9_000)],
            idempotency_key="k-005", fingerprint="f-005",
        )


@pytest.mark.postgres
@pytest.mark.asyncio
async def test_dos_envios_cruzados_no_se_abrazan(db):
    """
    A→B y B→A a la vez. El bloqueo en orden de id es lo que lo evita.

    NO CORRE EN LA SUITE POR DEFECTO: `tests/conftest.py` usa SQLite, cuyo
    dialecto ignora `with_for_update()`. Aquí pasaría siempre, sin probar
    nada. Exige Postgres y dos sesiones concurrentes; se ejecuta a mano con
    `pytest -m postgres` contra una base real antes de desplegar.
    """
    pytest.skip("Requiere Postgres y dos sesiones concurrentes; ver docstring.")
```

Registrar la marca en `services/api/pytest.ini` o `pyproject.toml`:

```ini
[pytest]
markers =
    postgres: exige una base Postgres real; no corre con SQLite en memoria
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_motor_de_asientos.py -q
```

Expected: FAIL con `ModuleNotFoundError: No module named 'app.services.ledger'`.

- [ ] **Step 3: Escribir el motor**

Crear `services/api/app/services/ledger.py`:

```python
"""
El único módulo que escribe en el libro mayor.

Transferencia, recarga, desembolso y cuota pasan todos por `post`. Es lo que
permite que las garantías del libro —partida doble, atomicidad, idempotencia—
se prueben una vez y valgan para siempre: si cada ruta insertara sus propios
asientos, cada ruta tendría que acordarse de todo esto.
"""

from dataclasses import dataclass
from typing import Optional

from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.db.models import Account, LedgerEntry, Transaction


@dataclass(frozen=True)
class Asiento:
    """El monto es SIEMPRE positivo; el signo lo dice `direccion`."""

    account_id: str
    direccion: str  # 'debito' | 'credito'
    monto: int


async def post(
    session: AsyncSession,
    *,
    tipo: str,
    asientos: list[Asiento],
    idempotency_key: str,
    fingerprint: str,
    referencia: Optional[str] = None,
) -> tuple[Transaction, bool]:
    """
    Registra una operación completa. Devuelve (transacción, reutilizada).

    No hace commit: quien llama decide cuándo cerrar, para poder escribir en la
    misma transacción de base de datos las filas que acompañan a los asientos
    (la fila de `transfers`, por ejemplo).
    """
    debitos = sum(a.monto for a in asientos if a.direccion == "debito")
    creditos = sum(a.monto for a in asientos if a.direccion == "credito")
    # Un descuadre no es un caso de negocio que el usuario pueda provocar: es
    # un bug de quien construyó los asientos. Reventar es la respuesta correcta.
    assert debitos == creditos, f"Asientos descuadrados: {debitos} != {creditos}"
    assert all(a.monto > 0 for a in asientos), "Los montos son siempre positivos"

    existente = (
        await session.execute(
            select(Transaction).where(Transaction.idempotency_key == idempotency_key)
        )
    ).scalar_one_or_none()
    if existente is not None:
        if existente.request_fingerprint != fingerprint:
            # Review Focus 1: misma clave, otros datos. No es un reintento.
            raise ApiError(
                ErrorCode.IDEMPOTENCY_KEY_REUSED,
                "Esa operación ya se envió con otros datos. Vuelve a empezar.",
                status_code=status.HTTP_409_CONFLICT,
            )
        return existente, True

    # Orden fijo por id: dos operaciones que tocan las mismas dos cuentas en
    # sentidos opuestos las bloquean en la misma secuencia y no se abrazan.
    ids = sorted({a.account_id for a in asientos})
    cuentas = {
        c.id: c
        for c in (
            await session.execute(
                select(Account).where(Account.id.in_(ids)).with_for_update()
            )
        ).scalars()
    }

    for a in asientos:
        cuenta = cuentas[a.account_id]
        if a.direccion == "debito" and cuenta.tipo != "sistema":
            if cuenta.saldo_disponible < a.monto:
                raise ApiError(
                    ErrorCode.INSUFFICIENT_FUNDS,
                    "No te alcanza el saldo disponible.",
                )

    tx = Transaction(
        tipo=tipo,
        estado="confirmada",
        idempotency_key=idempotency_key,
        request_fingerprint=fingerprint,
        referencia=referencia,
    )
    session.add(tx)
    await session.flush()

    for a in asientos:
        cuenta = cuentas[a.account_id]
        delta = -a.monto if a.direccion == "debito" else a.monto
        cuenta.saldo_disponible += delta
        cuenta.saldo_contable += delta
        session.add(
            LedgerEntry(
                transaction_id=tx.id,
                account_id=cuenta.id,
                direccion=a.direccion,
                monto=a.monto,
                moneda=cuenta.moneda,
                saldo_posterior=cuenta.saldo_disponible,
            )
        )

    await session.flush()
    return tx, False
```

Añadir a `app/core/errors.py`: `INSUFFICIENT_FUNDS`, `IDEMPOTENCY_KEY_REUSED`.

> **Sobre la comprobación previa de la clave:** aquí se consulta antes de insertar, cosa que el spec advertía que deja una ventana. Es correcto porque la fila ya está bloqueada por el `with_for_update()` sobre las cuentas implicadas: dos peticiones con la misma clave compiten por las mismas cuentas. Si alguna vez se añade una operación que no bloquee cuenta alguna, hay que capturar también el `IntegrityError` del `UNIQUE`. Dejar esta nota en el código.

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_motor_de_asientos.py -q
```

Expected: PASS, con un test marcado SKIPPED (el de concurrencia).

- [ ] **Step 5: Commit**

```bash
git add services/api/app/services/ledger.py services/api/app/core/errors.py services/api/tests/test_motor_de_asientos.py services/api/pytest.ini
git commit -m "feat(api): motor de asientos con partida doble e idempotencia"
```

---

### Tarea 7: `POST /v1/transfers`

**Files:**
- Create: `services/api/app/api/v1/routers/transfers.py`
- Modify: `services/api/app/main.py`, `services/api/app/schemas.py`
- Test: `services/api/tests/test_transferencias.py`

**Interfaces:**
- Consumes: `ledger.post`, `ledger.Asiento`, `current_user`, `lockout` (el servicio existente), `verify_pin` de `app.core.security`.
- Produces: `POST /v1/transfers` con el cuerpo del spec. 201 nuevo / 200 reutilizado.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_transferencias.py`:

```python
"""
HU06: envío inmediato entre personas de CuyCash, identificadas por DNI.
"""

import pytest

from tests.conftest import registrar


async def _con_saldo(client, registrado, centimos: int) -> str:
    """Devuelve el id de la cuenta del titular, ya recargada."""
    cuenta_id = (
        await client.get("/v1/accounts", headers=registrado.auth)
    ).json()["cuentas"][0]["id"]
    r = await client.post(
        "/v1/topups",
        json={
            "cuenta_id": cuenta_id,
            "monto_centimos": centimos,
            "pin": "839201",
            "idempotency_key": f"recarga-{registrado.dni}",
        },
        headers=registrado.auth,
    )
    assert r.status_code == 201, r.text
    return cuenta_id


@pytest.mark.asyncio
async def test_un_envio_debita_al_origen_y_acredita_al_destino(
    client, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)

    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "destinatario_dni": otro_registrado.dni,
            "monto_centimos": 25_000,
            "motivo": "Cena compartida",
            "pin": "839201",
            "idempotency_key": "env-001",
        },
        headers=registrado.auth,
    )
    assert r.status_code == 201, r.text

    mio = (await client.get("/v1/accounts", headers=registrado.auth)).json()
    suyo = (await client.get("/v1/accounts", headers=otro_registrado.auth)).json()
    assert mio["cuentas"][0]["saldo_disponible"] == 75_000
    assert suyo["cuentas"][0]["saldo_disponible"] == 25_000


@pytest.mark.asyncio
async def test_reintentar_con_la_misma_clave_responde_200_y_no_cobra_dos_veces(
    client, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)
    cuerpo = {
        "cuenta_origen_id": origen,
        "destinatario_dni": otro_registrado.dni,
        "monto_centimos": 25_000,
        "motivo": None,
        "pin": "839201",
        "idempotency_key": "env-002",
    }

    primera = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    segunda = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)

    assert primera.status_code == 201
    assert segunda.status_code == 200
    assert segunda.json()["transaction_id"] == primera.json()["transaction_id"]

    mio = (await client.get("/v1/accounts", headers=registrado.auth)).json()
    assert mio["cuentas"][0]["saldo_disponible"] == 75_000


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_monto_responde_409(
    client, registrado, otro_registrado
):
    """Review Focus 1, visto desde HTTP."""
    origen = await _con_saldo(client, registrado, 100_000)
    base = {
        "cuenta_origen_id": origen,
        "destinatario_dni": otro_registrado.dni,
        "pin": "839201",
        "idempotency_key": "env-003",
    }

    await client.post("/v1/transfers", json={**base, "monto_centimos": 10_000}, headers=registrado.auth)
    r = await client.post("/v1/transfers", json={**base, "monto_centimos": 50_000}, headers=registrado.auth)

    assert r.status_code == 409
    assert r.json()["detail"]["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_sin_saldo_suficiente_responde_insufficient_funds(
    client, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 5_000)

    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "destinatario_dni": otro_registrado.dni,
            "monto_centimos": 50_000,
            "pin": "839201",
            "idempotency_key": "env-004",
        },
        headers=registrado.auth,
    )
    assert r.json()["detail"]["code"] == "INSUFFICIENT_FUNDS"


@pytest.mark.asyncio
async def test_enviarse_a_uno_mismo_es_rechazado(client, registrado):
    origen = await _con_saldo(client, registrado, 50_000)

    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "destinatario_dni": registrado.dni,
            "monto_centimos": 1_000,
            "pin": "839201",
            "idempotency_key": "env-005",
        },
        headers=registrado.auth,
    )
    assert r.json()["detail"]["code"] == "SELF_TRANSFER"


@pytest.mark.asyncio
@pytest.mark.parametrize("monto", [0, -100, 200_001])
async def test_un_monto_fuera_de_rango_es_rechazado(
    client, registrado, otro_registrado, monto
):
    origen = await _con_saldo(client, registrado, 500_000)

    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "destinatario_dni": otro_registrado.dni,
            "monto_centimos": monto,
            "pin": "839201",
            "idempotency_key": f"env-rango-{monto}",
        },
        headers=registrado.auth,
    )
    assert r.json()["detail"]["code"] == "AMOUNT_OUT_OF_RANGE"


@pytest.mark.asyncio
async def test_un_pin_errado_no_mueve_dinero_y_descuenta_intentos(
    client, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)

    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "destinatario_dni": otro_registrado.dni,
            "monto_centimos": 10_000,
            "pin": "000000",
            "idempotency_key": "env-006",
        },
        headers=registrado.auth,
    )
    assert r.json()["detail"]["code"] == "INVALID_CREDENTIALS"
    assert r.json()["detail"]["intentos_restantes"] == 4

    mio = (await client.get("/v1/accounts", headers=registrado.auth)).json()
    assert mio["cuentas"][0]["saldo_disponible"] == 100_000


@pytest.mark.asyncio
async def test_al_quinto_pin_errado_se_bloquea_la_cuenta(
    client, registrado, otro_registrado
):
    """SLA: bloqueo automático al 5.º intento fallido, también al transferir."""
    origen = await _con_saldo(client, registrado, 100_000)
    cuerpo = lambda n: {
        "cuenta_origen_id": origen,
        "destinatario_dni": otro_registrado.dni,
        "monto_centimos": 10_000,
        "pin": "000000",
        "idempotency_key": f"env-bloq-{n}",
    }

    for n in range(4):
        await client.post("/v1/transfers", json=cuerpo(n), headers=registrado.auth)

    r = await client.post("/v1/transfers", json=cuerpo(99), headers=registrado.auth)
    assert r.json()["detail"]["code"] == "IDENTIFIER_LOCKED"
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_transferencias.py -q
```

Expected: FAIL con 404 (ni `/v1/transfers` ni `/v1/topups` existen).

- [ ] **Step 3: Escribir el router**

Crear `services/api/app/api/v1/routers/transfers.py`. Contiene `/v1/transfers` y `/v1/topups`, porque comparten la verificación de PIN y la construcción de la huella; separarlos duplicaría ambas.

```python
"""
Movimiento de dinero: envío entre personas (HU06) y recarga de saldo.

El PIN se verifica EL ÚLTIMO, después de validar cuenta, destinatario y monto.
Verificarlo antes gastaría intentos de bloqueo en peticiones que iban a
fallar igual, y el bloqueo es una defensa demasiado cara para desperdiciarla.
"""

import hashlib
from typing import Optional

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.core.security import verify_pin
from app.db.base import get_session
from app.db.models import Account, Transfer, User
from app.services import accounts as accounts_service
from app.services import lockout
from app.services.ledger import Asiento, post

router = APIRouter(prefix="/v1", tags=["Dinero"])

MONTO_MINIMO = 1
MONTO_MAXIMO = 200_000  # S/ 2,000.00


class TransferIn(BaseModel):
    cuenta_origen_id: str
    destinatario_dni: str = Field(min_length=8, max_length=8)
    monto_centimos: int
    motivo: Optional[str] = Field(default=None, max_length=40)
    pin: str
    idempotency_key: str = Field(min_length=8, max_length=64)


class TopUpIn(BaseModel):
    cuenta_id: str
    monto_centimos: int
    pin: str
    idempotency_key: str = Field(min_length=8, max_length=64)


def _huella(*partes) -> str:
    """
    Identifica los PARÁMETROS de la operación, no la operación.

    Es lo que permite distinguir un reintento legítimo —mismos datos— de una
    clave reutilizada con datos nuevos. El PIN queda fuera a propósito: no
    tiene por qué viajar a una columna, y no cambia qué operación es.
    """
    crudo = "|".join(str(p) for p in partes)
    return hashlib.sha256(crudo.encode()).hexdigest()


def _validar_monto(centimos: int) -> None:
    if centimos < MONTO_MINIMO or centimos > MONTO_MAXIMO:
        raise ApiError(
            ErrorCode.AMOUNT_OUT_OF_RANGE,
            f"El monto debe estar entre S/ 0.01 y S/ {MONTO_MAXIMO / 100:,.2f}.",
        )


async def _cuenta_operable(session: AsyncSession, user: User, cuenta_id: str) -> Account:
    cuenta = (
        await session.execute(
            select(Account).where(Account.id == cuenta_id, Account.user_id == user.id)
        )
    ).scalar_one_or_none()
    if cuenta is None:
        raise ApiError(
            ErrorCode.ACCOUNT_NOT_FOUND,
            "No encontramos esa cuenta.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    if cuenta.estado != "activa":
        raise ApiError(ErrorCode.ACCOUNT_BLOCKED, "Esa cuenta no está activa.")
    return cuenta


async def _exigir_pin(session: AsyncSession, user: User, pin: str) -> None:
    """
    Autoriza el movimiento. Los fallos alimentan el MISMO bloqueo que el login:
    cinco PIN errados cierran la cuenta, se hayan gastado entrando o enviando.
    """
    estado = await lockout.estado_identificador(session, user.dni)
    if estado.bloqueado:
        raise ApiError(
            ErrorCode.IDENTIFIER_LOCKED,
            "Tu cuenta está bloqueada temporalmente.",
            extra={"locked_until": estado.locked_until.isoformat()},
        )

    if verify_pin(pin, user.pin_hash):
        await lockout.registrar_exito(session, user.dni)
        return

    restantes = await lockout.registrar_fallo(session, user.dni)
    if restantes <= 0:
        estado = await lockout.estado_identificador(session, user.dni)
        raise ApiError(
            ErrorCode.IDENTIFIER_LOCKED,
            "Tu cuenta quedó bloqueada por intentos fallidos.",
            extra={"locked_until": estado.locked_until.isoformat()},
        )
    raise ApiError(
        ErrorCode.INVALID_CREDENTIALS,
        "PIN incorrecto.",
        extra={"intentos_restantes": restantes},
    )


@router.post("/transfers")
async def transferir(
    payload: TransferIn,
    response: Response,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    origen = await _cuenta_operable(session, user, payload.cuenta_origen_id)

    if payload.destinatario_dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes enviarte dinero a ti mismo.")

    destino = (
        await session.execute(
            select(Account)
            .join(User, User.id == Account.user_id)
            .where(
                User.dni == payload.destinatario_dni,
                Account.estado == "activa",
                Account.tipo == "ahorro",
            )
        )
    ).scalars().first()
    if destino is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    _validar_monto(payload.monto_centimos)
    await _exigir_pin(session, user, payload.pin)

    huella = _huella(
        "transferencia", origen.id, destino.id, payload.monto_centimos, payload.motivo
    )
    tx, reutilizada = await post(
        session,
        tipo="transferencia",
        asientos=[
            Asiento(origen.id, "debito", payload.monto_centimos),
            Asiento(destino.id, "credito", payload.monto_centimos),
        ],
        idempotency_key=payload.idempotency_key,
        fingerprint=huella,
    )
    if not reutilizada:
        session.add(
            Transfer(
                transaction_id=tx.id,
                cuenta_origen=origen.id,
                cuenta_destino=destino.id,
                monto=payload.monto_centimos,
                motivo=payload.motivo,
                estado="confirmada",
            )
        )
    await session.commit()

    response.status_code = (
        status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    )
    return {
        "transaction_id": tx.id,
        "estado": tx.estado,
        "monto_centimos": payload.monto_centimos,
        "created_at": tx.created_at.isoformat(),
    }


@router.post("/topups")
async def recargar(
    payload: TopUpIn,
    response: Response,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Cash-in simulado.

    El dinero sale de la caja de CuyCash, que es la única cuenta a la que el
    esquema le permite quedar en negativo. Sin esa contraparte el asiento no
    cuadraría y la conciliación de la épica 6 no tendría nada que cuadrar.
    """
    cuenta = await _cuenta_operable(session, user, payload.cuenta_id)
    _validar_monto(payload.monto_centimos)
    await _exigir_pin(session, user, payload.pin)

    caja = await accounts_service.cuenta_de_sistema(session)
    huella = _huella("recarga", cuenta.id, payload.monto_centimos)
    tx, reutilizada = await post(
        session,
        tipo="recarga",
        asientos=[
            Asiento(caja.id, "debito", payload.monto_centimos),
            Asiento(cuenta.id, "credito", payload.monto_centimos),
        ],
        idempotency_key=payload.idempotency_key,
        fingerprint=huella,
    )
    await session.commit()

    response.status_code = (
        status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    )
    return {
        "transaction_id": tx.id,
        "estado": tx.estado,
        "monto_centimos": payload.monto_centimos,
        "created_at": tx.created_at.isoformat(),
    }
```

Importar `Response` de `fastapi`. Añadir a `errors.py`: `SELF_TRANSFER`, `RECIPIENT_NOT_FOUND`, `ACCOUNT_BLOCKED`, `AMOUNT_OUT_OF_RANGE`. Registrar el router en `main.py`.

> **Nota al implementador:** las funciones `lockout.estado_identificador`, `lockout.registrar_fallo` y `lockout.registrar_exito` son nombres de ejemplo. Lee `app/services/lockout.py` y usa las que realmente existen, con el mismo sujeto (`subject_type='dni'`) que usa el login, para que los contadores sean *el mismo contador*. Si la API del módulo no encaja, adáptala allí — no dupliques la lógica de bloqueo aquí.

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_transferencias.py -q
```

Expected: PASS.

- [ ] **Step 5: Ejecutar la suite entera**

```bash
cd services/api && .venv/bin/python -m pytest -q
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add services/api
git commit -m "feat(api): envío de dinero y recarga sobre el libro mayor"
```

---

### Tarea 8: `GET /v1/directory/resolve` y `/v1/beneficiaries`

**Files:**
- Create: `services/api/app/api/v1/routers/directory.py`
- Modify: `services/api/app/main.py`
- Test: `services/api/tests/test_directorio_y_frecuentes.py`

**Interfaces:**
- Consumes: `current_user`.
- Produces: `GET /v1/directory/resolve?dni=`, `GET|POST /v1/beneficiaries`, `DELETE /v1/beneficiaries/{id}`.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `services/api/tests/test_directorio_y_frecuentes.py`:

```python
"""
Resolver un DNI es el endpoint más delicado del sprint.

Sin enmascarado y sin tope, la app sería un raspador de identidades: teclear
DNIs consecutivos devolvería el nombre de media población.
"""

import pytest

from tests.conftest import registrar


@pytest.mark.asyncio
async def test_resolver_devuelve_el_nombre_enmascarado(
    client, registrado, otro_registrado
):
    r = await client.get(
        f"/v1/directory/resolve?dni={otro_registrado.dni}", headers=registrado.auth
    )
    cuerpo = r.json()

    assert r.status_code == 200
    assert cuerpo["nombre_enmascarado"] == "C*** A*** N***"
    assert "Carlos" not in str(cuerpo)
    assert "Nina" not in str(cuerpo)
    assert cuerpo["cuenta_destino_numero_masked"].startswith("••••")


@pytest.mark.asyncio
async def test_un_dni_inexistente_responde_recipient_not_found(client, registrado):
    r = await client.get("/v1/directory/resolve?dni=99999999", headers=registrado.auth)
    assert r.status_code == 404
    assert r.json()["detail"]["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_un_destinatario_con_la_cuenta_bloqueada_no_se_resuelve(
    client, registrado, otro_registrado, db_de_client
):
    """
    Review Focus 3. Existe la persona, pero su cuenta no puede recibir.
    Devolverla dejaría al usuario escribir el monto para fallar al final.
    """
    from sqlalchemy import update

    from app.db.models import Account

    await db_de_client.execute(
        update(Account)
        .where(Account.user_id == otro_registrado.user_id)
        .values(estado="bloqueada")
    )
    await db_de_client.commit()

    r = await client.get(
        f"/v1/directory/resolve?dni={otro_registrado.dni}", headers=registrado.auth
    )
    assert r.status_code == 404
    assert r.json()["detail"]["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_resolver_el_propio_dni_es_rechazado(client, registrado):
    r = await client.get(
        f"/v1/directory/resolve?dni={registrado.dni}", headers=registrado.auth
    )
    assert r.json()["detail"]["code"] == "SELF_TRANSFER"


@pytest.mark.asyncio
async def test_pasado_el_tope_de_consultas_responde_rate_limited(
    client, registrado
):
    for _ in range(20):
        await client.get("/v1/directory/resolve?dni=99999999", headers=registrado.auth)

    r = await client.get("/v1/directory/resolve?dni=99999999", headers=registrado.auth)
    assert r.status_code == 429
    assert r.json()["detail"]["code"] == "RATE_LIMITED"


@pytest.mark.asyncio
async def test_guardar_dos_veces_el_mismo_dni_actualiza_el_apodo(
    client, registrado, otro_registrado
):
    await client.post(
        "/v1/beneficiaries",
        json={"dni": otro_registrado.dni, "apodo": "Carlos"},
        headers=registrado.auth,
    )
    await client.post(
        "/v1/beneficiaries",
        json={"dni": otro_registrado.dni, "apodo": "Carlitos"},
        headers=registrado.auth,
    )

    r = await client.get("/v1/beneficiaries", headers=registrado.auth)
    lista = r.json()["beneficiarios"]
    assert len(lista) == 1
    assert lista[0]["apodo"] == "Carlitos"


@pytest.mark.asyncio
async def test_los_beneficiarios_son_de_cada_titular(
    client, registrado, otro_registrado
):
    await client.post(
        "/v1/beneficiaries",
        json={"dni": otro_registrado.dni, "apodo": "Carlos"},
        headers=registrado.auth,
    )

    r = await client.get("/v1/beneficiaries", headers=otro_registrado.auth)
    assert r.json()["beneficiarios"] == []
```

El fixture `db_de_client` expone la sesión que usa el `client` (hoy `conftest.py` crea dos motores distintos). Añadirlo refactorizando `client` para que comparta su `maker`:

```python
@pytest_asyncio.fixture
async def db_de_client(client):
    """La MISMA base que ve el cliente HTTP, para montar escenarios difíciles."""
    maker = app.state.test_sessionmaker  # lo fija el fixture `client`
    async with maker() as session:
        yield session
```

y en el fixture `client`, tras crear `maker`, añadir `app.state.test_sessionmaker = maker`.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_directorio_y_frecuentes.py -q
```

Expected: FAIL con 404.

- [ ] **Step 3: Escribir el router**

Crear `services/api/app/api/v1/routers/directory.py`:

```python
"""
Resolver un destinatario y guardar frecuentes.

El DNI es el identificador porque es lo único que hoy distingue a una persona
sin ambigüedad: no hay celular en el modelo y el alias se deriva del nombre,
así que dos homónimos colisionan.
"""

import time
from collections import defaultdict, deque
from typing import Optional

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, Beneficiary, User

router = APIRouter(prefix="/v1", tags=["Directorio"])

CONSULTAS_MAXIMAS = 20
VENTANA_SEGUNDOS = 600

# Ventana deslizante por usuario, en memoria. Es suficiente para una demo de un
# solo proceso; con varias réplicas habría que moverlo a la base o a Redis, y
# esta nota es el recordatorio de que hoy NO protege contra eso.
_consultas: dict = defaultdict(deque)


def _consumir_cupo(user_id: str) -> None:
    ahora = time.monotonic()
    ventana = _consultas[user_id]
    while ventana and ahora - ventana[0] > VENTANA_SEGUNDOS:
        ventana.popleft()
    if len(ventana) >= CONSULTAS_MAXIMAS:
        raise ApiError(
            ErrorCode.RATE_LIMITED,
            "Hiciste demasiadas búsquedas. Espera un momento.",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        )
    ventana.append(ahora)


def enmascarar(nombres: str, apellidos: str) -> str:
    """
    `Carlos Alberto Nina` → `C*** A*** N***`.

    Confirma lo justo para que quien ya conoce al destinatario lo reconozca, y
    no lo bastante para que quien teclea DNIs al azar recolecte nombres.
    """
    partes = f"{nombres} {apellidos}".split()
    return " ".join(f"{p[0].upper()}***" for p in partes if p)


async def _destinatario(session: AsyncSession, dni: str) -> tuple:
    fila = (
        await session.execute(
            select(User, Account)
            .join(Account, Account.user_id == User.id)
            .where(
                User.dni == dni,
                Account.estado == "activa",
                Account.tipo == "ahorro",
            )
        )
    ).first()
    if fila is None:
        # Review Focus 3: una persona con la cuenta bloqueada cae aquí, y es lo
        # correcto — no se le puede enviar nada, así que no es un destinatario.
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return fila[0], fila[1]


@router.get("/directory/resolve")
async def resolver(
    dni: str = Query(min_length=8, max_length=8),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    if dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes enviarte dinero a ti mismo.")

    _consumir_cupo(user.id)
    destinatario, cuenta = await _destinatario(session, dni)
    return {
        "dni": destinatario.dni,
        "nombre_enmascarado": enmascarar(destinatario.nombres, destinatario.apellidos),
        "cuenta_destino_numero_masked": f"••••{cuenta.numero[-4:]}",
    }


class BeneficiaryIn(BaseModel):
    dni: str = Field(min_length=8, max_length=8)
    apodo: str = Field(min_length=1, max_length=40)


@router.get("/beneficiaries")
async def listar(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    filas = (
        await session.execute(
            select(Beneficiary)
            .where(Beneficiary.user_id == user.id)
            .order_by(Beneficiary.created_at.desc())
        )
    ).scalars().all()

    salida = []
    for b in filas:
        otro = (
            await session.execute(select(User).where(User.dni == b.beneficiario_dni))
        ).scalar_one_or_none()
        salida.append(
            {
                "id": b.id,
                "dni": b.beneficiario_dni,
                "apodo": b.apodo,
                "nombre_enmascarado": (
                    enmascarar(otro.nombres, otro.apellidos) if otro else None
                ),
            }
        )
    return {"beneficiarios": salida}


@router.post("/beneficiaries", status_code=status.HTTP_201_CREATED)
async def guardar(
    payload: BeneficiaryIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    if payload.dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes guardarte a ti mismo.")
    await _destinatario(session, payload.dni)

    existente = (
        await session.execute(
            select(Beneficiary).where(
                Beneficiary.user_id == user.id,
                Beneficiary.beneficiario_dni == payload.dni,
            )
        )
    ).scalar_one_or_none()
    if existente is not None:
        existente.apodo = payload.apodo
    else:
        session.add(
            Beneficiary(
                user_id=user.id, beneficiario_dni=payload.dni, apodo=payload.apodo
            )
        )
    await session.commit()
    return {"ok": True}


@router.delete("/beneficiaries/{beneficiary_id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar(
    beneficiary_id: str,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    fila = (
        await session.execute(
            select(Beneficiary).where(
                Beneficiary.id == beneficiary_id, Beneficiary.user_id == user.id
            )
        )
    ).scalar_one_or_none()
    if fila is not None:
        await session.delete(fila)
        await session.commit()
```

Añadir `RATE_LIMITED` a `errors.py`. Registrar el router en `main.py`.

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd services/api && .venv/bin/python -m pytest tests/test_directorio_y_frecuentes.py -q
```

Expected: PASS.

- [ ] **Step 5: Ejecutar la suite entera y commit**

```bash
cd services/api && .venv/bin/python -m pytest -q
git add services/api
git commit -m "feat(api): resolver destinatario por DNI y beneficiarios frecuentes

El nombre va enmascarado y con tope por sesión: sin eso, la app sería un
directorio de la población."
```

---

# Parte B — App

### Tarea 9: `Money` en `core_kernel`

**Files:**
- Create: `packages/core_kernel/lib/src/money.dart`
- Modify: `packages/core_kernel/lib/core_kernel.dart` (export)
- Modify: `apps/mobile/lib/core/format/soles.dart`
- Test: `packages/core_kernel/test/money_test.dart`

**Interfaces:**
- Produces: `Money` con `Money.fromCentimos(int)`, `Money.parse(String) -> Money?`, `Money.zero`, `centimos`, `operator +`, `operator -`, `operator <`, `operator <=`, `operator >`, `operator >=`, `compareTo`, `==`, `hashCode`. Y `String formatSoles(Money)`.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `packages/core_kernel/test/money_test.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('sumar diez veces S/ 0.10 da exactamente S/ 1.00', () {
      // Con double, esta suma da 0.9999999999999999. Es la razón entera de
      // que este tipo exista.
      var total = Money.zero;
      for (var i = 0; i < 10; i++) {
        total = total + Money.fromCentimos(10);
      }
      expect(total, Money.fromCentimos(100));
    });

    test('parse acepta las formas que el usuario escribe', () {
      expect(Money.parse('250'), Money.fromCentimos(25000));
      expect(Money.parse('250.00'), Money.fromCentimos(25000));
      expect(Money.parse('250,00'), Money.fromCentimos(25000));
      expect(Money.parse('250.5'), Money.fromCentimos(25050));
      expect(Money.parse(' 250.00 '), Money.fromCentimos(25000));
      expect(Money.parse('0.01'), Money.fromCentimos(1));
    });

    test('parse rechaza lo que no es un monto', () {
      expect(Money.parse('abc'), isNull);
      expect(Money.parse(''), isNull);
      expect(Money.parse('-5'), isNull);
      expect(Money.parse('1.234'), isNull, reason: 'tres decimales no son soles');
      expect(Money.parse('1.2.3'), isNull);
    });

    test('compara por céntimos', () {
      expect(Money.fromCentimos(100) < Money.fromCentimos(101), isTrue);
      expect(Money.fromCentimos(100) >= Money.fromCentimos(100), isTrue);
    });

    test('dos montos iguales son el mismo valor', () {
      expect(Money.fromCentimos(250), Money.fromCentimos(250));
      expect(
        {Money.fromCentimos(250), Money.fromCentimos(250)}.length,
        1,
      );
    });
  });
}
```

Y en `apps/mobile/test/core/format/soles_test.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/format/soles.dart';

void main() {
  test('formatea con separadores peruanos', () {
    expect(formatSoles(Money.fromCentimos(125040)), 'S/ 1,250.40');
    expect(formatSoles(Money.zero), 'S/ 0.00');
    expect(formatSoles(Money.fromCentimos(5)), 'S/ 0.05');
  });
}
```

> El nombre del paquete en los imports (`package:mobile/...`) sale de `apps/mobile/pubspec.yaml`. Úsalo tal cual aparece ahí.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd packages/core_kernel && dart test
```

Expected: FAIL, `Money` no está definido.

- [ ] **Step 3: Escribir `Money`**

Crear `packages/core_kernel/lib/src/money.dart`:

```dart
/// Un monto en soles, guardado como céntimos enteros.
///
/// Existe porque un `double` que representa S/ 0.10 no vale 0.10: tres sumas
/// después, el saldo de la pantalla ya no es el del libro mayor. El backend
/// decidió céntimos enteros; deshacerlo al deserializar anularía la decisión.
///
/// Al ser un tipo propio, el compilador impide pasar un número crudo donde va
/// dinero.
final class Money implements Comparable<Money> {
  const Money.fromCentimos(this.centimos);

  static const zero = Money.fromCentimos(0);

  /// Lee lo que el usuario escribe: `250`, `250.00`, `250,00`.
  ///
  /// Devuelve `null` ante cualquier cosa que no sea un monto en soles —más de
  /// dos decimales incluido—, en lugar de redondear por su cuenta. Quien
  /// llama decide qué hacer con una entrada inválida; adivinar aquí
  /// escondería el error hasta la pantalla de confirmación.
  static Money? parse(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(limpio)) return null;

    final partes = limpio.split('.');
    final enteros = int.parse(partes[0]);
    final decimales = partes.length > 1 ? partes[1].padRight(2, '0') : '00';
    return Money.fromCentimos(enteros * 100 + int.parse(decimales));
  }

  final int centimos;

  Money operator +(Money other) => Money.fromCentimos(centimos + other.centimos);
  Money operator -(Money other) => Money.fromCentimos(centimos - other.centimos);
  bool operator <(Money other) => centimos < other.centimos;
  bool operator <=(Money other) => centimos <= other.centimos;
  bool operator >(Money other) => centimos > other.centimos;
  bool operator >=(Money other) => centimos >= other.centimos;

  @override
  int compareTo(Money other) => centimos.compareTo(other.centimos);

  @override
  bool operator ==(Object other) => other is Money && other.centimos == centimos;

  @override
  int get hashCode => centimos.hashCode;

  @override
  String toString() => 'Money($centimos)';
}
```

Exportarlo desde `packages/core_kernel/lib/core_kernel.dart`:

```dart
export 'src/money.dart';
```

- [ ] **Step 4: Cambiar `formatSoles`**

Reescribir `apps/mobile/lib/core/format/soles.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:intl/intl.dart';

/// Formatea un monto como `S/ 1,250.40`.
///
/// El símbolo va delante y los separadores son los peruanos: coma para miles,
/// punto para decimales. No se usa `NumberFormat.currency(locale: 'es_PE')`
/// porque los datos de ICU para ese locale devuelven `1.250,40 S/`, que no es
/// como se escribe el dinero en el país ni como lo muestran los bancos.
///
/// Recibe [Money] y no un `double`: el redondeo ya lo hizo quien construyó el
/// monto, y aquí solo se decide cómo se ve.
String formatSoles(Money monto) {
  final soles = monto.centimos / 100;
  return 'S/ ${NumberFormat('#,##0.00', 'en_US').format(soles)}';
}
```

- [ ] **Step 5: Ejecutar los tests**

```bash
cd packages/core_kernel && dart test
cd ../../apps/mobile && flutter test test/core/format/soles_test.dart
```

Expected: PASS ambos. `flutter analyze` desde la raíz señalará los sitios donde `formatSoles` recibe aún un `double` (la BalanceCard de demo): se arreglan en la Tarea 12, no aquí. Si el analyze debe quedar limpio en cada commit, adapta esas llamadas con `Money.fromCentimos((valor * 100).round())` como puente temporal y deja un `// TODO(tarea-12)`.

- [ ] **Step 6: Commit**

```bash
git add packages/core_kernel apps/mobile/lib/core/format apps/mobile/test/core/format
git commit -m "feat(core_kernel): Money en céntimos enteros

Un double que representa S/ 0.10 no vale 0.10, y tres sumas después el
saldo de la pantalla deja de ser el del libro mayor."
```

---

### Tarea 10: `Dio` autenticado compartido

**Files:**
- Create: `apps/mobile/lib/core/http/authenticated_dio.dart`
- Modify: `apps/mobile/lib/core/injection/envs/shared/shared_backend_dependencies.dart`
- Modify: `apps/mobile/lib/feature/auth/infrastructure/http_auth_repository.dart` (dejar de poner la cabecera a mano)
- Test: `apps/mobile/test/core/http/authenticated_dio_test.dart`

**Interfaces:**
- Produces: `Dio buildAuthenticatedDio({required String baseUrl, required String deviceId, required String? Function() readToken, required void Function() onUnauthenticated})`.

- [ ] **Step 1: Escribir los tests que fallan**

Crear `apps/mobile/test/core/http/authenticated_dio_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/http/authenticated_dio.dart';

void main() {
  group('buildAuthenticatedDio', () {
    test('adjunta el token vigente en cada petición', () async {
      late RequestOptions vista;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => 'tok-123',
        onUnauthenticated: () {},
      );
      dio.httpClientAdapter = _Adaptador((options) {
        vista = options;
        return ResponseBody.fromString('{}', 200);
      });

      await dio.get<dynamic>('/v1/accounts');

      expect(vista.headers['Authorization'], 'Bearer tok-123');
      expect(vista.headers['X-Device-Id'], 'dev-1');
    });

    test('sin token no adjunta la cabecera', () async {
      late RequestOptions vista;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => null,
        onUnauthenticated: () {},
      );
      dio.httpClientAdapter = _Adaptador((options) {
        vista = options;
        return ResponseBody.fromString('{}', 200);
      });

      await dio.get<dynamic>('/v1/accounts');

      expect(vista.headers.containsKey('Authorization'), isFalse);
    });

    test('un 401 avisa una sola vez y NO reintenta', () async {
      // Review Focus 5: si la sesión vence durante un envío, el usuario debe
      // acabar en el login con la operación sin ejecutar. Reintentar en
      // silencio podría cobrarle dos veces.
      var avisos = 0;
      var peticiones = 0;
      final dio = buildAuthenticatedDio(
        baseUrl: 'http://test',
        deviceId: 'dev-1',
        readToken: () => 'vencido',
        onUnauthenticated: () => avisos++,
      );
      dio.httpClientAdapter = _Adaptador((options) {
        peticiones++;
        return ResponseBody.fromString(
          '{"detail":{"code":"UNAUTHENTICATED"}}',
          401,
        );
      });

      final r = await dio.post<dynamic>('/v1/transfers', data: <String, dynamic>{});

      expect(avisos, 1);
      expect(peticiones, 1);
      expect(r.statusCode, 401);
    });
  });
}

class _Adaptador implements HttpClientAdapter {
  _Adaptador(this.responder);
  final ResponseBody Function(RequestOptions) responder;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      responder(options);
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/core/http/authenticated_dio_test.dart
```

Expected: FAIL, el archivo no existe.

- [ ] **Step 3: Escribir el builder**

Crear `apps/mobile/lib/core/http/authenticated_dio.dart`:

```dart
import 'package:dio/dio.dart';

/// El `Dio` que usan las features que hablan con el backend autenticado.
///
/// El token se adjunta en un interceptor y no en cada repositorio: así ningún
/// repositorio necesita saber qué es un token, y añadir una feature nueva no
/// es una oportunidad más de olvidarse de la cabecera.
///
/// [readToken] se lee en CADA petición, no una vez al construir: la sesión
/// cambia (login, logout, renovación) y un token capturado al armar el grafo
/// quedaría obsoleto.
Dio buildAuthenticatedDio({
  required String baseUrl,
  required String deviceId,
  required String? Function() readToken,
  required void Function() onUnauthenticated,
  Duration connectTimeout = const Duration(seconds: 20),
  Duration receiveTimeout = const Duration(seconds: 70),
}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    headers: {'X-Device-Id': deviceId},
    // Los 4xx son respuestas de negocio (sin saldo, PIN errado), no
    // excepciones: se leen y se mapean a failures.
    validateStatus: (status) => status != null && status < 500,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      if (response.statusCode == 401) {
        // No se reintenta ni se renueva en silencio. Si la sesión venció a
        // mitad de un envío, el usuario debe acabar en el login con la
        // operación SIN ejecutar: reintentar a ciegas podría cobrarle dos
        // veces. La respuesta sigue su curso para que el repositorio la mapee.
        onUnauthenticated();
      }
      handler.next(response);
    },
  ));

  return dio;
}
```

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd apps/mobile && flutter test test/core/http/authenticated_dio_test.dart
```

Expected: PASS.

- [ ] **Step 5: Enchufarlo en la composición**

En `shared_backend_dependencies.dart`, construir un único `Dio` autenticado y pasarlo a las features nuevas. El token se lee de `authRepository.currentSession`; el `onUnauthenticated` llama a `authRepository.signOut()` (el nombre exacto sale de `AuthRepository`), y el `AppRedirect` ya existente se encarga de llevar al login al emitirse `sessionChanges`.

`HttpAuthRepository` deja de poner `Authorization` a mano en su línea ~211: pasa a recibir el `Dio` autenticado.

- [ ] **Step 6: Verificar y commit**

```bash
cd /Users/jairconislla/Projects/cuycash && flutter analyze && cd apps/mobile && flutter test
git add apps/mobile
git commit -m "feat(app): Dio autenticado compartido con cierre de sesión ante 401"
```

---

### Tarea 11: `feature/account`

**Files:**
- Create: `apps/mobile/lib/feature/account/domain/{account.dart,movement.dart,account_failure.dart,account_repository.dart}`
- Create: `apps/mobile/lib/feature/account/application/account_actions.dart`
- Create: `apps/mobile/lib/feature/account/infrastructure/{memory_account_repository.dart,http_account_repository.dart}`
- Create: `apps/mobile/lib/core/injection/modules/account_module.dart`
- Modify: `apps/mobile/lib/core/injection/app_dependencies.dart` y los tres `envs/`
- Test: `apps/mobile/test/feature/account/{account_repository_contract.dart,memory_account_repository_test.dart,http_account_repository_test.dart}`

**Interfaces:**
- Consumes: `Money` (Tarea 9), el `Dio` autenticado (Tarea 10), `GET /v1/accounts`, `/movements` (Tarea 5).
- Produces:
  - `class Account { String id; String numero; String tipo; String moneda; String estado; Money saldoDisponible; Money saldoContable; String get numeroMasked; }`
  - `enum MovementDirection { debito, credito }`, `enum MovementKind { transferencia, recarga, otro }`
  - `class Movement { String transactionId; MovementKind tipo; MovementDirection direccion; Money monto; String? contraparte; String? motivo; Money saldoPosterior; DateTime fecha; }`
  - `class MovementDetail extends Movement { String estado; String? cuentaDestinoMasked; }`
  - `class MovementPage { List<Movement> items; String? nextCursor; }`
  - `sealed class AccountFailure` con `AccountNotFound`, `Unauthenticated`, `NetworkFailure`, `UnexpectedFailure` (factories `AccountFailure.accountNotFound()`, etc.)
  - `abstract interface class AccountRepository { FutureResult<AccountFailure, List<Account>> cuentas(); FutureResult<AccountFailure, MovementPage> movimientos(String cuentaId, {String? cursor}); FutureResult<AccountFailure, MovementDetail> movimiento(String transactionId); }`
  - `class AccountActions` delegando los tres.

- [ ] **Step 1: Escribir la batería de contrato compartida**

Crear `apps/mobile/test/feature/account/account_repository_contract.dart`:

```dart
import 'package:core_kernel/core_kernel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/feature/account/domain/account_repository.dart';

/// La MISMA batería contra el `Memory*` y contra el HTTP.
///
/// Es lo que impide que el flavor `mock` mienta: si el repositorio en memoria
/// se comporta distinto del real, la app que se demuestra no es la que se
/// despliega.
void probarContratoDeCuentas(
  String nombre,
  AccountRepository Function() construir,
) {
  group('$nombre · contrato de AccountRepository', () {
    test('devuelve al menos una cuenta activa en soles', () async {
      final r = await construir().cuentas();

      r.match(
        (f) => fail('No debía fallar: $f'),
        (cuentas) {
          expect(cuentas, isNotEmpty);
          expect(cuentas.first.moneda, 'PEN');
          expect(cuentas.first.estado, 'activa');
        },
      );
    });

    test('el número enmascarado son los últimos cuatro dígitos', () async {
      final r = await construir().cuentas();

      r.match(
        (f) => fail('No debía fallar: $f'),
        (cuentas) {
          final c = cuentas.first;
          expect(c.numeroMasked, '••••${c.numero.substring(c.numero.length - 4)}');
        },
      );
    });

    test('una cuenta inexistente devuelve accountNotFound, no una excepción', () async {
      final r = await construir().movimientos('no-existe');

      r.match(
        (f) => expect(f, isA<AccountNotFound>()),
        (_) => fail('Debía fallar'),
      );
    });

    test('el detalle de un movimiento ajeno devuelve un failure', () async {
      final r = await construir().movimiento('tx-ajena');

      r.match(
        (f) => expect(f, isNotNull),
        (_) => fail('Debía fallar'),
      );
    });

    test('la página inicial no trae cursor cuando no hay más', () async {
      final repo = construir();
      final cuentas = (await repo.cuentas()).getRight().toNullable()!;
      final r = await repo.movimientos(cuentas.first.id);

      r.match(
        (f) => fail('No debía fallar: $f'),
        (pagina) {
          if (pagina.items.length < 20) {
            expect(pagina.nextCursor, isNull);
          }
        },
      );
    });
  });
}
```

Y los dos archivos que la invocan:

```dart
// apps/mobile/test/feature/account/memory_account_repository_test.dart
import 'package:mobile/feature/account/infrastructure/memory_account_repository.dart';

import 'account_repository_contract.dart';

void main() {
  probarContratoDeCuentas('MemoryAccountRepository', MemoryAccountRepository.new);
}
```

El de HTTP construye un `HttpAccountRepository` sobre un `Dio` con `HttpClientAdapter` simulado que devuelve las respuestas exactas del spec. Seguir el patrón de `apps/mobile/test/feature/auth/http_auth_repository_test.dart`, que ya resuelve esa plomería en este repo — léelo y cópialo.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/feature/account/
```

Expected: FAIL, nada de `feature/account` existe.

- [ ] **Step 3: Escribir domain, application e infrastructure**

Seguir al pie de la letra la forma de `feature/auth`, que es la plantilla declarada en `CLAUDE.md`: interfaz en `domain`, failures sellados con factory nombrado, `*Actions` que delega, `Memory*` funcional e impl HTTP que mapea `code` → failure.

Mapeo de códigos para `HttpAccountRepository`:

| HTTP / `code` | Failure |
|---|---|
| `401` / `UNAUTHENTICATED` | `AccountFailure.unauthenticated()` |
| `404` / `ACCOUNT_NOT_FOUND` | `AccountFailure.accountNotFound()` |
| `404` / `MOVEMENT_NOT_FOUND` | `AccountFailure.accountNotFound()` |
| `DioException` de red/timeout | `AccountFailure.network()` |
| cualquier otro | `AccountFailure.unexpected()` |

El `MemoryAccountRepository` reproduce lo que hoy hay en `demo_wallet.dart`: una cuenta `19100000004521` con S/ 1,250.40 y tres movimientos (Bodega Don Aurelio −S/ 45.00, Jenny Marisol Ruiz +S/ 1,200.00, Menú La Cuchara −S/ 18.50). Esos datos se mueven aquí; `demo_wallet.dart` se borra en la Tarea 12.

- [ ] **Step 4: Ejecutar y ver que pasan**

```bash
cd apps/mobile && flutter test test/feature/account/
```

Expected: PASS las dos baterías.

- [ ] **Step 5: Enchufar en la composición**

`account_module.dart` arma la feature; `AppDependencies` gana `final AccountActions accountActions;`; `mock_dependencies.dart` le pasa el `Memory*` y `shared_backend_dependencies.dart` el HTTP sobre el `Dio` autenticado. Actualizar `test/core/injection/mock_dependencies_test.dart` si comprueba la lista de dependencias.

- [ ] **Step 6: Verificar y commit**

```bash
cd /Users/jairconislla/Projects/cuycash && flutter analyze && cd apps/mobile && flutter test
git add apps/mobile packages
git commit -m "feat(app): feature account con saldo y movimientos reales"
```

---

### Tarea 12: Home real

**Files:**
- Create: `apps/mobile/lib/presentation/home/bloc/{account_bloc.dart,account_event.dart,account_state.dart}`
- Create: `apps/mobile/lib/presentation/home/home_action.dart`
- Modify: `apps/mobile/lib/presentation/home/home_screen.dart`, `widgets/balance_card.dart`, `widgets/movements_card.dart`, `widgets/quick_actions_row.dart`
- Delete: `apps/mobile/lib/presentation/home/demo_wallet.dart`
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Test: `apps/mobile/test/presentation/home/{account_bloc_test.dart,home_screen_test.dart}`

**Interfaces:**
- Consumes: `AccountActions` (Tarea 11).
- Produces: `enum HomeAction { send, charge, topUp, withdraw }`; `AccountBloc` con eventos `AccountStarted`, `AccountRefreshed`, `AccountMoreRequested` y un estado freezed con `enum AccountStatus { loading, ready, error }`.

- [ ] **Step 1: Escribir los tests que fallan**

`apps/mobile/test/presentation/home/account_bloc_test.dart`:

```dart
blocTest<AccountBloc, AccountState>(
  'al arrancar emite loading y luego la cuenta con sus movimientos',
  build: () => AccountBloc(AccountActions(MemoryAccountRepository())),
  act: (bloc) => bloc.add(const AccountStarted()),
  expect: () => [
    isA<AccountState>().having((s) => s.status, 'status', AccountStatus.loading),
    isA<AccountState>()
        .having((s) => s.status, 'status', AccountStatus.ready)
        .having((s) => s.cuenta?.saldoDisponible, 'saldo', isNotNull)
        .having((s) => s.movimientos, 'movimientos', isNotEmpty),
  ],
);

blocTest<AccountBloc, AccountState>(
  'un fallo de red deja la pantalla en error, no vacía',
  build: () => AccountBloc(AccountActions(_RepoQueFalla())),
  act: (bloc) => bloc.add(const AccountStarted()),
  expect: () => [
    isA<AccountState>().having((s) => s.status, 'status', AccountStatus.loading),
    isA<AccountState>()
        .having((s) => s.status, 'status', AccountStatus.error)
        .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
  ],
);

blocTest<AccountBloc, AccountState>(
  'pedir más sin cursor no vuelve a llamar al backend',
  // Evita la llamada infinita al final de una lista corta.
  build: () => AccountBloc(AccountActions(MemoryAccountRepository())),
  seed: () => const AccountState(status: AccountStatus.ready, nextCursor: null),
  act: (bloc) => bloc.add(const AccountMoreRequested()),
  expect: () => <AccountState>[],
);
```

Y en `home_screen_test.dart`, reescribir los casos existentes para que:
- Ya **no** aparezca el sello "Datos de demostración". La clave exacta del ARB sale del `_DemoBadge` de `home_screen.dart`; el test comprueba `findsNothing` sobre ese texto, y la clave se borra del ARB.
- Con el bloc en `ready`, el saldo formateado aparezca en pantalla.
- Tocar "Enviar" navegue a la ruta de envío, verificando con un `GoRouter` de prueba — no con el snackbar de "próximamente".

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/presentation/home/
```

Expected: FAIL.

- [ ] **Step 3: `HomeAction`, el bloc y la pantalla**

`home_action.dart`:

```dart
/// Las cuatro acciones rápidas del inicio.
///
/// Es un enum y no el texto del botón: `QuickActionsRow` notificaba antes con
/// el copy traducido, así que renombrar una cadena en el ARB habría roto la
/// navegación sin que el compilador dijera nada.
enum HomeAction { send, charge, topUp, withdraw }
```

El bloc sigue el patrón de `OtpBloc`: estado `@freezed` con un `status` enum y `switch` exhaustivo en la pantalla. `AccountMoreRequested` sale sin emitir si `nextCursor == null` o si ya está cargando.

Borrar `demo_wallet.dart`. `BalanceCard` pasa a recibir `Money`, `MovementsCard` una `List<Movement>` del dominio, y `QuickActionsRow` notifica con `HomeAction`. Envolver el `ListView` en un `RefreshIndicator` que dispara `AccountRefreshed`, y escuchar el scroll para `AccountMoreRequested`.

Copy nuevo al ARB: estados de carga, error con reintento, y lista vacía ("Aún no tienes movimientos").

- [ ] **Step 4: Regenerar l10n, ejecutar y commit**

```bash
cd apps/mobile && flutter gen-l10n --arb-dir="lib/l10n/arb"
cd /Users/jairconislla/Projects/cuycash && flutter analyze && cd apps/mobile && flutter test
git add apps/mobile
git commit -m "feat(app): el inicio muestra saldo y movimientos reales

Se borra demo_wallet.dart y con él el sello de datos de demostración."
```

---

### Tarea 13: `feature/transfer`

**Files:**
- Create: `apps/mobile/lib/feature/transfer/domain/{recipient.dart,transfer_receipt.dart,transfer_failure.dart,transfer_repository.dart}`
- Create: `apps/mobile/lib/feature/transfer/application/transfer_actions.dart`
- Create: `apps/mobile/lib/feature/transfer/infrastructure/{memory_transfer_repository.dart,http_transfer_repository.dart}`
- Create: `apps/mobile/lib/core/injection/modules/transfer_module.dart`
- Test: `apps/mobile/test/feature/transfer/{transfer_repository_contract.dart,memory_transfer_repository_test.dart,http_transfer_repository_test.dart}`

**Interfaces:**
- Produces:
  - `class Recipient { String dni; String nombreEnmascarado; String cuentaDestinoMasked; }`
  - `class TransferReceipt { String transactionId; Money monto; String? destinatarioNombre; DateTime fecha; }`
  - `sealed class TransferFailure`: `InsufficientFunds`, `RecipientNotFound`, `SelfTransfer`, `WrongPin(int intentosRestantes)`, `Locked(DateTime hasta)`, `RateLimited`, `AmountOutOfRange`, `AccountBlocked`, `IdempotencyKeyReused`, `NetworkFailure`, `UnexpectedFailure`
  - `abstract interface class TransferRepository`:
    - `FutureResult<TransferFailure, Recipient> resolverDestinatario(String dni)`
    - `FutureResult<TransferFailure, TransferReceipt> enviar({required String cuentaOrigenId, required String destinatarioDni, required Money monto, String? motivo, required String pin, required String idempotencyKey})`
    - `FutureResult<TransferFailure, TransferReceipt> recargar({required String cuentaId, required Money monto, required String pin, required String idempotencyKey})`

- [ ] **Step 1: Escribir la batería de contrato**

`apps/mobile/test/feature/transfer/transfer_repository_contract.dart` — los casos, con el PIN válido del escenario inyectado:

```dart
void probarContratoDeTransferencias(
  String nombre,
  TransferRepository Function() construir, {
  required String pinValido,
  required String cuentaOrigenId,
  required String dniDestino,
}) {
  group('$nombre · contrato de TransferRepository', () {
    test('resolver un DNI conocido devuelve el nombre enmascarado', () async {
      final r = await construir().resolverDestinatario(dniDestino);

      r.match(
        (f) => fail('No debía fallar: $f'),
        (d) {
          expect(d.dni, dniDestino);
          expect(d.nombreEnmascarado, contains('***'));
          expect(d.cuentaDestinoMasked, startsWith('••••'));
        },
      );
    });

    test('un DNI desconocido devuelve recipientNotFound', () async {
      final r = await construir().resolverDestinatario('99999999');
      r.match((f) => expect(f, isA<RecipientNotFound>()), (_) => fail('Debía fallar'));
    });

    test('un envío válido devuelve la constancia', () async {
      final r = await construir().enviar(
        cuentaOrigenId: cuentaOrigenId,
        destinatarioDni: dniDestino,
        monto: Money.fromCentimos(25000),
        motivo: 'Cena compartida',
        pin: pinValido,
        idempotencyKey: 'contrato-001',
      );

      r.match(
        (f) => fail('No debía fallar: $f'),
        (c) => expect(c.monto, Money.fromCentimos(25000)),
      );
    });

    test('repetir la clave devuelve la MISMA constancia, no una nueva', () async {
      final repo = construir();
      Future<TransferReceipt> una() async => (await repo.enviar(
            cuentaOrigenId: cuentaOrigenId,
            destinatarioDni: dniDestino,
            monto: Money.fromCentimos(10000),
            pin: pinValido,
            idempotencyKey: 'contrato-002',
          ))
              .getRight()
              .toNullable()!;

      final primera = await una();
      final segunda = await una();

      expect(segunda.transactionId, primera.transactionId);
    });

    test('un PIN errado devuelve wrongPin con los intentos restantes', () async {
      final r = await construir().enviar(
        cuentaOrigenId: cuentaOrigenId,
        destinatarioDni: dniDestino,
        monto: Money.fromCentimos(10000),
        pin: '111111',
        idempotencyKey: 'contrato-003',
      );

      r.match(
        (f) {
          expect(f, isA<WrongPin>());
          expect((f as WrongPin).intentosRestantes, greaterThanOrEqualTo(0));
        },
        (_) => fail('Debía fallar'),
      );
    });

    test('enviar más de lo disponible devuelve insufficientFunds', () async {
      final r = await construir().enviar(
        cuentaOrigenId: cuentaOrigenId,
        destinatarioDni: dniDestino,
        monto: Money.fromCentimos(99999999),
        pin: pinValido,
        idempotencyKey: 'contrato-004',
      );

      r.match(
        (f) => expect(f, anyOf(isA<InsufficientFunds>(), isA<AmountOutOfRange>())),
        (_) => fail('Debía fallar'),
      );
    });

    test('una recarga acredita sin necesitar destinatario', () async {
      final r = await construir().recargar(
        cuentaId: cuentaOrigenId,
        monto: Money.fromCentimos(5000),
        pin: pinValido,
        idempotencyKey: 'contrato-005',
      );

      r.match((f) => fail('No debía fallar: $f'), (c) => expect(c.monto, Money.fromCentimos(5000)));
    });
  });
}
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/feature/transfer/
```

Expected: FAIL.

- [ ] **Step 3: Escribir la feature**

Mapeo de códigos en `HttpTransferRepository`:

| `code` | Failure |
|---|---|
| `INSUFFICIENT_FUNDS` | `TransferFailure.insufficientFunds()` |
| `RECIPIENT_NOT_FOUND` | `TransferFailure.recipientNotFound()` |
| `SELF_TRANSFER` | `TransferFailure.selfTransfer()` |
| `INVALID_CREDENTIALS` | `TransferFailure.wrongPin(detail['intentos_restantes'] as int)` |
| `IDENTIFIER_LOCKED` | `TransferFailure.locked(DateTime.parse(detail['locked_until'] as String))` |
| `RATE_LIMITED` | `TransferFailure.rateLimited()` |
| `AMOUNT_OUT_OF_RANGE` | `TransferFailure.amountOutOfRange()` |
| `ACCOUNT_BLOCKED` | `TransferFailure.accountBlocked()` |
| `IDEMPOTENCY_KEY_REUSED` | `TransferFailure.idempotencyKeyReused()` |
| `UNAUTHENTICATED` | `TransferFailure.unexpected()` — el interceptor ya llevó al login |
| `DioException` de red | `TransferFailure.network()` |

El `MemoryTransferRepository` acepta PIN `000000`, guarda un mapa de `idempotencyKey → TransferReceipt` para cumplir el caso de reintento, y lleva un saldo propio para poder devolver `insufficientFunds`.

- [ ] **Step 4: Ejecutar, enchufar en la composición y commit**

```bash
cd apps/mobile && flutter test test/feature/transfer/
cd /Users/jairconislla/Projects/cuycash && flutter analyze && cd apps/mobile && flutter test
git add apps/mobile
git commit -m "feat(app): feature transfer con envío, recarga y failures sellados"
```

---

### Tarea 14: Flujo de envío y constancia

**Files:**
- Create: `apps/mobile/lib/presentation/transfer/bloc/{transfer_bloc.dart,transfer_event.dart,transfer_state.dart}`
- Create: `apps/mobile/lib/presentation/transfer/{recipient_screen.dart,amount_screen.dart,confirm_screen.dart,receipt_screen.dart}`
- Modify: `apps/mobile/lib/presentation/app/{app_routes.dart,router.dart}`
- Modify: `apps/mobile/lib/l10n/arb/app_es.arb`
- Test: `apps/mobile/test/presentation/transfer/{transfer_bloc_test.dart,confirm_screen_test.dart}`

**Interfaces:**
- Consumes: `TransferActions` (Tarea 13), `AccountActions` (Tarea 11), el teclado de PIN existente de `presentation/pin/`.
- Produces: rutas `AppRoutes.enviar`, `AppRoutes.enviarMonto`, `AppRoutes.enviarConfirmar`, `AppRoutes.enviarConstancia`.

- [ ] **Step 1: Escribir los tests que fallan**

`transfer_bloc_test.dart`, un caso por failure y los dos de la Review Focus:

```dart
blocTest<TransferBloc, TransferState>(
  'la clave de idempotencia se fija al entrar en confirmación y NO cambia al reintentar',
  // Review Focus 1 y 2. Si se generara al pulsar Confirmar, un doble toque
  // produciría dos claves y dos cobros.
  build: () => TransferBloc(TransferActions(_RepoQueFallaPorRed())),
  act: (bloc) async {
    bloc.add(const TransferConfirmationOpened());
    final primera = bloc.state.idempotencyKey;
    bloc.add(const TransferSubmitted(pin: '000000'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const TransferSubmitted(pin: '000000'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.idempotencyKey, primera);
  },
  verify: (bloc) => expect(bloc.state.idempotencyKey, isNotEmpty),
);

blocTest<TransferBloc, TransferState>(
  'mientras hay un envío en vuelo, otro TransferSubmitted se ignora',
  // Review Focus 2: el doble toque no debe llegar siquiera al repositorio.
  build: () => TransferBloc(TransferActions(_RepoLento())),
  act: (bloc) {
    bloc.add(const TransferConfirmationOpened());
    bloc.add(const TransferSubmitted(pin: '000000'));
    bloc.add(const TransferSubmitted(pin: '000000'));
  },
  verify: (_) => expect(_RepoLento.llamadas, 1),
);

blocTest<TransferBloc, TransferState>(
  'un PIN errado conserva el monto y el destinatario',
  // Volver a escribirlo todo tras equivocarse de PIN sería ensañamiento.
  build: () => TransferBloc(TransferActions(MemoryTransferRepository())),
  seed: () => _estadoListoParaConfirmar,
  act: (bloc) => bloc.add(const TransferSubmitted(pin: '111111')),
  expect: () => [
    isA<TransferState>().having((s) => s.status, 'status', TransferStatus.submitting),
    isA<TransferState>()
        .having((s) => s.failure, 'failure', isA<WrongPin>())
        .having((s) => s.monto, 'monto', _estadoListoParaConfirmar.monto)
        .having((s) => s.destinatario, 'destinatario', isNotNull),
  ],
);
```

Y en `confirm_screen_test.dart`, un test de widget: tocar "Confirmar transferencia" dos veces seguidas con el repositorio lento provoca **una** llamada, y el botón queda deshabilitado tras el primer toque.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/presentation/transfer/
```

Expected: FAIL.

- [ ] **Step 3: Escribir bloc y pantallas**

El estado, `@freezed`, con `enum TransferStatus { idle, resolving, ready, submitting, done }` y los campos `Recipient? destinatario`, `Money? monto`, `String? motivo`, `bool guardarFrecuente`, `String idempotencyKey`, `TransferFailure? failure`, `TransferReceipt? constancia`.

`TransferConfirmationOpened` genera la clave con el generador de ids de `core_kernel` (`packages/core_kernel/lib/src/ids.dart`) y la fija en el estado. `TransferSubmitted` sale sin emitir si `status == TransferStatus.submitting`.

Las tres pantallas siguen las maquetas: búsqueda por DNI con frecuentes, monto con disponible y sugeridos, resumen con PIN. `confirm_screen` deshabilita el botón primario en `submitting` y muestra un indicador.

Copy al ARB, incluida la tabla de mensajes de error de la sección "Errores en pantalla" del spec.

- [ ] **Step 4: Regenerar, ejecutar y commit**

```bash
cd apps/mobile && flutter gen-l10n --arb-dir="lib/l10n/arb" && flutter test
cd /Users/jairconislla/Projects/cuycash && flutter analyze
git add apps/mobile
git commit -m "feat(app): flujo de envío de dinero con PIN y constancia"
```

---

### Tarea 15: Recarga

**Files:**
- Create: `apps/mobile/lib/presentation/topup/bloc/{topup_bloc.dart,topup_event.dart,topup_state.dart}`
- Create: `apps/mobile/lib/presentation/topup/topup_screen.dart`
- Modify: `apps/mobile/lib/presentation/app/{app_routes.dart,router.dart}`, `app_es.arb`
- Test: `apps/mobile/test/presentation/topup/topup_bloc_test.dart`

**Interfaces:**
- Consumes: `TransferActions.recargar` (Tarea 13).
- Produces: ruta `AppRoutes.recargar`, alcanzada desde `HomeAction.topUp`.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
blocTest<TopUpBloc, TopUpState>(
  'una recarga válida deja la constancia en el estado',
  build: () => TopUpBloc(TransferActions(MemoryTransferRepository())),
  act: (bloc) {
    bloc.add(const TopUpOpened(cuentaId: 'cta-1'));
    bloc.add(TopUpAmountChanged(Money.fromCentimos(10000)));
    bloc.add(const TopUpSubmitted(pin: '000000'));
  },
  expect: () => [
    isA<TopUpState>(),
    isA<TopUpState>().having((s) => s.monto, 'monto', Money.fromCentimos(10000)),
    isA<TopUpState>().having((s) => s.status, 'status', TopUpStatus.submitting),
    isA<TopUpState>()
        .having((s) => s.status, 'status', TopUpStatus.done)
        .having((s) => s.constancia, 'constancia', isNotNull),
  ],
);

blocTest<TopUpBloc, TopUpState>(
  'una recarga NUNCA falla por fondos',
  // Si este test rompe, alguien conectó la recarga al camino equivocado.
  build: () => TopUpBloc(TransferActions(MemoryTransferRepository())),
  act: (bloc) {
    bloc.add(const TopUpOpened(cuentaId: 'cta-1'));
    bloc.add(TopUpAmountChanged(Money.fromCentimos(200000)));
    bloc.add(const TopUpSubmitted(pin: '000000'));
  },
  verify: (bloc) => expect(bloc.state.failure, isNot(isA<InsufficientFunds>())),
);

blocTest<TopUpBloc, TopUpState>(
  'un monto por encima del máximo se rechaza sin llamar al backend',
  build: () => TopUpBloc(TransferActions(_RepoQueCuentaLlamadas())),
  act: (bloc) {
    bloc.add(const TopUpOpened(cuentaId: 'cta-1'));
    bloc.add(TopUpAmountChanged(Money.fromCentimos(300000)));
    bloc.add(const TopUpSubmitted(pin: '000000'));
  },
  verify: (bloc) {
    expect(bloc.state.failure, isA<AmountOutOfRange>());
    expect(_RepoQueCuentaLlamadas.llamadas, 0);
  },
);
```

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/presentation/topup/
```

Expected: FAIL.

- [ ] **Step 3: Escribir bloc y pantalla**

Mismo patrón que `TransferBloc`, sin destinatario: monto, sugeridos, PIN, constancia. La clave de idempotencia se fija en `TopUpOpened`. Al terminar, volver al home disparando `AccountRefreshed`.

- [ ] **Step 4: Regenerar, ejecutar y commit**

```bash
cd apps/mobile && flutter gen-l10n --arb-dir="lib/l10n/arb" && flutter test
cd /Users/jairconislla/Projects/cuycash && flutter analyze
git add apps/mobile
git commit -m "feat(app): recargar saldo contra la caja del sistema"
```

---

### Tarea 16: Frecuentes y detalle del movimiento

**Files:**
- Create: `apps/mobile/lib/feature/beneficiary/{domain,application,infrastructure}/…`
- Create: `apps/mobile/lib/core/injection/modules/beneficiary_module.dart`
- Create: `apps/mobile/lib/presentation/movement/{movement_detail_screen.dart,bloc/…}`
- Create: `apps/mobile/lib/presentation/transfer/widgets/frequent_row.dart`
- Create: `apps/mobile/lib/presentation/movement/widgets/receipt_card.dart`
- Modify: `recipient_screen.dart`, `receipt_screen.dart`, `movements_card.dart`, `router.dart`, `app_es.arb`
- Test: `apps/mobile/test/feature/beneficiary/…`, `apps/mobile/test/presentation/movement/movement_detail_bloc_test.dart`

**Interfaces:**
- Consumes: `/v1/beneficiaries` (Tarea 8), `AccountActions.movimiento` (Tarea 11).
- Produces:
  - `class Beneficiary { String id; String dni; String apodo; String? nombreEnmascarado; }`
  - `sealed class BeneficiaryFailure` con `BeneficiaryRecipientNotFound`, `BeneficiarySelfTransfer`, `BeneficiaryNetworkFailure`, `BeneficiaryUnexpectedFailure` (factories `BeneficiaryFailure.recipientNotFound()`, etc.)
  - `abstract interface class BeneficiaryRepository { FutureResult<BeneficiaryFailure, List<Beneficiary>> listar(); FutureResult<BeneficiaryFailure, Unit> guardar(String dni, String apodo); FutureResult<BeneficiaryFailure, Unit> eliminar(String id); }`
  - `class BeneficiaryActions` delegando los tres.
  - `MovementDetailBloc` con `MovementDetailOpened(String transactionId)` y `enum MovementDetailStatus { loading, ready, error }`.
  - `ReceiptCard`, el widget compartido por la constancia de un envío recién hecho y por el detalle de un movimiento viejo.

- [ ] **Step 1: Escribir los tests que fallan**

`apps/mobile/test/feature/beneficiary/beneficiary_repository_contract.dart`:

```dart
void probarContratoDeBeneficiarios(
  String nombre,
  BeneficiaryRepository Function() construir, {
  required String dniConocido,
}) {
  group('$nombre · contrato de BeneficiaryRepository', () {
    test('guardar dos veces el mismo DNI actualiza el apodo', () async {
      final repo = construir();
      await repo.guardar(dniConocido, 'Carlos');
      await repo.guardar(dniConocido, 'Carlitos');

      final r = await repo.listar();
      r.match(
        (f) => fail('No debía fallar: $f'),
        (lista) {
          final suyos = lista.where((b) => b.dni == dniConocido).toList();
          expect(suyos, hasLength(1));
          expect(suyos.single.apodo, 'Carlitos');
        },
      );
    });

    test('eliminar uno inexistente no es un error', () async {
      final r = await construir().eliminar('no-existe');
      r.match((f) => fail('No debía fallar: $f'), (_) {});
    });

    test('guardar un DNI que no está en CuyCash devuelve recipientNotFound', () async {
      final r = await construir().guardar('99999999', 'Fantasma');
      r.match(
        (f) => expect(f, isA<BeneficiaryRecipientNotFound>()),
        (_) => fail('Debía fallar'),
      );
    });

    test('el apodo se recorta a 40 caracteres, no revienta', () async {
      final repo = construir();
      final r = await repo.guardar(dniConocido, 'x' * 80);
      r.match((f) => expect(f, isA<BeneficiaryFailure>()), (_) {});
    });
  });
}
```

Y `apps/mobile/test/presentation/movement/movement_detail_bloc_test.dart`:

```dart
blocTest<MovementDetailBloc, MovementDetailState>(
  'carga la ficha del movimiento',
  build: () => MovementDetailBloc(AccountActions(MemoryAccountRepository())),
  act: (bloc) => bloc.add(const MovementDetailOpened('tx-demo-1')),
  expect: () => [
    isA<MovementDetailState>()
        .having((s) => s.status, 'status', MovementDetailStatus.loading),
    isA<MovementDetailState>()
        .having((s) => s.status, 'status', MovementDetailStatus.ready)
        .having((s) => s.detalle?.monto, 'monto', isNotNull),
  ],
);

blocTest<MovementDetailBloc, MovementDetailState>(
  'un movimiento ajeno deja la pantalla en error, no en blanco',
  build: () => MovementDetailBloc(AccountActions(MemoryAccountRepository())),
  act: (bloc) => bloc.add(const MovementDetailOpened('tx-ajena')),
  expect: () => [
    isA<MovementDetailState>()
        .having((s) => s.status, 'status', MovementDetailStatus.loading),
    isA<MovementDetailState>()
        .having((s) => s.status, 'status', MovementDetailStatus.error),
  ],
);
```

> El id `tx-demo-1` debe existir en `MemoryAccountRepository` (Tarea 11) y `tx-ajena` no. Si los ids de los movimientos en memoria son otros, usa los reales en lugar de inventar unos nuevos.

- [ ] **Step 2: Ejecutar y ver que fallan**

```bash
cd apps/mobile && flutter test test/feature/beneficiary/ test/presentation/movement/
```

Expected: FAIL.

- [ ] **Step 3: Escribir la feature y las pantallas**

`feature/beneficiary` siguiendo la plantilla de `feature/auth`. `FrequentRow` en `recipient_screen` rellena el DNI al tocar un frecuente. El interruptor "guardar como frecuente" de `amount_screen` llama a `guardar` después de un envío exitoso, nunca antes: guardar un destinatario de una operación que falló es basura en la lista.

`ReceiptCard` se extrae de `receipt_screen` para que la constancia inmediata y el detalle histórico sean el mismo widget. Compartir usa `share_plus`, que ya está en `pubspec.yaml`, con el resumen en texto; el render a imagen es opcional y se deja fuera si complica.

- [ ] **Step 4: Regenerar, ejecutar y commit**

```bash
cd apps/mobile && flutter gen-l10n --arb-dir="lib/l10n/arb" && flutter test
cd /Users/jairconislla/Projects/cuycash && flutter analyze
git add apps/mobile
git commit -m "feat(app): beneficiarios frecuentes, detalle de movimiento y constancia compartible"
```

---

### Tarea 17: Cierre — documentación y verificación de punta a punta

**Files:**
- Modify: `CLAUDE.md`, `docs/modelo-datos.md`, `README.md`

- [ ] **Step 1: Actualizar `CLAUDE.md`**

- La tabla de estructura: `services/api` → `services/api`, y qué es ahora.
- La frase "Cuentas, transferencias, préstamos, QR, conciliación y antifraude **no existen todavía**" deja de ser cierta a medias: reescribirla para decir qué hay ya (cuentas, libro mayor, envío por DNI, recarga) y qué sigue sin existir (interbancaria, CCI, QR, préstamos, antifraude, conciliación).
- Añadir a "Reglas duras": *el dinero es un `int` de céntimos envuelto en `Money`; ningún `double` representa dinero*.
- Features actuales: añadir `account`, `transfer`, `beneficiary`.
- Comandos: cómo recrear el esquema.

- [ ] **Step 2: Actualizar `docs/modelo-datos.md`**

La tabla de estado por épica: la 3 pasa de "Diseñada" a "Parcial" (transferencia entre cuentas CuyCash implementada; interbancaria y antifraude pendientes). Añadir `beneficiaries` y `transfers` al listado de tablas implementadas, con las columnas reales.

- [ ] **Step 3: Verificación completa**

```bash
cd /Users/jairconislla/Projects/cuycash
flutter analyze
flutter test
cd services/api && .venv/bin/python -m pytest -q
```

Expected: cero issues, toda la suite en verde, un solo SKIPPED (el test de concurrencia que exige Postgres).

- [ ] **Step 4: Prueba manual contra el backend**

```bash
cd services/api && .venv/bin/python scripts/reset_schema.py
# arrancar el servicio como lo hace render.yaml / el README
cd ../../apps/mobile
flutter run --flavor local -t lib/main_local.dart --dart-define-from-file=config.local.json
```

Registrar **dos** cuentas desde la app (hacen falta dos para demostrar un envío), recargar la primera, enviarle dinero a la segunda, y comprobar que el saldo de ambas y los dos historiales cuadran. Es la demo del sprint: si esto no funciona de corrido, el sprint no está hecho.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md docs README.md
git commit -m "docs: actualizar estado tras el sprint de cuentas y transferencias"
```
