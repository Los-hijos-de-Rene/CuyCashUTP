"""
Consulta de cuentas y movimientos (HU05).

Nada de aquí escribe. El saldo que se devuelve es la COLUMNA, no la suma del
historial: sumar miles de asientos en cada apertura del home no sostiene el
SLA de 1 s.
"""

import base64
import binascii
import uuid
from datetime import datetime, timezone
from typing import Optional, Tuple

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import case, or_, select
from sqlalchemy.orm import aliased
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routers.directory import enmascarar
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


def _utc(momento: datetime) -> datetime:
    """
    El instante como UTC aware, sea cual sea el motor.

    SQLite devuelve datetimes sin zona y Postgres con ella. Se asume que un
    naive ya es UTC (así se escriben: `utcnow()`), y no la zona del proceso.
    """
    if momento.tzinfo is None:
        return momento.replace(tzinfo=timezone.utc)
    return momento.astimezone(timezone.utc)


def _iso(momento: datetime) -> str:
    """
    Formato único del contrato JSON: UTC, microsegundos fijos y sufijo `Z`.

    Con zona explícita, un cliente que parsea no puede leerlo como hora local;
    con ancho fijo, el mismo instante no se escribe de dos maneras.
    """
    return _utc(momento).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def _codificar_cursor(entry: LedgerEntry) -> str:
    crudo = f"{_iso(entry.created_at)}|{entry.id}"
    return base64.urlsafe_b64encode(crudo.encode()).decode()


# Rango sensato de una fecha de movimiento. Fuera de él el cursor es forjado o
# corrupto, y fechas extremas desbordan al convertir de zona o las rechaza el
# motor.
_FECHA_MINIMA = datetime(2000, 1, 1, tzinfo=timezone.utc)
_FECHA_MAXIMA = datetime(2100, 1, 1, tzinfo=timezone.utc)


def _decodificar_cursor(cursor: Optional[str]) -> Optional[Tuple[datetime, str]]:
    """
    Un cursor ilegible devuelve None, no un error.

    El cursor es un detalle de transporte: si llega corrupto, lo correcto es
    empezar por el principio, no dejar al usuario mirando una pantalla rota.
    "Ilegible" incluye lo que SQLite tolera y Postgres no: un id que no es un
    UUID (un NUL en el id lo rechaza Postgres y daría 500), una fecha que
    desborda al pasar a UTC, o una fecha fuera de rango.
    """
    if not cursor:
        return None
    try:
        crudo = base64.urlsafe_b64decode(cursor.encode()).decode()
        fecha, entry_id = crudo.split("|", 1)
        if fecha.endswith("Z"):  # fromisoformat de 3.9 no entiende la Z
            fecha = fecha[:-1] + "+00:00"
        momento = _utc(datetime.fromisoformat(fecha))
        # Forma canónica de 36 caracteres: lo único que generamos nosotros.
        if len(entry_id) != 36 or str(uuid.UUID(entry_id)) != entry_id:
            return None
    except (ValueError, OverflowError, binascii.Error):
        return None
    if not (_FECHA_MINIMA <= momento <= _FECHA_MAXIMA):
        return None
    return momento, entry_id


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


def _consulta_movimientos():
    """
    UN solo SELECT con todo lo que una fila del historial necesita.

    Antes cada fila hacía tres consultas más (transacción, transferencia,
    contraparte): con limit=50 eran ~155 viajes a la base, y contra un Postgres
    remoto eso rompe el SLA de 1 s. La contraparte se resuelve en el JOIN: es
    el otro extremo de la transferencia respecto a la cuenta del asiento.
    """
    propia = aliased(Account)
    destino = aliased(Account)
    otra = aliased(Account)
    otro = aliased(User)
    consulta = (
        select(
            LedgerEntry,
            Transaction,
            Transfer,
            otro.nombres,
            otro.apellidos,
            destino.numero,
        )
        .join(Transaction, Transaction.id == LedgerEntry.transaction_id)
        .join(propia, propia.id == LedgerEntry.account_id)
        .outerjoin(Transfer, Transfer.transaction_id == Transaction.id)
        .outerjoin(destino, destino.id == Transfer.cuenta_destino)
        .outerjoin(
            otra,
            otra.id
            == case(
                (Transfer.cuenta_origen == LedgerEntry.account_id, Transfer.cuenta_destino),
                else_=Transfer.cuenta_origen,
            ),
        )
        .outerjoin(otro, otro.id == otra.user_id)
    )
    return consulta, propia


def _movimiento_json(fila) -> dict:
    entry, tx, transfer, nombres, apellidos, _numero_destino = fila
    # El nombre COMPLETO solo para quien RECIBIÓ el dinero; quien envió ve el
    # mismo enmascarado que le dio `/directory/resolve`.
    #
    # "Ya hubo una operación entre ambos" no alcanza como justificación: la
    # operación la elige quien envía, y `MONTO_MINIMO` es 1 céntimo. Con la
    # regla anterior, un céntimo al DNI de un desconocido convertía
    # `L*** A*** Q***` en "Luis Alberto Quispe", y este historial no descuenta
    # del presupuesto de consultas de destinatario. Recibir, en cambio, no es
    # algo que el curioso pueda provocarse: nadie puede obligar a otro a
    # pagarle, así que ahí el nombre sí lo trae una relación real.
    if tx.tipo == "recarga":
        contraparte, motivo = "Recarga de saldo", None
    elif transfer is None:
        contraparte, motivo = None, None
    elif nombres is None:
        contraparte, motivo = None, transfer.motivo
    else:
        contraparte = (
            f"{nombres} {apellidos}"
            if entry.direccion == "credito"
            else enmascarar(nombres, apellidos)
        )
        motivo = transfer.motivo
    return {
        "transaction_id": tx.id,
        "tipo": tx.tipo,
        "estado": tx.estado,
        "direccion": entry.direccion,
        "monto": entry.monto,
        "contraparte": contraparte,
        "motivo": motivo,
        "saldo_posterior": entry.saldo_posterior,
        "created_at": _iso(entry.created_at),
    }


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
    consulta, _ = _consulta_movimientos()
    consulta = (
        consulta.where(LedgerEntry.account_id == cuenta.id)
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

    filas = (await session.execute(consulta)).all()
    hay_mas = len(filas) > limit
    pagina = filas[:limit]

    return {
        "movimientos": [_movimiento_json(f) for f in pagina],
        "next_cursor": _codificar_cursor(pagina[-1][0]) if hay_mas and pagina else None,
    }


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
    consulta, propia = _consulta_movimientos()
    fila = (
        await session.execute(
            consulta.where(
                LedgerEntry.transaction_id == transaction_id,
                propia.user_id == user.id,
            )
            # Una transferencia entre cuentas del mismo titular tiene dos
            # asientos suyos: sin orden, la ficha cambiaría de uno a otro.
            .order_by(LedgerEntry.created_at, LedgerEntry.id)
            .limit(1)
        )
    ).first()
    if fila is None:
        raise ApiError(
            ErrorCode.MOVEMENT_NOT_FOUND,
            "No encontramos ese movimiento.",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    base = _movimiento_json(fila)
    numero_destino = fila[5]
    if fila[2] is not None and numero_destino is not None:
        base["cuenta_destino_masked"] = f"••••{numero_destino[-4:]}"
    return base
