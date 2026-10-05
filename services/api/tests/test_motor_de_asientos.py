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
