# Multicuenta — Entrega 1: Backend — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que `services/api` permita a un titular abrir varias cuentas (tipo, moneda, nombre), enviar a una cuenta concreta (no a un DNI), recargar en soles o dólares y guardar frecuentes por cuenta.

**Architecture:** El modelo `accounts` gana `nombre`, `idempotency_key` y el tipo `sueldo`; `beneficiaries` pasa a apuntar a una cuenta. Las rutas cambian de forma (`resolve` devuelve una lista de cuentas, `/transfers` recibe `cuenta_destino_id`) y aparecen `POST /v1/accounts` y `PATCH /v1/accounts/{id}/nombre`. La autorización por PIN de operaciones sale de `transfers.py` a un servicio para que la reutilice la apertura de cuentas.

**Tech Stack:** FastAPI, SQLAlchemy 2 async, Pydantic v2, pytest + pytest-asyncio, SQLite en tests (Postgres en producción).

**Spec:** `docs/superpowers/specs/2026-10-06-multicuenta-y-envio-por-cuenta-design.md` (§1 y §4).

**Entregas hermanas:** `2026-10-06-multicuenta-2-app-cuentas.md`, `2026-10-06-multicuenta-3-app-envio.md`. Esta va primero: las otras dos consumen su contrato.

## Global Constraints

- Dinero: `BIGINT` de céntimos y `StrictInt` en los payloads. Nunca `float`.
- Toda escritura de dinero pasa por `app/services/ledger.py` con `idempotency_key`.
- Monedas: `PEN`, `USD`. Tipos de titular: `ahorro`, `corriente`, `sueldo`. `sistema` solo para cajas.
- Tope: 5 cuentas por titular (cuentan todas, incluidas cerradas). Una sola `sueldo` por titular, solo `PEN`.
- `nombre`: opcional, se recorta, vacío = `null`, máximo 30 caracteres, solo lo ve su titular.
- Cajas: `PEN` = `19100000000000`, `USD` = `19100000000001`. Ningún titular recibe esos números.
- Rango de montos: 1..200 000 céntimos en cualquier moneda.
- Errores por `code` estable (`ApiError`), nunca por texto. Códigos nuevos: `ACCOUNT_LIMIT_REACHED`, `SALARY_ACCOUNT_EXISTS`, `INVALID_ACCOUNT_CURRENCY`, `INVALID_ACCOUNT_NAME`, `CURRENCY_MISMATCH`, `SAME_ACCOUNT`. Se elimina `SELF_TRANSFER`.
- Comentarios y nombres en español, con la densidad de comentario del archivo que se toca.
- Cada task termina con `.venv/bin/python -m pytest -q` en verde (desde `services/api`).

## Review Focus

1. **Reintento de apertura con datos distintos** (misma `idempotency_key`, otro `tipo`): debe dar `IDEMPOTENCY_KEY_REUSED` 409, no devolver la cuenta vieja como si fuera la pedida. → test en Task 3.
2. **Clave de apertura de otro titular**: la misma `idempotency_key` usada por dos titulares distintos debe crear dos cuentas (la unicidad es por titular). → test en Task 3.
3. **Frecuente que apunta a una cuenta cerrada después**: `GET /v1/beneficiaries` responde `cuenta: null` y no se cae ni omite la fila. → test en Task 6.
4. **Envío a una cuenta de sistema por id** (alguien adivina el id de la caja): `RECIPIENT_NOT_FOUND`, igual que una inexistente. → test en Task 5.
5. **Reintento de envío con otra `cuenta_destino_id` de la MISMA persona**: 409 `IDEMPOTENCY_KEY_REUSED` (antes se comparaba por DNI y dos cuentas del mismo DNI habrían pasado). → test en Task 5.

---

## Task 0: Limpiar el árbol de trabajo

El árbol tiene sin commitear un intento anterior (rediseño parcial del envío + `dart format` sobre ~100 archivos ajenos). Se guarda y se descarta.

**Files:** ninguno nuevo.

- [ ] **Step 1: Confirmar la rama**

Run: `cd /Users/jairconislla/Projects/cuycash && git branch --show-current`
Expected: `feat/multicuenta-y-envio-por-cuenta`

- [ ] **Step 2: Guardar el intento anterior en un stash con nombre**

Run: `git stash push -m "intento-previo-envio-por-cuenta (descartado, ver spec 2026-10-06)" -- apps services`
Expected: `Saved working directory and index state On feat/multicuenta-y-envio-por-cuenta: intento-previo-...`

- [ ] **Step 3: Verificar que el árbol quedó limpio y la base pasa**

Run: `git status --short && (cd services/api && .venv/bin/python -m pytest -q 2>&1 | tail -2)`
Expected: `git status` vacío; pytest `passed` sin fallos.

No hay commit en esta task.

---

## Task 1: Modelo — cuentas con nombre, sueldo y clave; frecuentes por cuenta; cajas por moneda

**Files:**
- Modify: `services/api/app/db/models.py` (clase `Account` ~195-245, clase `Beneficiary` ~329-345)
- Modify: `services/api/app/core/errors.py` (clase `ErrorCode`)
- Modify: `services/api/app/services/accounts.py` (todo el archivo)
- Modify: `services/api/tests/test_transferencias.py:406-450` (el test que ciega `_buscar_caja`)
- Create: `services/api/tests/test_modelo_multicuenta.py`

**Interfaces:**
- Produces:
  - `Account.nombre: Optional[str]`, `Account.idempotency_key: Optional[str]`.
  - `Beneficiary.cuenta_destino_id: str` (FK `accounts.id`).
  - `accounts.MAX_CUENTAS = 5`, `accounts.NUMEROS_SISTEMA: dict[str, str]`, `accounts.NUMERO_SISTEMA` (= el de PEN, se conserva).
  - `async def abrir_cuenta(session, user_id, *, tipo="ahorro", moneda="PEN", nombre=None, idempotency_key=None) -> Account`
  - `async def cuenta_de_sistema(session, moneda: str = "PEN") -> Account`
  - `async def _buscar_caja(session, moneda: str = "PEN") -> Optional[Account]`
  - `ErrorCode.ACCOUNT_LIMIT_REACHED`, `SALARY_ACCOUNT_EXISTS`, `INVALID_ACCOUNT_CURRENCY`, `INVALID_ACCOUNT_NAME`, `CURRENCY_MISMATCH`, `SAME_ACCOUNT`.

- [ ] **Step 1: Escribir los tests del modelo**

Create `services/api/tests/test_modelo_multicuenta.py`:

