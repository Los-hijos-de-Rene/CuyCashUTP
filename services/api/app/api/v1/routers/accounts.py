"""
Consulta de cuentas y movimientos (HU05).

Nada de aquí escribe. El saldo que se devuelve es la COLUMNA, no la suma del
historial: sumar miles de asientos en cada apertura del home no sostiene el
SLA de 1 s.
"""

import base64
import binascii
from datetime import datetime
from typing import Optional, Tuple

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


def _decodificar_cursor(cursor: Optional[str]) -> Optional[Tuple[datetime, str]]:
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

    # Orden total (fecha, id): dos asientos con la misma fecha no se pueden
    # desempatar solo por fecha, y sin desempate el cursor repetiría o saltaría
    # filas en el borde de la página. Se pide uno de más para saber si hay otra.
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
) -> Tuple[Optional[str], Optional[str]]:
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
    solicitante: sin eso, cualquiera con un id leería operaciones ajenas. Si no
    la toca es 404 y no 403, por la misma razón que en las cuentas.
    """
    entry = (
        await session.execute(
            select(LedgerEntry)
            .join(Account, Account.id == LedgerEntry.account_id)
            .where(
                LedgerEntry.transaction_id == transaction_id,
                Account.user_id == user.id,
            )
            # Una transferencia entre cuentas del mismo titular tiene dos
            # asientos suyos: sin orden, la ficha cambiaría de uno a otro.
            .order_by(LedgerEntry.created_at, LedgerEntry.id)
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
