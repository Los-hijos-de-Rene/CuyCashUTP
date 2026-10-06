"""
Pruebas del libro mayor (épica 2 · HU17, HU18).

Lo que se verifica aquí no es código de aplicación: son las garantías que la
BASE impone, y por eso se prueban contra el esquema. Una regla que vive en una
restricción no se puede saltar olvidando una validación en una ruta nueva; una
que vive solo en Python, sí.

Diseño y justificación: docs/modelo-datos.md
"""

import pytest
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.db.models import Account, LedgerEntry, Transaction, User


async def _cuenta(db, dni: str, numero: str, saldo: int) -> Account:
    user = User(
        dni=dni,
        nombres="Ada",
        apellidos="Lovelace",
        email=f"{dni}@correo.pe",
        alias="@ada",
        pin_hash="x",
    )
    db.add(user)
    await db.flush()
    cuenta = Account(
        user_id=user.id, numero=numero, saldo_disponible=saldo, saldo_contable=saldo
    )
    db.add(cuenta)
    await db.flush()
    return cuenta


async def test_una_transferencia_deja_los_debitos_iguales_a_los_creditos(db):
    """La partida doble: 150,00 soles salen de una cuenta y entran en la otra."""
    origen = await _cuenta(db, "10000001", "00000000000001", 50_000)
    destino = await _cuenta(db, "10000002", "00000000000002", 0)
    monto = 15_000  # céntimos

    tx = Transaction(tipo="transferencia", idempotency_key="demo-001")
    db.add(tx)
    await db.flush()

    origen.saldo_disponible -= monto
    destino.saldo_disponible += monto
    db.add_all([
        LedgerEntry(
            transaction_id=tx.id,
            account_id=origen.id,
            direccion="debito",
            monto=monto,
            saldo_posterior=origen.saldo_disponible,
        ),
        LedgerEntry(
            transaction_id=tx.id,
            account_id=destino.id,
            direccion="credito",
            monto=monto,
            saldo_posterior=destino.saldo_disponible,
        ),
    ])
    await db.commit()

    async def total(direccion: str) -> int:
        return (
            await db.execute(
                select(func.coalesce(func.sum(LedgerEntry.monto), 0)).where(
                    LedgerEntry.transaction_id == tx.id,
                    LedgerEntry.direccion == direccion,
                )
            )
        ).scalar_one()

    assert await total("debito") == await total("credito") == monto
    assert origen.saldo_disponible == 35_000
    assert destino.saldo_disponible == 15_000


async def test_el_saldo_no_puede_quedar_negativo(db):
    """Última defensa contra el doble gasto si una ruta olvidara validarlo."""
    cuenta = await _cuenta(db, "10000003", "00000000000003", 1_000)
    cuenta.saldo_disponible = -1

    with pytest.raises(IntegrityError):
        await db.commit()


async def test_un_asiento_con_monto_cero_o_negativo_es_rechazado(db):
    """El signo lo dice `direccion`; el monto es siempre positivo."""
    cuenta = await _cuenta(db, "10000004", "00000000000004", 1_000)
    tx = Transaction(tipo="ajuste", idempotency_key="demo-002")
    db.add(tx)
    await db.flush()

    db.add(
        LedgerEntry(
            transaction_id=tx.id,
            account_id=cuenta.id,
            direccion="debito",
            monto=-500,
            saldo_posterior=1_500,
        )
    )
    with pytest.raises(IntegrityError):
        await db.commit()


async def test_repetir_la_clave_de_idempotencia_no_crea_una_segunda_transaccion(db):
    """
    HU16: una sola autorización por pago.

    El cliente repite la clave al reintentar por timeout o red caída. La
    restricción única es lo que impide cobrar dos veces, y está en la base
    porque es la única capa que ve todos los intentos a la vez.
    """
    await _cuenta(db, "10000005", "00000000000005", 10_000)
    db.add(Transaction(tipo="pago_qr", idempotency_key="qr-abc-123"))
    await db.commit()

    db.add(Transaction(tipo="pago_qr", idempotency_key="qr-abc-123"))
    with pytest.raises(IntegrityError):
        await db.commit()


async def test_un_estado_no_previsto_es_rechazado(db):
    """Los estados son texto acotado por CHECK, no cualquier cadena."""
    cuenta = await _cuenta(db, "10000006", "00000000000006", 1_000)
    cuenta.estado = "congelada"

    with pytest.raises(IntegrityError):
        await db.commit()


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
    """Guardar dos veces la misma cuenta actualiza el apodo, no crea otra fila."""
    from app.db.models import Beneficiary

    cuenta = await _cuenta(db, "10000008", "00000000000008", 0)
    db.add(Beneficiary(user_id=cuenta.user_id, beneficiario_dni="71234567",
                    cuenta_destino_id=cuenta.id, apodo="Jenny"))
    await db.commit()

    db.add(Beneficiary(user_id=cuenta.user_id, beneficiario_dni="71234567",
                    cuenta_destino_id=cuenta.id, apodo="Jenny 2"))
    with pytest.raises(IntegrityError):
        await db.commit()


async def test_una_cuenta_normal_sin_titular_es_rechazada(db):
    """Solo la caja de sistema puede existir sin titular."""
    db.add(Account(user_id=None, numero="00000000000009", tipo="ahorro"))
    with pytest.raises(IntegrityError):
        await db.commit()


async def test_una_cuenta_de_sistema_con_titular_es_rechazada(db):
    """Una `sistema` con titular podría quedar en negativo: se prohíbe."""
    cuenta = await _cuenta(db, "10000009", "00000000000010", 0)
    db.add(Account(user_id=cuenta.user_id, numero="19100000000001", tipo="sistema"))
    with pytest.raises(IntegrityError):
        await db.commit()