```python
"""
Restricciones de la base para la multicuenta.

Se prueban contra el esquema (fixture `db`) y no por HTTP: lo que importa es
que la BASE rechace lo inválido aunque un router futuro se olvide de validar.
"""

import pytest
from sqlalchemy.exc import IntegrityError

from app.db.models import Account, Beneficiary, User
from app.services import accounts


async def _titular(db, dni="70000009") -> User:
    u = User(
        dni=dni,
        nombres="Ana",
        apellidos="Rojas",
        email=f"{dni}@correo.pe",
        pin_hash="x",
        alias=f"@ana{dni}",
    )
    db.add(u)
    await db.flush()
    return u


@pytest.mark.asyncio
async def test_una_cuenta_sueldo_en_dolares_es_rechazada_por_la_base(db):
    u = await _titular(db)
    db.add(Account(user_id=u.id, numero="19111111111111", tipo="sueldo", moneda="USD"))
    with pytest.raises(IntegrityError):
        await db.flush()


@pytest.mark.asyncio
async def test_dos_cuentas_sueldo_del_mismo_titular_son_rechazadas_por_la_base(db):
    u = await _titular(db)
    db.add(Account(user_id=u.id, numero="19111111111111", tipo="sueldo", moneda="PEN"))
    await db.flush()
    db.add(Account(user_id=u.id, numero="19122222222222", tipo="sueldo", moneda="PEN"))
    with pytest.raises(IntegrityError):
        await db.flush()


@pytest.mark.asyncio
async def test_la_misma_clave_de_apertura_en_dos_titulares_se_acepta(db):
    a = await _titular(db, "70000010")
    b = await _titular(db, "70000011")
    db.add(Account(user_id=a.id, numero="19111111111111", idempotency_key="clave-0001"))
    db.add(Account(user_id=b.id, numero="19122222222222", idempotency_key="clave-0001"))
    await db.flush()  # no lanza: la unicidad es por titular


@pytest.mark.asyncio
async def test_abrir_cuenta_guarda_tipo_moneda_y_nombre(db):
    u = await _titular(db)
    c = await accounts.abrir_cuenta(
        db, u.id, tipo="corriente", moneda="USD", nombre="Viaje", idempotency_key="k-000001"
    )
    assert (c.tipo, c.moneda, c.nombre, c.idempotency_key) == (
        "corriente", "USD", "Viaje", "k-000001"
    )
    assert c.saldo_disponible == 0


@pytest.mark.asyncio
async def test_hay_una_caja_por_moneda(db):
    pen = await accounts.cuenta_de_sistema(db, "PEN")
    usd = await accounts.cuenta_de_sistema(db, "USD")
    assert pen.id != usd.id
    assert (pen.numero, pen.moneda) == ("19100000000000", "PEN")
    assert (usd.numero, usd.moneda) == ("19100000000001", "USD")
    assert (await accounts.cuenta_de_sistema(db, "USD")).id == usd.id


@pytest.mark.asyncio
async def test_generar_numero_nunca_da_el_de_una_caja(db, monkeypatch):
    # Forzar que el primer candidato sea el de la caja USD.
    digitos = iter("00000000001" + "12345678901")
    monkeypatch.setattr(accounts.secrets, "randbelow", lambda _: int(next(digitos)))
    assert await accounts.generar_numero(db) == "19112345678901"


@pytest.mark.asyncio
async def test_un_frecuente_apunta_a_una_cuenta_y_no_se_repite(db):
    u = await _titular(db, "70000012")
    otro = await _titular(db, "70000013")
    c1 = await accounts.abrir_cuenta(db, otro.id)
    c2 = await accounts.abrir_cuenta(db, otro.id, tipo="corriente")
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c1.id, apodo="A"))
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c2.id, apodo="B"))
    await db.flush()  # dos cuentas de la misma persona: válido
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c1.id, apodo="C"))
    with pytest.raises(IntegrityError):
        await db.flush()
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `cd services/api && .venv/bin/python -m pytest tests/test_modelo_multicuenta.py -q`
Expected: FAIL (`TypeError: 'nombre' is an invalid keyword argument`, `cuenta_destino_id` inválido, etc.).

- [ ] **Step 3: Cambiar el modelo `Account`**

En `app/db/models.py`, importar `text` de `sqlalchemy` y, en `Account`, después de `estado`:

```python
    # Lo pone el titular ("Viaje"); solo lo ve él. Quien le envía dinero ve el
    # tipo y la moneda, nunca esto.
    nombre: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    # Clave de la petición que abrió la cuenta: un reintento con la misma clave
    # devuelve esta cuenta en vez de abrir otra. `None` en la de registro y en
    # las cajas.
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
```

Reemplazar el `CheckConstraint` de `tipo` y añadir los nuevos en `__table_args__`:

```python
        CheckConstraint(
            "tipo IN ('ahorro','corriente','sueldo','sistema')", name="ck_accounts_tipo"
        ),
        # La cuenta sueldo existe para recibir la planilla, que en Perú se paga
        # en soles.
        CheckConstraint(
            "tipo <> 'sueldo' OR moneda = 'PEN'", name="ck_accounts_sueldo_en_soles"
        ),
        # Una sueldo por titular. Índice parcial y no regla del servicio: dos
        # aperturas simultáneas verían "no hay" y abrirían dos.
        Index(
            "ux_accounts_un_sueldo",
            "user_id",
            unique=True,
            sqlite_where=text("tipo = 'sueldo'"),
            postgresql_where=text("tipo = 'sueldo'"),
        ),
        # La clave de apertura es única POR TITULAR: la de otro no debe chocar.
        UniqueConstraint("user_id", "idempotency_key", name="uq_accounts_clave_apertura"),
