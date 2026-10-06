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
from typing import Literal, Optional, Tuple

from fastapi import APIRouter, Depends, Query, Response, status
from pydantic import BaseModel, Field
from sqlalchemy import case, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import aliased
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routers.directory import enmascarar
from app.core.deps import current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, LedgerEntry, Transaction, Transfer, User
from app.db.models import Session as SessionRow
from app.services import accounts as accounts_service
from app.services.autorizacion import exigir_pin_de_operacion

router = APIRouter(prefix="/v1", tags=["Cuentas"])

LIMITE_MAXIMO = 50


def _cuenta_json(c: Account) -> dict:
    return {
        "id": c.id,
        "numero": c.numero,
        "tipo": c.tipo,
        "moneda": c.moneda,
        "estado": c.estado,
        "nombre": c.nombre,
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
        "moneda": entry.moneda,
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

    # Serializa las aperturas del MISMO titular: sin esto, dos peticiones a la
    # vez contarían 4 cuentas cada una y abrirían la 5.ª y la 6.ª. SQLite
    # ignora FOR UPDATE (allí las escrituras ya se serializan).
    await session.execute(select(User.id).where(User.id == user.id).with_for_update())
    # El reintento se busca DESPUÉS del bloqueo: dos peticiones con la misma
    # clave se serializan y la segunda ve la cuenta de la primera.
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
        cuenta = await accounts_service.abrir_cuenta(
            session,
            user.id,
            tipo=payload.tipo,
            moneda=payload.moneda,
            nombre=nombre,
            idempotency_key=payload.idempotency_key,
        )
    except IntegrityError:
        await session.rollback()
        if payload.tipo != "sueldo":
            raise  # una restricción inesperada no se disfraza de sueldo repetida
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
