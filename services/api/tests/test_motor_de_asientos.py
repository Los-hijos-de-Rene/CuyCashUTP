"""
HU17, HU18 y HU16: libro mayor atómico y una sola autorización por pago.

Lo que se prueba aquí es el ÚNICO camino por el que entra dinero al libro.
Si algún día otra ruta escribe asientos sin pasar por `ledger.post`, estas
garantías dejan de valer y nadie se entera: por eso el motor es uno solo.
"""

import asyncio
import os

import pytest
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core.errors import ApiError
from app.db.models import Account, LedgerEntry, Transaction, User
from app.services.ledger import Asiento, post


async def _cuenta(db, dni: str, numero: str, saldo: int) -> Account:
    user = User(
        dni=dni, nombres="Ada", apellidos="Lovelace",
        email=f"{dni}@correo.pe", alias=f"@ada{dni}", pin_hash="x",
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


@pytest.mark.asyncio
async def test_dos_debitos_sobre_la_misma_cuenta_se_validan_sumados(db):
    """Cada débito de 600 cabe en 1000; juntos no. Se valida el total."""
    origen = await _cuenta(db, "20000011", "19100000000011", 1_000)
    destino = await _cuenta(db, "20000012", "19100000000012", 0)

    with pytest.raises(ApiError) as exc:
        await post(
            db, tipo="transferencia",
            asientos=[
                Asiento(origen.id, "debito", 600),
                Asiento(origen.id, "debito", 600),
                Asiento(destino.id, "credito", 1_200),
            ],
            idempotency_key="k-006", fingerprint="f-006",
        )
    assert exc.value.detail["code"] == "INSUFFICIENT_FUNDS"
    assert origen.saldo_disponible == 1_000


@pytest.mark.asyncio
async def test_una_recarga_deja_la_caja_del_sistema_en_negativo(db):
    from app.services.accounts import cuenta_de_sistema

    caja = await cuenta_de_sistema(db)
    titular = await _cuenta(db, "20000013", "19100000000013", 0)

    await post(
        db, tipo="recarga",
        asientos=[Asiento(caja.id, "debito", 20_000), Asiento(titular.id, "credito", 20_000)],
        idempotency_key="k-007", fingerprint="f-007",
    )
    await db.commit()

    assert caja.saldo_disponible == -20_000
    assert titular.saldo_disponible == 20_000


@pytest.mark.asyncio
async def test_una_cuenta_ya_cargada_se_relee_tras_el_bloqueo(db):
    """
    C1. La caja de `cuenta_de_sistema` y el origen que carga una ruta ya están
    en el identity map cuando se llama a `post`. Si el SELECT FOR UPDATE no
    repuebla, se valida y se calcula con un saldo viejo y el UPDATE pisa el
    cambio concurrente (dinero creado de la nada).
    """
    origen = await _cuenta(db, "20000014", "19100000000014", 100_000)
    destino = await _cuenta(db, "20000015", "19100000000015", 0)
    await db.commit()
    assert origen.saldo_disponible == 100_000  # cargada en el identity map

    # Otra transacción deja la fila en 1.000 por detrás de la ORM.
    await db.execute(
        update(Account)
        .where(Account.id == origen.id)
        .values(saldo_disponible=1_000, saldo_contable=1_000)
        .execution_options(synchronize_session=False)
    )

    with pytest.raises(ApiError) as exc:
        await post(
            db, tipo="transferencia",
            asientos=[Asiento(origen.id, "debito", 50_000), Asiento(destino.id, "credito", 50_000)],
            idempotency_key="k-008", fingerprint="f-008",
        )
    assert exc.value.detail["code"] == "INSUFFICIENT_FUNDS"
    assert origen.saldo_disponible == 1_000


@pytest.mark.asyncio
async def test_la_misma_clave_y_huella_con_otro_destinatario_es_rechazada(db):
    """I2. La huella del llamador es idéntica; los asientos, no."""
    origen = await _cuenta(db, "20000016", "19100000000016", 50_000)
    uno = await _cuenta(db, "20000017", "19100000000017", 0)
    otro = await _cuenta(db, "20000018", "19100000000018", 0)

    await post(
        db, tipo="transferencia",
        asientos=[Asiento(origen.id, "debito", 10_000), Asiento(uno.id, "credito", 10_000)],
        idempotency_key="k-009", fingerprint="igual",
    )
    await db.commit()

    with pytest.raises(ApiError) as exc:
        await post(
            db, tipo="transferencia",
            asientos=[Asiento(origen.id, "debito", 10_000), Asiento(otro.id, "credito", 10_000)],
            idempotency_key="k-009", fingerprint="igual",
        )
    assert exc.value.detail["code"] == "IDEMPOTENCY_KEY_REUSED"
    assert otro.saldo_disponible == 0


@pytest.mark.asyncio
async def test_una_clave_duplicada_que_llega_al_insert_se_resuelve_como_reutilizacion(db, monkeypatch):
    """
    I1. Se simula la ventana: la consulta previa no ve la fila (otra sesión la
    confirma justo después) y es la UNIQUE la que salta. No debe haber 500 ni
    sesión envenenada.
    """
    from app.services import ledger

    origen = await _cuenta(db, "20000019", "19100000000019", 50_000)
    destino = await _cuenta(db, "20000020", "19100000000020", 0)
    asientos = [Asiento(origen.id, "debito", 10_000), Asiento(destino.id, "credito", 10_000)]
    primera, _ = await post(
        db, tipo="transferencia", asientos=asientos,
        idempotency_key="k-010", fingerprint="f-010",
    )
    await db.commit()

    real = ledger._buscar_por_clave
    llamadas = []

    async def ciega_la_primera_vez(session, key):
        llamadas.append(key)
        return None if len(llamadas) == 1 else await real(session, key)

    monkeypatch.setattr(ledger, "_buscar_por_clave", ciega_la_primera_vez)

    segunda, reutilizada = await post(
        db, tipo="transferencia", asientos=asientos,
        idempotency_key="k-010", fingerprint="f-010",
    )
    assert reutilizada is True
    assert segunda.id == primera.id
    assert origen.saldo_disponible == 40_000
    # La sesión sigue viva.
    assert (await db.execute(select(func.count(LedgerEntry.id)))).scalar_one() == 2


@pytest.mark.asyncio
async def test_una_cuenta_bloqueada_no_se_debita(db):
    """I3."""
    origen = await _cuenta(db, "20000021", "19100000000021", 50_000)
    destino = await _cuenta(db, "20000022", "19100000000022", 0)
    origen.estado = "bloqueada"
    await db.flush()
    asientos = [Asiento(origen.id, "debito", 1_000), Asiento(destino.id, "credito", 1_000)]

    with pytest.raises(ApiError) as exc:
        await post(
            db, tipo="transferencia", asientos=asientos,
            idempotency_key="k-011", fingerprint="f-011",
        )
    assert exc.value.detail["code"] == "ACCOUNT_BLOCKED"
    assert origen.saldo_disponible == 50_000

    # Una reversión o ajuste sí puede tocarla, con la exención explícita.
    _, reutilizada = await post(
        db, tipo="ajuste", asientos=asientos,
        idempotency_key="k-012", fingerprint="f-012",
        permitir_cuentas_inactivas=True,
    )
    assert reutilizada is False
    assert origen.saldo_disponible == 49_000


@pytest.mark.asyncio
async def test_entradas_invalidas_revientan_antes_de_tocar_la_base(db):
    origen = await _cuenta(db, "20000023", "19100000000023", 50_000)
    destino = await _cuenta(db, "20000024", "19100000000024", 0)
    par = [Asiento(origen.id, "debito", 1_000), Asiento(destino.id, "credito", 1_000)]

    with pytest.raises(AssertionError):  # tipo fuera del CHECK
        await post(db, tipo="inventado", asientos=par, idempotency_key="k-013", fingerprint="f")
    with pytest.raises(AssertionError):  # clave más larga que la columna
        await post(db, tipo="transferencia", asientos=par, idempotency_key="k" * 65, fingerprint="f")
    with pytest.raises(AssertionError):  # clave vacía
        await post(db, tipo="transferencia", asientos=par, idempotency_key="", fingerprint="f")


@pytest.mark.postgres
@pytest.mark.asyncio
async def test_dos_envios_cruzados_no_se_abrazan(db_engine):
    """
    A→B y B→A a la vez, muchas veces. El bloqueo en orden de id lo evita; sin
    él Postgres aborta una de las dos con "deadlock detected".

    SOLO CORRE CON `TEST_POSTGRES_URL`: SQLite ignora `with_for_update()` y aquí
    pasaría siempre sin probar nada, así que sin la variable se salta.
    Ejemplo: `TEST_POSTGRES_URL=postgresql+asyncpg://... pytest -m postgres`
    contra una base DESECHABLE cuyo nombre termine en `_test` (el esquema se
    borra al empezar y al terminar).

    PENDIENTE la primera vez que se ejecute contra Postgres: la comprobación
    recíproca. Quitar `order_by(Account.id)` de `ledger.post` y confirmar que
    ESTE test falla (deadlock detected). Sin esa mutación, el orden de bloqueo
    sigue siendo un razonamiento y no una prueba.
    """
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")

    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as setup:
        a = await _cuenta(setup, "30000001", "19100000000101", 1_000_000)
        b = await _cuenta(setup, "30000002", "19100000000102", 1_000_000)
        await setup.commit()
        id_a, id_b = a.id, b.id

    async def enviar(origen, destino, key):
        async with maker() as s:
            await post(
                s, tipo="transferencia",
                asientos=[Asiento(origen, "debito", 100), Asiento(destino, "credito", 100)],
                idempotency_key=key, fingerprint=key,
            )
            await s.commit()

    rondas = 25
    tareas = []
    for i in range(rondas):
        tareas.append(enviar(id_a, id_b, f"ab-{i}"))
        tareas.append(enviar(id_b, id_a, f"ba-{i}"))
    await asyncio.wait_for(asyncio.gather(*tareas), timeout=60)

    async with maker() as s:
        saldos = (await s.execute(select(Account.saldo_disponible))).scalars().all()
    assert sum(saldos) == 2_000_000  # nada se creó ni se perdió


@pytest.mark.postgres
@pytest.mark.asyncio
async def test_la_misma_clave_en_paralelo_cobra_una_sola_vez(db_engine):
    """HU16 bajo concurrencia real: dos peticiones simultáneas, un solo cobro."""
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")

    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as setup:
        a = await _cuenta(setup, "30000003", "19100000000103", 50_000)
        b = await _cuenta(setup, "30000004", "19100000000104", 0)
        await setup.commit()
        id_a, id_b = a.id, b.id

    async def enviar():
        async with maker() as s:
            _, reutilizada = await post(
                s, tipo="transferencia",
                asientos=[Asiento(id_a, "debito", 10_000), Asiento(id_b, "credito", 10_000)],
                idempotency_key="par-1", fingerprint="par",
            )
            await s.commit()
            return reutilizada

    resultados = await asyncio.wait_for(asyncio.gather(enviar(), enviar()), timeout=30)
    assert sorted(resultados) == [False, True]
    async with maker() as s:
        saldo = (await s.execute(select(Account.saldo_disponible).where(Account.id == id_a))).scalar_one()
    assert saldo == 40_000