```

(conservar los demás `CheckConstraint` existentes tal cual).

- [ ] **Step 4: Cambiar el modelo `Beneficiary`**

```python
class Beneficiary(Base):
    """
    Una CUENTA guardada por un titular, con un apodo.

    Se guarda la cuenta y no solo el DNI porque una persona puede tener varias:
    el frecuente es "la de ahorros en soles de Luis", no "Luis". El DNI se
    conserva para pintar y para volver a buscar si esa cuenta deja de recibir.
    El nombre y el número enmascarado se calculan al leer.
    """

    __tablename__ = "beneficiaries"
    __table_args__ = (
        UniqueConstraint("user_id", "cuenta_destino_id", name="uq_beneficiaries_user_cuenta"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    beneficiario_dni: Mapped[str] = mapped_column(String(8), index=True)
    cuenta_destino_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    apodo: Mapped[str] = mapped_column(String(40))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
```

- [ ] **Step 5: Códigos de error**

En `app/core/errors.py`, dentro de `ErrorCode`, borrar `SELF_TRANSFER` y añadir:

```python
    ACCOUNT_LIMIT_REACHED = "ACCOUNT_LIMIT_REACHED"
    SALARY_ACCOUNT_EXISTS = "SALARY_ACCOUNT_EXISTS"
    INVALID_ACCOUNT_CURRENCY = "INVALID_ACCOUNT_CURRENCY"
    INVALID_ACCOUNT_NAME = "INVALID_ACCOUNT_NAME"
    CURRENCY_MISMATCH = "CURRENCY_MISMATCH"
    SAME_ACCOUNT = "SAME_ACCOUNT"
```

> `SELF_TRANSFER` todavía se usa en `directory.py` y `transfers.py`; las Tasks 4–6 lo quitan. Para que esta task compile, **déjalo por ahora** y bórralo en la Task 6 (Step final). Anota esto en el commit.

- [ ] **Step 6: Servicio de cuentas**

Reemplazar en `app/services/accounts.py`:

```python
# Prefijo de CuyCash. El resto es aleatorio: derivar el número del DNI haría
# que publicar una cuenta publicara el documento de su titular.
PREFIJO = "191"
# Una caja por moneda: el libro cuadra por moneda y una recarga en dólares no
# puede salir de la caja de soles.
NUMEROS_SISTEMA = {"PEN": "19100000000000", "USD": "19100000000001"}
NUMERO_SISTEMA = NUMEROS_SISTEMA["PEN"]
MAX_CUENTAS = 5


async def generar_numero(session: AsyncSession) -> str:
    """14 dígitos: prefijo + 11 aleatorios, reintentando ante colisión."""
    for _ in range(20):
        candidato = PREFIJO + "".join(str(secrets.randbelow(10)) for _ in range(11))
        # Reservados: los números fijos de las cajas. Si un titular recibiera
        # uno, crear esa caja chocaría después contra la UNIQUE sin pista.
        if candidato in NUMEROS_SISTEMA.values():
            continue
        existe = (
            await session.execute(select(Account.id).where(Account.numero == candidato))
        ).scalar_one_or_none()
        if existe is None:
            return candidato
    raise RuntimeError("No se pudo generar un número de cuenta libre")


async def abrir_cuenta(
    session: AsyncSession,
    user_id: str,
    *,
    tipo: str = "ahorro",
    moneda: str = "PEN",
    nombre: Optional[str] = None,
    idempotency_key: Optional[str] = None,
) -> Account:
    """Cuenta activa y en cero. No valida reglas de negocio ni hace commit."""
    cuenta = Account(
        user_id=user_id,
        numero=await generar_numero(session),
        tipo=tipo,
        moneda=moneda,
        estado="activa",
        nombre=nombre,
        idempotency_key=idempotency_key,
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(cuenta)
    await session.flush()
    return cuenta


async def _buscar_caja(session: AsyncSession, moneda: str = "PEN") -> Optional[Account]:
    # Por `numero` y no por `tipo`: la UNIQUE de `numero` es lo que de verdad
    # impide una segunda caja, y así la búsqueda es coherente con ella.
    return (
        await session.execute(
            select(Account).where(Account.numero == NUMEROS_SISTEMA[moneda])
        )
    ).scalar_one_or_none()
```

y en `cuenta_de_sistema` cambiar la firma a `async def cuenta_de_sistema(session: AsyncSession, moneda: str = "PEN") -> Account:`, pasar `moneda` a cada `_buscar_caja(session, moneda)` y crear la caja con `numero=NUMEROS_SISTEMA[moneda]` y `moneda=moneda`. Actualizar el docstring: "La caja de CuyCash en esa moneda".

- [ ] **Step 7: Ajustar el test que ciega `_buscar_caja`**

En `tests/test_transferencias.py` (test `test_si_otra_peticion_crea_la_caja_a_la_vez_la_sesion_sigue_sirviendo`), la función de reemplazo debe aceptar la moneda:

```python
    async def ciega_la_primera_vez(session, moneda="PEN"):
        llamadas.append(1)
        return None if len(llamadas) == 1 else await real(session, moneda)
```

- [ ] **Step 8: Correr toda la suite**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: los 7 tests nuevos PASS. Fallan los tests de frecuentes que insertan `Beneficiary` sin `cuenta_destino_id` (por HTTP, `POST /v1/beneficiaries`): es esperado, la Task 6 los reescribe. Anota cuántos fallan y que todos son de `test_directorio_y_frecuentes.py` frecuentes; si falla cualquier otro, arréglalo antes de seguir.

> Para no dejar la rama roja entre tasks, en este step marca esos tests con `@pytest.mark.skip(reason="Task 6: frecuentes por cuenta")`. La Task 6 quita los `skip`.

- [ ] **Step 9: Commit**

```bash
git add services/api/app/db/models.py services/api/app/core/errors.py services/api/app/services/accounts.py services/api/tests/test_modelo_multicuenta.py services/api/tests/test_transferencias.py services/api/tests/test_directorio_y_frecuentes.py
git commit -m "feat(api): modelo multicuenta: nombre, sueldo, clave de apertura, cajas por moneda y frecuentes por cuenta"
```

---

## Task 2: Autorización por PIN como servicio compartido

`_exigir_pin` vive en `transfers.py`; la apertura de cuentas (en `accounts.py`) la necesita, y `transfers.py` ya importa de `accounts.py` (`_iso`), así que importarla al revés crearía un ciclo.

**Files:**
- Create: `services/api/app/services/autorizacion.py`
- Modify: `services/api/app/api/v1/routers/transfers.py` (borrar `_bloqueado` y `_exigir_pin` ~170-235; usar el servicio)

**Interfaces:**
- Produces: `async def exigir_pin_de_operacion(session, user: User, device_id: str, pin: str) -> None` en `app.services.autorizacion`. Mismo comportamiento exacto que el `_exigir_pin` actual (403 `INVALID_CREDENTIALS` con `intentos_restantes`, 423 `IDENTIFIER_LOCKED`/`DEVICE_LOCKED` con `locked_until`).

- [ ] **Step 1: Crear el servicio moviendo el código**

Create `app/services/autorizacion.py` con el docstring de módulo:

```python
"""
Autorizar con el PIN una operación de un titular con sesión (mover dinero,
abrir una cuenta).

Los fallos alimentan el MISMO bloqueo que el login (sujeto `dni`, y de paso el
del dispositivo): se agotan los intentos se gasten entrando u operando.
"""
```

y debajo, **copiadas sin cambios de lógica**, las funciones `_bloqueado` y `_exigir_pin` de `transfers.py`, renombrando `_exigir_pin` a `exigir_pin_de_operacion`. Imports necesarios: `status` de fastapi, `AsyncSession`, `ApiError`, `ErrorCode`, `averify_pin`, `User`, `lockout`.

- [ ] **Step 2: Usarlo en `transfers.py`**

Borrar `_bloqueado` y `_exigir_pin` de `transfers.py`, añadir `from app.services.autorizacion import exigir_pin_de_operacion` y reemplazar las dos llamadas `await _exigir_pin(session, user, sesion.device_id, payload.pin)` por `await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)`. Quitar imports que queden sin uso (`averify_pin`, `lockout`).

- [ ] **Step 3: La suite sigue igual**

Run: `cd services/api && .venv/bin/python -m pytest -q`
Expected: mismo resultado que al final de la Task 1 (todo verde salvo los `skip`).

- [ ] **Step 4: Commit**

```bash
git add services/api/app/services/autorizacion.py services/api/app/api/v1/routers/transfers.py
git commit -m "refactor(api): la autorización por PIN de operaciones pasa a un servicio"
```

---

## Task 3: Abrir cuenta y cambiarle el nombre

**Files:**
- Modify: `services/api/app/api/v1/routers/accounts.py` (`_cuenta_json`, nuevas rutas)
- Create: `services/api/tests/test_abrir_y_renombrar_cuenta.py`

**Interfaces:**
- Consumes: `accounts.abrir_cuenta`, `accounts.MAX_CUENTAS`, `exigir_pin_de_operacion`, `current_session_row`.
- Produces (contrato HTTP):
  - `POST /v1/accounts` body `{tipo, moneda, nombre?, pin, idempotency_key}` → `201` cuenta nueva | `200` reintento.
  - `PATCH /v1/accounts/{id}/nombre` body `{nombre: str|null}` → `200` cuenta.
  - Forma de cuenta (también en `GET /v1/accounts`): `{id, numero, tipo, moneda, estado, nombre, saldo_disponible, saldo_contable}`.

- [ ] **Step 1: Escribir los tests**

Create `tests/test_abrir_y_renombrar_cuenta.py`:

```python
"""
Abrir otra cuenta desde la app y ponerle nombre.

Abrir cuenta pide PIN e idempotencia como mover dinero: un doble toque o un
reintento tras perder la respuesta no debe dejar al titular con dos cuentas.
"""

import asyncio

import pytest

from tests.conftest import PIN_DE_PRUEBA, registrar

PIN = PIN_DE_PRUEBA


def _abrir(tipo="ahorro", moneda="PEN", nombre=None, clave="abrir-0001", pin=PIN):
    return {
        "tipo": tipo,
        "moneda": moneda,
        "nombre": nombre,
        "pin": pin,
        "idempotency_key": clave,
    }


async def _cuentas(client, titular):
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"]


@pytest.mark.asyncio
async def test_abrir_una_cuenta_en_dolares_con_nombre(client, registrado):
    r = await client.post(
        "/v1/accounts", json=_abrir("corriente", "USD", "  Viaje  "), headers=registrado.auth
    )
    assert r.status_code == 201, r.text
    c = r.json()
    assert (c["tipo"], c["moneda"], c["nombre"], c["estado"]) == (
        "corriente", "USD", "Viaje", "activa"
    )
    assert c["saldo_disponible"] == 0
    assert len(await _cuentas(client, registrado)) == 2


@pytest.mark.asyncio
async def test_get_accounts_trae_el_nombre(client, registrado):
    cuentas = await _cuentas(client, registrado)
    assert cuentas[0]["nombre"] is None


@pytest.mark.asyncio
async def test_reintentar_con_la_misma_clave_devuelve_la_misma_cuenta(client, registrado):
    a = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    assert (a.status_code, b.status_code) == (201, 200)
    assert a.json()["id"] == b.json()["id"]
    assert len(await _cuentas(client, registrado)) == 2


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_tipo_es_409(client, registrado):
    await client.post("/v1/accounts", json=_abrir("ahorro"), headers=registrado.auth)
    r = await client.post("/v1/accounts", json=_abrir("corriente"), headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_la_misma_clave_en_otro_titular_abre_su_propia_cuenta(
    client, registrado, otro_registrado
):
    a = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir(), headers=otro_registrado.auth)
    assert (a.status_code, b.status_code) == (201, 201)
    assert a.json()["id"] != b.json()["id"]


@pytest.mark.asyncio
async def test_el_tope_es_de_cinco_cuentas(client, registrado):
    for i in range(4):  # ya tiene 1 por el registro
        r = await client.post(
            "/v1/accounts", json=_abrir(clave=f"abrir-tope-{i}"), headers=registrado.auth
        )
        assert r.status_code == 201
    r = await client.post("/v1/accounts", json=_abrir(clave="abrir-tope-x"), headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "ACCOUNT_LIMIT_REACHED"


@pytest.mark.asyncio
async def test_solo_una_cuenta_sueldo(client, registrado):
    a = await client.post("/v1/accounts", json=_abrir("sueldo", clave="s-0000001"), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir("sueldo", clave="s-0000002"), headers=registrado.auth)
    assert a.status_code == 201
    assert b.status_code == 409
    assert b.json()["code"] == "SALARY_ACCOUNT_EXISTS"


@pytest.mark.asyncio
async def test_sueldo_en_dolares_se_rechaza(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir("sueldo", "USD"), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "INVALID_ACCOUNT_CURRENCY"


@pytest.mark.asyncio
@pytest.mark.parametrize("nombre", ["x" * 31, "a\nb"])
async def test_un_nombre_invalido_se_rechaza(client, registrado, nombre):
    r = await client.post("/v1/accounts", json=_abrir(nombre=nombre), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "INVALID_ACCOUNT_NAME"


@pytest.mark.asyncio
async def test_un_tipo_o_moneda_desconocidos_son_422(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir("cts"), headers=registrado.auth)
    assert r.status_code == 422
    r = await client.post("/v1/accounts", json=_abrir(moneda="EUR"), headers=registrado.auth)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_pin_errado_no_abre_y_descuenta_intentos(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir(pin="000000"), headers=registrado.auth)
    assert r.status_code == 403
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert "intentos_restantes" in r.json()
    assert len(await _cuentas(client, registrado)) == 1


@pytest.mark.asyncio
async def test_abrir_exige_sesion(client):
    assert (await client.post("/v1/accounts", json=_abrir())).status_code == 401


@pytest.mark.asyncio
async def test_renombrar_una_cuenta_propia(client, registrado):
    cid = (await _cuentas(client, registrado))[0]["id"]
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": " Casa "}, headers=registrado.auth
    )
    assert r.status_code == 200
    assert r.json()["nombre"] == "Casa"
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": "   "}, headers=registrado.auth
    )
    assert r.json()["nombre"] is None


@pytest.mark.asyncio
async def test_renombrar_una_cuenta_ajena_es_404(client, registrado, otro_registrado):
    cid = (await _cuentas(client, otro_registrado))[0]["id"]
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": "Mía"}, headers=registrado.auth
    )
    assert r.status_code == 404
    assert r.json()["code"] == "ACCOUNT_NOT_FOUND"


@pytest.mark.asyncio
async def test_dos_aperturas_de_sueldo_a_la_vez_dejan_una(client, registrado):
    """En SQLite las peticiones se serializan; la garantía real la da el índice
    parcial y se prueba contra Postgres en `test_concurrencia_multicuenta.py`."""
    respuestas = await asyncio.gather(
        *[
            client.post(
                "/v1/accounts", json=_abrir("sueldo", clave=f"sueldo-par-{i}"), headers=registrado.auth
            )
            for i in range(2)
        ]
    )
    assert sorted(r.status_code for r in respuestas) == [201, 409]
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `.venv/bin/python -m pytest tests/test_abrir_y_renombrar_cuenta.py -q`
Expected: FAIL (405 Method Not Allowed en `POST /v1/accounts`).

- [ ] **Step 3: Implementar en `accounts.py`**

Añadir `nombre` a `_cuenta_json`:

```python
        "nombre": c.nombre,
```

Imports nuevos: `from typing import Literal`, `from fastapi import Response`, `from pydantic import BaseModel, Field`, `from sqlalchemy import func`, `from sqlalchemy.exc import IntegrityError`, `from app.core.deps import current_session_row`, `from app.db.models import Session as SessionRow`, `from app.services import accounts as accounts_service`, `from app.services.autorizacion import exigir_pin_de_operacion`.

Código nuevo (al final del archivo):

```python
NOMBRE_MAXIMO = 30


class AbrirCuentaIn(BaseModel):
    tipo: Literal["ahorro", "corriente", "sueldo"]
    moneda: Literal["PEN", "USD"]
    # Holgado a propósito: la regla real (≤ 30 tras recortar, sin saltos de
    # línea) la aplica `_nombre`, para responder INVALID_ACCOUNT_NAME y no 422.
    nombre: Optional[str] = Field(default=None, max_length=200)
    pin: str
    idempotency_key: str = Field(min_length=8, max_length=64)


class NombreIn(BaseModel):
    nombre: Optional[str] = Field(default=None, max_length=200)


def _nombre(crudo: Optional[str]) -> Optional[str]:
    """Recortado; vacío es `None`. Más de 30 o con saltos de línea, error."""
    limpio = (crudo or "").strip()
    if not limpio:
        return None
    if len(limpio) > NOMBRE_MAXIMO or any(c in limpio for c in "\r\n\t"):
        raise ApiError(
            ErrorCode.INVALID_ACCOUNT_NAME,
            f"El nombre puede tener hasta {NOMBRE_MAXIMO} caracteres.",
        )
    return limpio


@router.post("/accounts", status_code=status.HTTP_201_CREATED)
async def abrir_cuenta(
    payload: AbrirCuentaIn,
    response: Response,
    user: User = Depends(current_user),
    sesion: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    """
    Abre otra cuenta del titular. Pide PIN, como mover dinero.

    Orden: validar el nombre, reintento idempotente, reglas de tipo y moneda,
    tope y sueldo única (con la fila del titular bloqueada), y el PIN EL ÚLTIMO
    para no gastar intentos en peticiones que iban a fallar igual.
    """
    nombre = _nombre(payload.nombre)

    previa = (
        await session.execute(
            select(Account).where(
                Account.user_id == user.id,
                Account.idempotency_key == payload.idempotency_key,
            )
        )
    ).scalar_one_or_none()
    if previa is not None:
        if (previa.tipo, previa.moneda, previa.nombre) != (payload.tipo, payload.moneda, nombre):
            raise ApiError(
                ErrorCode.IDEMPOTENCY_KEY_REUSED,
                "Esa apertura ya se pidió con otros datos. Vuelve a empezar.",
                status_code=status.HTTP_409_CONFLICT,
            )
        response.status_code = status.HTTP_200_OK
        return _cuenta_json(previa)

    if payload.tipo == "sueldo" and payload.moneda != "PEN":
        raise ApiError(
            ErrorCode.INVALID_ACCOUNT_CURRENCY,
            "La cuenta sueldo solo puede ser en soles.",
        )

    # Serializa las aperturas del MISMO titular: sin esto, dos peticiones a la
    # vez contarían 4 cuentas cada una y abrirían la 5.ª y la 6.ª. SQLite
    # ignora FOR UPDATE (allí las escrituras ya se serializan).
    await session.execute(select(User.id).where(User.id == user.id).with_for_update())
    cuantas = (
        await session.execute(
            select(func.count()).select_from(Account).where(Account.user_id == user.id)
        )
    ).scalar_one()
    if cuantas >= accounts_service.MAX_CUENTAS:
        raise ApiError(
            ErrorCode.ACCOUNT_LIMIT_REACHED,
            f"Puedes tener hasta {accounts_service.MAX_CUENTAS} cuentas.",
            status_code=status.HTTP_409_CONFLICT,
        )
    if payload.tipo == "sueldo":
        ya_hay = (
            await session.execute(
                select(Account.id).where(Account.user_id == user.id, Account.tipo == "sueldo")
            )
        ).first()
        if ya_hay is not None:
            raise _sueldo_repetida()

    await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)

    try:
        async with session.begin_nested():
            cuenta = await accounts_service.abrir_cuenta(
                session,
                user.id,
                tipo=payload.tipo,
                moneda=payload.moneda,
                nombre=nombre,
                idempotency_key=payload.idempotency_key,
            )
    except IntegrityError:
        # Otra apertura de sueldo ganó la carrera: el índice parcial la frenó.
        raise _sueldo_repetida()
    cuerpo = _cuenta_json(cuenta)
    await session.commit()
    return cuerpo


def _sueldo_repetida() -> ApiError:
    return ApiError(
        ErrorCode.SALARY_ACCOUNT_EXISTS,
        "Ya tienes una cuenta sueldo.",
        status_code=status.HTTP_409_CONFLICT,
    )


@router.patch("/accounts/{cuenta_id}/nombre")
async def renombrar_cuenta(
    cuenta_id: str,
    payload: NombreIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """Sin PIN: no mueve dinero y el nombre solo lo ve su titular."""
    nombre = _nombre(payload.nombre)
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
    cuenta.nombre = nombre
    cuerpo = _cuenta_json(cuenta)
    await session.commit()
    return cuerpo
```

> `IntegrityError` dentro de `begin_nested` deshace solo el SAVEPOINT; la sesión sigue usable para responder. Si `exigir_pin_de_operacion` hizo `register_success` antes, ese cambio sigue en la transacción externa y no se commitea en la rama de error: es correcto (no hubo operación).

- [ ] **Step 4: Correr los tests nuevos y toda la suite**

Run: `.venv/bin/python -m pytest tests/test_abrir_y_renombrar_cuenta.py -q && .venv/bin/python -m pytest -q`
Expected: PASS. Si `test_dos_aperturas_de_sueldo_a_la_vez_dejan_una` falla por el orden de SQLite, revisa que la segunda petición vea la primera (el fixture usa una conexión `StaticPool`); no lo borres.

- [ ] **Step 5: Commit**

```bash
git add services/api/app/api/v1/routers/accounts.py services/api/tests/test_abrir_y_renombrar_cuenta.py
git commit -m "feat(api): abrir otra cuenta (tipo, moneda, nombre) con PIN e idempotencia, y renombrarla"
```

---

## Task 4: `resolve` devuelve todas las cuentas del DNI

**Files:**
- Modify: `services/api/app/api/v1/routers/directory.py` (`_destinatario`, `resolver`)
- Modify: `services/api/tests/test_directorio_y_frecuentes.py` (tests de `resolve`)

**Interfaces:**
- Produces:
  - `def cuenta_publica_json(c: Account, *, propia: bool) -> dict` en `directory.py` → `{cuenta_id, tipo, moneda, numero_masked, nombre}` (`nombre` solo si `propia`).
  - `async def _destinatario(session, dni) -> Tuple[User, List[Account]]` — cuentas activas, no sistema, ordenadas por `created_at, id`; 404 `RECIPIENT_NOT_FOUND` si no hay ninguna.
  - `GET /v1/directory/resolve` → `{dni, nombre_enmascarado, cuentas: [...]}`.

- [ ] **Step 1: Reescribir los tests de resolve**

En `tests/test_directorio_y_frecuentes.py`:

Reemplazar `test_resolver_devuelve_el_nombre_enmascarado` por:

```python
@pytest.mark.asyncio
async def test_resolver_devuelve_el_nombre_enmascarado_y_sus_cuentas(
    client, registrado, otro_registrado
):
    r = await _resolver(client, registrado, otro_registrado.dni)
    cuerpo = r.json()

    assert r.status_code == 200
    assert cuerpo["nombre_enmascarado"] == "L*** A*** Q***"
    assert "Luis" not in str(cuerpo)
    assert "Quispe" not in str(cuerpo)
    [cuenta] = cuerpo["cuentas"]
    assert cuenta["tipo"] == "ahorro"
    assert cuenta["moneda"] == "PEN"
    assert cuenta["numero_masked"].startswith("••••")
    assert len(cuenta["numero_masked"]) == 8
    assert cuenta["nombre"] is None
    assert set(cuenta) == {"cuenta_id", "tipo", "moneda", "numero_masked", "nombre"}


@pytest.mark.asyncio
async def test_resolver_lista_todas_las_cuentas_activas_en_orden(
    client, registrado, otro_registrado
):
    for clave, tipo, moneda in (("r-000001", "corriente", "USD"), ("r-000002", "sueldo", "PEN")):
        r = await client.post(
            "/v1/accounts",
            json={"tipo": tipo, "moneda": moneda, "nombre": "Secreto", "pin": PIN_DE_PRUEBA,
                  "idempotency_key": clave},
            headers=otro_registrado.auth,
        )
        assert r.status_code == 201
    cuentas = (await _resolver(client, registrado, otro_registrado.dni)).json()["cuentas"]
    assert [(c["tipo"], c["moneda"]) for c in cuentas] == [
        ("ahorro", "PEN"), ("corriente", "USD"), ("sueldo", "PEN")
    ]
    # El nombre que el otro le puso a sus cuentas no sale a terceros.
    assert all(c["nombre"] is None for c in cuentas)
    assert "Secreto" not in str(cuentas)


@pytest.mark.asyncio
async def test_resolver_el_propio_dni_lista_mis_cuentas_con_su_nombre(client, registrado):
    await client.post(
        "/v1/accounts",
        json={"tipo": "ahorro", "moneda": "USD", "nombre": "Viaje", "pin": PIN_DE_PRUEBA,
              "idempotency_key": "propia-01"},
        headers=registrado.auth,
    )
    r = await _resolver(client, registrado, registrado.dni)
    assert r.status_code == 200
    assert [c["nombre"] for c in r.json()["cuentas"]] == [None, "Viaje"]
```

Borrar `test_resolver_el_propio_dni_es_rechazado` (ya no es un error).

En `test_un_destinatario_con_la_cuenta_bloqueada_no_se_resuelve` y `..._cerrada_...` no cambia nada: el titular tiene una sola cuenta y al bloquearla no queda ninguna activa → 404. Añadir uno nuevo:

```python
@pytest.mark.asyncio
async def test_una_cuenta_bloqueada_no_aparece_pero_las_demas_si(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import select, update
    from app.db.models import Account

    await client.post(
        "/v1/accounts",
        json={"tipo": "corriente", "moneda": "PEN", "pin": PIN_DE_PRUEBA,
              "idempotency_key": "bloq-0001"},
        headers=otro_registrado.auth,
    )
    await db_de_client.execute(
        update(Account)
        .where(Account.user_id == otro_registrado.user_id, Account.tipo == "ahorro")
        .values(estado="bloqueada")
    )
    await db_de_client.commit()
    cuentas = (await _resolver(client, registrado, otro_registrado.dni)).json()["cuentas"]
    assert [c["tipo"] for c in cuentas] == ["corriente"]
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `.venv/bin/python -m pytest tests/test_directorio_y_frecuentes.py -q -k resolver`
Expected: FAIL (`KeyError: 'cuentas'`, el propio DNI da 400).

- [ ] **Step 3: Implementar**

En `directory.py`, reemplazar `_destinatario` y `resolver`:

```python
def cuenta_publica_json(c: Account, *, propia: bool) -> dict:
    """
    Lo que se puede decir de una cuenta a quien quiere enviarle dinero.

    `cuenta_id` es el UUID: no revela el número completo ni el DNI. El nombre
    que el titular le puso a su cuenta es suyo: solo sale cuando la cuenta es
    del que pregunta.
    """
    return {
        "cuenta_id": c.id,
        "tipo": c.tipo,
        "moneda": c.moneda,
        "numero_masked": "••••{}".format(c.numero[-4:]),
        "nombre": c.nombre if propia else None,
    }


async def _destinatario(session: AsyncSession, dni: str) -> Tuple[User, List[Account]]:
    filas = (
        await session.execute(
            select(User, Account)
            .join(Account, Account.user_id == User.id)
            .where(
                User.dni == dni,
                Account.estado == "activa",
                Account.tipo != "sistema",
            )
            .order_by(Account.created_at, Account.id)
        )
    ).all()
    if not filas:
        # Una persona con todas sus cuentas bloqueadas o cerradas cae aquí, y
        # es lo correcto: existe pero no puede recibir, así que no es un
        # destinatario. La respuesta es idéntica a la de un DNI inexistente.
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return filas[0][0], [cuenta for _, cuenta in filas]


@router.get("/directory/resolve")
async def resolver(
    dni: str = Query(min_length=8, max_length=8, pattern=r"^\d{8}$"),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # El propio DNI ya no es un error: lista las otras cuentas del titular para
    # pasar dinero entre ellas. Igual descuenta del presupuesto, para que el
    # tope no dependa de qué DNI se teclea.
    consumir_consulta_de_destinatario(user.id)
    destinatario, cuentas = await _destinatario(session, dni)
    propia = destinatario.id == user.id
    return {
        "dni": destinatario.dni,
        "nombre_enmascarado": enmascarar(destinatario.nombres, destinatario.apellidos),
        "cuentas": [cuenta_publica_json(c, propia=propia) for c in cuentas],
    }
```

Importar `List` de `typing`. `guardar` (frecuentes) sigue llamando a `_destinatario` hasta la Task 6; ajusta esa llamada para que compile (`await _destinatario(session, payload.dni)` sigue siendo válido: ignora el retorno).

- [ ] **Step 4: Correr**

Run: `.venv/bin/python -m pytest -q`
Expected: PASS (salvo los `skip` de frecuentes).

- [ ] **Step 5: Commit**

```bash
git add services/api/app/api/v1/routers/directory.py services/api/tests/test_directorio_y_frecuentes.py
git commit -m "feat(api): resolver un DNI devuelve todas sus cuentas; el propio DNI lista las mías"
```

---

## Task 5: Enviar a una cuenta, recargar por moneda y moneda en los movimientos

**Files:**
- Modify: `services/api/app/api/v1/routers/transfers.py` (`TransferIn`, `_destino_original`, `transferir`, `recargar`)
- Modify: `services/api/app/api/v1/routers/accounts.py` (`_movimiento_json`)
- Modify: `services/api/tests/test_transferencias.py` (helper `_envio` y sus llamadas)
- Modify: `services/api/tests/test_directorio_y_frecuentes.py` (helper `_envio` y sus llamadas)
- Modify: `services/api/tests/test_cuentas_y_movimientos.py` (si llama a `/v1/transfers` con `destinatario_dni`)
- Create: `services/api/tests/test_envio_por_cuenta.py`

**Interfaces:**
- Consumes: `cuenta_de_sistema(session, moneda)`.
- Produces: `TransferIn {cuenta_origen_id, cuenta_destino_id, monto_centimos, motivo?, pin, idempotency_key}`; cada movimiento JSON gana `"moneda"`.

- [ ] **Step 1: Tests nuevos del envío por cuenta**

Create `tests/test_envio_por_cuenta.py`:

```python
"""
El envío apunta a una CUENTA, no a una persona: con varias cuentas por DNI, el
dinero debe llegar a la que el usuario eligió, y nunca cruzar monedas.
"""

import pytest
from sqlalchemy import update

from app.db.models import Account
from app.services import accounts as accounts_service
from tests.conftest import PIN_DE_PRUEBA

PIN = PIN_DE_PRUEBA
INEXISTENTE_ID = "00000000-0000-0000-0000-000000000000"


async def _cuentas(client, t):
    return (await client.get("/v1/accounts", headers=t.auth)).json()["cuentas"]


async def _abrir(client, t, tipo, moneda, clave):
    r = await client.post(
        "/v1/accounts",
        json={"tipo": tipo, "moneda": moneda, "pin": PIN, "idempotency_key": clave},
        headers=t.auth,
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _recargar(client, t, cuenta_id, centimos, clave):
    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta_id, "monto_centimos": centimos, "pin": PIN,
              "idempotency_key": clave},
        headers=t.auth,
    )
    assert r.status_code == 201, r.text


def _envio(origen, destino, monto=1_000, clave="envio-cta-0001"):
    return {
        "cuenta_origen_id": origen,
        "cuenta_destino_id": destino,
        "monto_centimos": monto,
        "pin": PIN,
        "idempotency_key": clave,
    }


def _saldo(cuentas, cid):
    return next(c["saldo_disponible"] for c in cuentas if c["id"] == cid)


@pytest.mark.asyncio
async def test_el_dinero_llega_a_la_cuenta_elegida_y_no_a_la_primera(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 10_000, "rec-env-01")
    primera = (await _cuentas(client, otro_registrado))[0]["id"]
    segunda = await _abrir(client, otro_registrado, "corriente", "PEN", "ab-env-01")

    r = await client.post("/v1/transfers", json=_envio(origen, segunda), headers=registrado.auth)
    assert r.status_code == 201, r.text

    cuentas = await _cuentas(client, otro_registrado)
    assert _saldo(cuentas, segunda) == 1_000
    assert _saldo(cuentas, primera) == 0


@pytest.mark.asyncio
async def test_entre_cuentas_propias_se_puede(client, registrado):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-02")
    otra = await _abrir(client, registrado, "corriente", "PEN", "ab-env-02")

    r = await client.post("/v1/transfers", json=_envio(origen, otra), headers=registrado.auth)
    assert r.status_code == 201
    cuentas = await _cuentas(client, registrado)
    assert (_saldo(cuentas, origen), _saldo(cuentas, otra)) == (4_000, 1_000)


@pytest.mark.asyncio
async def test_a_la_misma_cuenta_es_same_account(client, registrado):
    origen = (await _cuentas(client, registrado))[0]["id"]
    r = await client.post("/v1/transfers", json=_envio(origen, origen), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "SAME_ACCOUNT"


@pytest.mark.asyncio
async def test_entre_monedas_distintas_es_currency_mismatch_y_no_gasta_pin(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-03")
    usd = await _abrir(client, otro_registrado, "ahorro", "USD", "ab-env-03")

    cuerpo = _envio(origen, usd)
    cuerpo["pin"] = "000000"  # errado: si se verificara, descontaría un intento
    r = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "CURRENCY_MISMATCH"
    assert _saldo(await _cuentas(client, registrado), origen) == 5_000


@pytest.mark.asyncio
async def test_a_una_cuenta_inexistente_o_de_sistema_es_recipient_not_found(
    client, registrado, db_de_client
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-04")
    caja = await accounts_service.cuenta_de_sistema(db_de_client, "PEN")
    await db_de_client.commit()
    for i, destino in enumerate((INEXISTENTE_ID, caja.id)):
        r = await client.post(
            "/v1/transfers", json=_envio(origen, destino, clave=f"env-404-{i:04d}"),
            headers=registrado.auth,
        )
        assert r.status_code == 404
        assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_a_una_cuenta_bloqueada_es_recipient_not_found(
    client, registrado, otro_registrado, db_de_client
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-05")
    destino = (await _cuentas(client, otro_registrado))[0]["id"]
    await db_de_client.execute(update(Account).where(Account.id == destino).values(estado="bloqueada"))
    await db_de_client.commit()
    r = await client.post("/v1/transfers", json=_envio(origen, destino), headers=registrado.auth)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_reintentar_la_clave_hacia_otra_cuenta_de_la_misma_persona_es_409(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-06")
    primera = (await _cuentas(client, otro_registrado))[0]["id"]
    segunda = await _abrir(client, otro_registrado, "corriente", "PEN", "ab-env-06")

    a = await client.post("/v1/transfers", json=_envio(origen, primera), headers=registrado.auth)
    b = await client.post("/v1/transfers", json=_envio(origen, segunda), headers=registrado.auth)
    assert a.status_code == 201
    assert b.status_code == 409
    assert b.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_envio_y_recarga_en_dolares(client, registrado, otro_registrado):
    mi_usd = await _abrir(client, registrado, "ahorro", "USD", "ab-env-07")
    su_usd = await _abrir(client, otro_registrado, "ahorro", "USD", "ab-env-08")
    await _recargar(client, registrado, mi_usd, 3_000, "rec-env-07")

    r = await client.post(
        "/v1/transfers", json=_envio(mi_usd, su_usd, 1_200), headers=registrado.auth
    )
    assert r.status_code == 201
    assert _saldo(await _cuentas(client, otro_registrado), su_usd) == 1_200

    movs = (
        await client.get(f"/v1/accounts/{su_usd}/movements", headers=otro_registrado.auth)
    ).json()["movimientos"]
    assert movs[0]["moneda"] == "USD"


@pytest.mark.asyncio
async def test_una_recarga_en_dolares_sale_de_la_caja_de_dolares(
    client, registrado, db_de_client
):
    mi_usd = await _abrir(client, registrado, "ahorro", "USD", "ab-env-09")
    await _recargar(client, registrado, mi_usd, 2_500, "rec-env-09")
    caja = await accounts_service._buscar_caja(db_de_client, "USD")
    assert caja is not None
    assert caja.saldo_disponible == -2_500
    assert await accounts_service._buscar_caja(db_de_client, "PEN") is None
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `.venv/bin/python -m pytest tests/test_envio_por_cuenta.py -q`
Expected: FAIL (422 por `destinatario_dni` requerido).

- [ ] **Step 3: Cambiar `transfers.py`**

`TransferIn`: reemplazar `destinatario_dni` por

```python
    cuenta_destino_id: str = Field(min_length=1, max_length=36)
```

`_destino_original` devuelve solo la cuenta (ya no hace falta el titular):

```python
async def _destino_original(
    session: AsyncSession, cuenta_origen_id: str, idempotency_key: str
) -> Optional[Account]:
    """
    La cuenta destino del envío que esa clave YA registró desde esta cuenta;
    `None` si no hay tal envío.

    Un reintento no vuelve a buscar el destino del payload: es el de la
    operación original. Así no consulta el padrón ni gasta presupuesto.
    """
    return (
        await session.execute(
            select(Account)
            .join(Transfer, Transfer.cuenta_destino == Account.id)
            .join(Transaction, Transaction.id == Transfer.transaction_id)
            .where(
                Transaction.idempotency_key == idempotency_key,
                Transfer.cuenta_origen == cuenta_origen_id,
            )
            .limit(1)
        )
    ).scalars().first()
```

Cuerpo de `transferir` desde `origen = ...` hasta antes de `motivo = ...`:

```python
    origen = await _buscar_cuenta_propia(session, user, payload.cuenta_origen_id)

    if payload.cuenta_destino_id == origen.id:
        raise ApiError(ErrorCode.SAME_ACCOUNT, "Elige una cuenta distinta a la de origen.")

    destino = await _destino_original(session, origen.id, payload.idempotency_key)
    if destino is not None:
        # REINTENTO del MISMO envío desde la MISMA cuenta: el destino es el de
        # la operación original y no se toca el padrón ni el presupuesto (ver
        # la pregunta "¿se cobró?" en el historial de este archivo).
        if destino.id != payload.cuenta_destino_id:
            # La clave es de un envío a OTRA cuenta (aunque sea de la misma
            # persona): devolver la original haría creer al usuario que envió
            # a donde acaba de elegir.
            raise _clave_reusada()
    else:
        if origen.estado != "activa":
            raise ApiError(
                ErrorCode.ACCOUNT_BLOCKED,
                "Esa cuenta no está activa.",
                status_code=status.HTTP_409_CONFLICT,
            )
        # Buscar una cuenta por id también es un oráculo (existe o no):
        # comparte presupuesto con `/directory/resolve`.
        consumir_consulta_de_destinatario(user.id)
        destino = (
            await session.execute(
                select(Account).where(
                    Account.id == payload.cuenta_destino_id,
                    # Una caja no es un destinatario, y una cuenta bloqueada
                    # tampoco: la respuesta es la de una cuenta inexistente.
                    Account.tipo != "sistema",
                    Account.estado == "activa",
                )
            )
        ).scalar_one_or_none()
        if destino is None:
            raise ApiError(
                ErrorCode.RECIPIENT_NOT_FOUND,
                "No encontramos esa cuenta en CuyCash.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        if destino.moneda != origen.moneda:
            # Antes del PIN: no gasta intentos. Y antes del motor, cuyo
            # `assert` de monedas es la última defensa, no la respuesta.
            raise ApiError(
                ErrorCode.CURRENCY_MISMATCH,
                "Solo puedes enviar entre cuentas de la misma moneda.",
            )

    _validar_monto(payload.monto_centimos, origen.moneda)
    await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)
```

Borrar el bloque `if payload.destinatario_dni == user.dni: ... SELF_TRANSFER`.

`_validar_monto` con símbolo por moneda:

```python
SIMBOLOS = {"PEN": "S/", "USD": "US$"}


def _validar_monto(centimos: int, moneda: str) -> None:
    if centimos < MONTO_MINIMO or centimos > MONTO_MAXIMO:
        s = SIMBOLOS[moneda]
        raise ApiError(
            ErrorCode.AMOUNT_OUT_OF_RANGE,
            f"El monto debe estar entre {s} 0.01 y {s} {MONTO_MAXIMO / 100:,.2f}.",
        )
```

En `recargar`: `_validar_monto(payload.monto_centimos, cuenta.moneda)` y `caja = await accounts_service.cuenta_de_sistema(session, cuenta.moneda)`.

- [ ] **Step 4: Moneda en los movimientos**

En `accounts.py`, `_movimiento_json`, añadir tras `"monto": entry.monto,`:

```python
        "moneda": entry.moneda,
```

- [ ] **Step 5: Adaptar los tests existentes al nuevo payload**

En `tests/test_transferencias.py`:

1. Helper:

```python
INEXISTENTE_ID = "00000000-0000-0000-0000-000000000000"


def _envio(origen, destino, monto, clave, pin=PIN, motivo=None):
    return {
        "cuenta_origen_id": origen,
        "cuenta_destino_id": destino,
        "monto_centimos": monto,
        "motivo": motivo,
        "pin": pin,
        "idempotency_key": clave,
    }
```

2. Reemplazos mecánicos (revisa el diff después):

```bash
cd services/api
sed -i '' -E 's/_envio\(([a-z_]+), otro_registrado\.dni,/_envio(\1, await _cuenta_id(client, otro_registrado),/g' tests/test_transferencias.py
sed -i '' -E 's/_envio\(([a-z_]+), tercero\.dni,/_envio(\1, await _cuenta_id(client, tercero),/g' tests/test_transferencias.py
sed -i '' -E 's/_envio\(([a-z_]+), "99999999",/_envio(\1, INEXISTENTE_ID,/g' tests/test_transferencias.py
```

3. Casos a mano:
   - `test_enviarse_a_uno_mismo_es_rechazado` → renombrar a `test_enviar_a_la_misma_cuenta_es_rechazado`, usar `_envio(origen, origen, 1_000, "envio-006")` y esperar `r.json()["code"] == "SAME_ACCOUNT"`.
   - `test_una_cuenta_ajena_se_trata_como_inexistente` (`_envio(ajena, registrado.dni, ...)`) → `_envio(ajena, await _cuenta_id(client, registrado), ...)`.
   - `test_una_cuenta_ajena_sigue_siendo_404_aunque_la_clave_exista` (línea ~583, `registrado.dni`) → igual que el anterior.
   - `test_la_clave_de_un_envio_a_otra_persona_tampoco_lo_revela` y `test_la_clave_de_la_propia_recarga_...`: ahora comparan cuentas destino; mantén su intención (misma clave, otro destino → 409 sin revelar si existe) usando ids.
   - Un `_envio(...)` dentro de una variable `cuerpo = _envio(...)` en un `def` no-async no puede llevar `await`: si el sed lo dejó así, calcula `destino = await _cuenta_id(client, otro_registrado)` antes.

En `tests/test_directorio_y_frecuentes.py`: mismo helper (`"cuenta_destino_id": destino`), `_envio(origen, INEXISTENTE)` → `_envio(origen, INEXISTENTE_ID)` y `_envio(origen, otro_registrado.dni)` → `_envio(origen, await _cuenta_id(client, otro_registrado))`.

En `tests/test_cuentas_y_movimientos.py`: `grep -n destinatario_dni` y aplicar el mismo cambio.

- [ ] **Step 6: Correr toda la suite**

Run: `.venv/bin/python -m pytest -q`
Expected: PASS (salvo los `skip` de frecuentes).

- [ ] **Step 7: Commit**

```bash
git add services/api/app services/api/tests
git commit -m "feat(api): enviar a una cuenta concreta, sin cruzar monedas; recarga desde la caja de su moneda"
```

---

## Task 6: Frecuentes por cuenta

**Files:**
- Modify: `services/api/app/api/v1/routers/directory.py` (`BeneficiaryIn`, `listar`, `guardar`)
- Modify: `services/api/app/core/errors.py` (borrar `SELF_TRANSFER`)
- Modify: `services/api/tests/test_directorio_y_frecuentes.py` (frecuentes; quitar los `skip`)

**Interfaces:**
- Consumes: `cuenta_publica_json`.
- Produces:
  - `POST /v1/beneficiaries` body `{cuenta_destino_id, apodo}` → `201 {"ok": true}`.
  - `GET /v1/beneficiaries` → `{beneficiarios: [{id, dni, apodo, nombre_enmascarado, cuenta: {cuenta_id, tipo, moneda, numero_masked, nombre} | null}]}`.

- [ ] **Step 1: Reescribir los tests de frecuentes**

En `tests/test_directorio_y_frecuentes.py` quitar los `@pytest.mark.skip(...)` de la Task 1 y añadir un helper:

```python
async def _guardar(client, titular, cuenta_id, apodo="Luis"):
    return await client.post(
        "/v1/beneficiaries",
        json={"cuenta_destino_id": cuenta_id, "apodo": apodo},
        headers=titular.auth,
    )
```

Reemplazar cada `json={"dni": otro_registrado.dni, "apodo": X}` por `json={"cuenta_destino_id": await _cuenta_id(client, otro_registrado), "apodo": X}` (o usar `_guardar`). Cambios específicos:

```python
@pytest.mark.asyncio
async def test_guardar_dos_veces_la_misma_cuenta_actualiza_el_apodo(
    client, registrado, otro_registrado
):
    cid = await _cuenta_id(client, otro_registrado)
    for apodo in ("Luis", "Lucho"):
        assert (await _guardar(client, registrado, cid, apodo)).status_code == 201

    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()[
        "beneficiarios"
    ]
    assert len(lista) == 1
    b = lista[0]
    assert b["apodo"] == "Lucho"
    assert b["dni"] == otro_registrado.dni
    assert b["nombre_enmascarado"] == "L*** A*** Q***"
    assert b["cuenta"]["cuenta_id"] == cid
    assert b["cuenta"]["moneda"] == "PEN"
    assert b["cuenta"]["numero_masked"].startswith("••••")
    assert b["cuenta"]["nombre"] is None


@pytest.mark.asyncio
async def test_dos_cuentas_de_la_misma_persona_son_dos_frecuentes(
    client, registrado, otro_registrado
):
    primera = await _cuenta_id(client, otro_registrado)
    r = await client.post(
        "/v1/accounts",
        json={"tipo": "ahorro", "moneda": "USD", "pin": PIN_DE_PRUEBA, "idempotency_key": "fr-000001"},
        headers=otro_registrado.auth,
    )
    segunda = r.json()["id"]
    await _guardar(client, registrado, primera, "Luis soles")
    await _guardar(client, registrado, segunda, "Luis dólares")
    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()["beneficiarios"]
    assert [b["cuenta"]["moneda"] for b in lista] == ["USD", "PEN"]  # más reciente primero


@pytest.mark.asyncio
async def test_un_frecuente_cuya_cuenta_se_bloquea_queda_sin_cuenta(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import update
    from app.db.models import Account

    cid = await _cuenta_id(client, otro_registrado)
    await _guardar(client, registrado, cid)
    await db_de_client.execute(update(Account).where(Account.id == cid).values(estado="cerrada"))
    await db_de_client.commit()
    [b] = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()["beneficiarios"]
    assert b["cuenta"] is None
    assert b["dni"] == otro_registrado.dni


@pytest.mark.asyncio
async def test_se_puede_guardar_una_cuenta_propia_pero_no_una_inexistente_ni_una_caja(
    client, registrado, db_de_client
):
    from app.services import accounts as accounts_service

    propia = await _cuenta_id(client, registrado)
    assert (await _guardar(client, registrado, propia, "Mi ahorro")).status_code == 201
    caja = await accounts_service.cuenta_de_sistema(db_de_client, "PEN")
    await db_de_client.commit()
    for cid in ("00000000-0000-0000-0000-000000000000", caja.id):
        r = await _guardar(client, registrado, cid, "?")
        assert r.status_code == 404
        assert r.json()["code"] == "RECIPIENT_NOT_FOUND"
```

Borrar `test_no_se_puede_guardar_a_uno_mismo_ni_a_un_inexistente` (cubierto por el anterior). En `test_guardar_el_mismo_frecuente_a_la_vez_no_da_500` y `test_guardar_un_frecuente_comparte_el_mismo_cupo`, cambiar el body a `cuenta_destino_id` (en el del cupo, usar `INEXISTENTE_ID`).

- [ ] **Step 2: Correr y ver que fallan**

Run: `.venv/bin/python -m pytest tests/test_directorio_y_frecuentes.py -q`
Expected: FAIL (422 por `dni` requerido).

- [ ] **Step 3: Implementar**

En `directory.py`:

```python
class BeneficiaryIn(BaseModel):
    cuenta_destino_id: str = Field(min_length=1, max_length=36)
    apodo: str = Field(min_length=1, max_length=40)


@router.get("/beneficiaries")
async def listar(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # No gasta presupuesto: devuelve a quienes el propio titular ya validó al
    # guardarlos. La cuenta se lee al vuelo: si dejó de estar activa, `null`.
    filas = (
        await session.execute(
            select(Beneficiary, User, Account)
            .outerjoin(User, User.dni == Beneficiary.beneficiario_dni)
            .outerjoin(
                Account,
                (Account.id == Beneficiary.cuenta_destino_id) & (Account.estado == "activa"),
            )
            .where(Beneficiary.user_id == user.id)
            .order_by(Beneficiary.created_at.desc(), Beneficiary.id)
        )
    ).all()
    return {
        "beneficiarios": [
            {
                "id": b.id,
                "dni": b.beneficiario_dni,
                "apodo": b.apodo,
                "nombre_enmascarado": (
                    enmascarar(otro.nombres, otro.apellidos) if otro else None
                ),
                "cuenta": (
                    cuenta_publica_json(cuenta, propia=cuenta.user_id == user.id)
                    if cuenta
                    else None
                ),
            }
            for b, otro, cuenta in filas
        ]
    }


@router.post("/beneficiaries", status_code=status.HTTP_201_CREATED)
async def guardar(
    payload: BeneficiaryIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # Guardar valida que la cuenta exista y reciba: 201 vs 404 es otro oráculo
    # del padrón, así que cuesta del mismo presupuesto. Una cuenta propia SÍ
    # se puede guardar ("Mi sueldo").
    consumir_consulta_de_destinatario(user.id)
    fila = (
        await session.execute(
            select(Account, User)
            .join(User, User.id == Account.user_id)
            .where(
                Account.id == payload.cuenta_destino_id,
                Account.tipo != "sistema",
                Account.estado == "activa",
            )
        )
    ).first()
    if fila is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos esa cuenta en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    cuenta, titular = fila

    # Upsert atómico (ver el comentario histórico de este bloque): el doble
    # toque no debe dar 500.
    insertar = (
        pg_insert if session.get_bind().dialect.name == "postgresql" else sqlite_insert
    )
    await session.execute(
        insertar(Beneficiary)
        .values(
            id=_uuid(),
            user_id=user.id,
            beneficiario_dni=titular.dni,
            cuenta_destino_id=cuenta.id,
            apodo=payload.apodo,
            created_at=utcnow(),
        )
        .on_conflict_do_update(
            index_elements=["user_id", "cuenta_destino_id"],
            set_={"apodo": payload.apodo},
        )
    )
    await session.commit()
    return {"ok": True}
```

Conserva el comentario largo existente sobre el upsert (pégalo encima del `insertar`). En `errors.py`, borrar `SELF_TRANSFER`. `grep -rn SELF_TRANSFER app tests` debe quedar vacío.

- [ ] **Step 4: Correr toda la suite**

Run: `.venv/bin/python -m pytest -q`
Expected: PASS, sin `skip` de frecuentes (los únicos omitidos son los `postgres`).

- [ ] **Step 5: Commit**

```bash
git add services/api/app services/api/tests
git commit -m "feat(api): los frecuentes guardan una cuenta; se elimina SELF_TRANSFER"
```

---

## Task 7: Concurrencia (Postgres), esquema y documentación del backend

**Files:**
- Create: `services/api/tests/test_concurrencia_multicuenta.py`
- Modify: `services/api/schema.sql` (regenerado)
- Modify: `docs/modelo-datos.md`

- [ ] **Step 1: Test `postgres` de dos aperturas de sueldo a la vez**

Mismo patrón que `tests/test_motor_de_asientos.py:326` (marca `postgres` + `pytest.skip` sin `TEST_POSTGRES_URL`). Create `tests/test_concurrencia_multicuenta.py`:

```python
"""
Dos aperturas de cuenta sueldo del mismo titular a la vez dejan UNA.

Solo tiene sentido contra Postgres (`TEST_POSTGRES_URL`): SQLite serializa las
escrituras y el choque no ocurre. Como los otros tests `postgres`, NO se ha
ejecutado aún contra una base real.
"""

import asyncio
import os

import pytest
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.db.models import Account, User
from app.services import accounts


@pytest.mark.postgres
@pytest.mark.asyncio
async def test_dos_sueldos_a_la_vez_dejan_uno(db_engine):
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")
    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as s:
        u = User(dni="70000099", nombres="A", apellidos="B", email="a@b.pe",
                 pin_hash="x", alias="@a70000099")
        s.add(u)
        await s.commit()
        user_id = u.id

    async def abrir():
        async with maker() as s:
            try:
                await accounts.abrir_cuenta(s, user_id, tipo="sueldo")
                await s.commit()
                return "ok"
            except IntegrityError:
                await s.rollback()
                return "choque"

    resultados = await asyncio.gather(abrir(), abrir())
    assert sorted(resultados) == ["choque", "ok"]
    async with maker() as s:
        n = (await s.execute(
            select(func.count()).select_from(Account)
            .where(Account.user_id == user_id, Account.tipo == "sueldo")
        )).scalar_one()
    assert n == 1
```

- [ ] **Step 2: Comprobar que se omite sin Postgres**

Run: `.venv/bin/python -m pytest -q tests/test_concurrencia_multicuenta.py`
Expected: `1 skipped`.

- [ ] **Step 3: Regenerar `schema.sql`**

Run: `cd services/api && .venv/bin/python scripts/dump_schema.py`
Expected: `schema.sql` cambia: `nombre`, `idempotency_key`, `ck_accounts_sueldo_en_soles`, `ux_accounts_un_sueldo`, `uq_accounts_clave_apertura`, `cuenta_destino_id`, `uq_beneficiaries_user_cuenta`.

- [ ] **Step 4: Actualizar `docs/modelo-datos.md`**

En las secciones de `accounts` y `beneficiaries`, documentar las columnas y restricciones nuevas (copiar los comentarios del modelo), el tope de 5 (regla del servicio, serializada con `FOR UPDATE` sobre `users`), las dos cajas y que `beneficiaries` apunta a una cuenta. Añadir una línea: "Cambió un `CHECK` y una `UNIQUE`: hay que recrear el esquema con `scripts/reset_schema.py`."

- [ ] **Step 5: Suite completa y commit**

Run: `.venv/bin/python -m pytest -q`
Expected: PASS.

```bash
git add services/api/tests/test_concurrencia_multicuenta.py services/api/schema.sql docs/modelo-datos.md
git commit -m "test(api): apertura concurrente de sueldo (postgres, sin ejecutar); esquema y modelo de datos"
```
