"""Cobros con QR firmados, consulta previa y pago en libro mayor (issue #77)."""

import hashlib
import os
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel, Field, StrictInt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routers.accounts import _iso
from app.api.v1.routers.transfers import MONTO_MAXIMO, _buscar_cuenta_propia, _validar_monto
from app.core.deps import current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, Transaction, Transfer, User
from app.db.models import Session as SessionRow
from app.services.autorizacion import exigir_pin_de_operacion
from app.services.ledger import Asiento, post
from app.services.qr_firmado import QrVencido, emitir_qr, validar_qr

router = APIRouter(prefix="/v1/qr", tags=["QR"])


class QREmitirIn(BaseModel):
    cuenta_id: str = Field(min_length=1, max_length=36)
    monto_centimos: StrictInt
    concepto: str = Field(default="", max_length=40)
    caducidad_segundos: StrictInt = Field(default=300, ge=30, le=86400)


class QRValidarIn(BaseModel):
    qr: str = Field(min_length=1, max_length=2048)


class QRPagarIn(QRValidarIn):
    cuenta_origen_id: str = Field(min_length=1, max_length=36)
    idempotency_key: str = Field(min_length=8, max_length=64)
    pin: Optional[str] = Field(default=None, max_length=64)


def _secreto_firma() -> str:
    secreto = os.environ.get("QR_SIGNING_SECRET", "")
    if len(secreto.encode("utf-8")) < 32:
        raise ApiError(
            "QR_NOT_CONFIGURED",
            "El servicio QR no está disponible.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    return secreto


def _limite_sin_pin() -> int:
    # El límite debe acordarse con el equipo; no se presume uno en producción.
    raw = os.environ.get("QR_MONTO_BASE_CENTIMOS", "")
    try:
        limite = int(raw)
    except ValueError:
        limite = -1
    if not 1 <= limite <= MONTO_MAXIMO:
        raise ApiError(
            "QR_NOT_CONFIGURED",
            "El servicio QR no está disponible.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    return limite


def _datos_qr(token: str) -> dict:
    try:
        return validar_qr(token, secreto=_secreto_firma())
    except QrVencido as exc:
        raise ApiError(
            "QR_EXPIRED",
            "El QR ha vencido.",
            status_code=status.HTTP_400_BAD_REQUEST,
        ) from exc
    except ValueError as exc:
        raise ApiError(
            "QR_INVALID",
            "El QR es inválido o ha vencido.",
            status_code=status.HTTP_400_BAD_REQUEST,
        ) from exc


def _huella_qr(token: str) -> str:
    return hashlib.sha256(token.encode("ascii")).hexdigest()


def _qr_ya_pagado() -> ApiError:
    return ApiError(
        "QR_ALREADY_PAID",
        "Este QR ya fue pagado.",
        status_code=status.HTTP_409_CONFLICT,
    )


def _ocultar_nombre(texto: str) -> str:
    primera = (texto or "").strip().split()
    if not primera:
        return "***"
    nombre = primera[0]
    return nombre[0] + "*" * min(max(len(nombre) - 1, 2), 5)


async def _destino_visible(session: AsyncSession, cuenta_id: str) -> tuple[Account, User]:
    resultado = await session.execute(
        select(Account, User)
        .join(User, User.id == Account.user_id)
        .where(
            Account.id == cuenta_id,
            Account.tipo != "sistema",
            Account.estado == "activa",
        )
    )
    encontrado = resultado.first()
    if encontrado is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos esa cuenta en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return encontrado[0], encontrado[1]


def _resumen(datos: dict, destino: Account, titular: User) -> dict:
    monto = datos["monto_centimos"]
    _validar_monto(monto, destino.moneda)
    return {
        "cuenta_destino_id": destino.id,
        "nombre_enmascarado": (
            f"{_ocultar_nombre(titular.nombres)} {_ocultar_nombre(titular.apellidos)}"
        ),
        "monto_centimos": monto,
        "moneda": destino.moneda,
        "concepto": datos["concepto"],
        "caduca_en": datetime.fromtimestamp(datos["exp"], timezone.utc).isoformat(),
        "requiere_pin": monto > _limite_sin_pin(),
    }


@router.post("/emitir", status_code=status.HTTP_201_CREATED)
async def emitir(
    payload: QREmitirIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    cuenta = await _buscar_cuenta_propia(session, user, payload.cuenta_id)
    if cuenta.tipo == "sistema" or cuenta.estado != "activa":
        raise ApiError(
            ErrorCode.ACCOUNT_BLOCKED,
            "Esa cuenta no está disponible.",
            status_code=status.HTTP_409_CONFLICT,
        )
    _validar_monto(payload.monto_centimos, cuenta.moneda)
    secreto = _secreto_firma()
    _limite_sin_pin()  # comprobar configuración antes de emitir
    token = emitir_qr(
        secreto=secreto,
        cuenta_id=cuenta.id,
        monto_centimos=payload.monto_centimos,
        concepto=payload.concepto,
        ttl_segundos=payload.caducidad_segundos,
    )
    datos = _datos_qr(token)
    return {
        "id": datos["nonce"],
        "qr": token,
        "monto_centimos": payload.monto_centimos,
        "moneda": cuenta.moneda,
        "concepto": datos["concepto"],
        "caduca_en": datetime.fromtimestamp(datos["exp"], timezone.utc).isoformat(),
    }


@router.post("/validar")
async def consultar(
    payload: QRValidarIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    datos = _datos_qr(payload.qr)
    destino, titular = await _destino_visible(session, datos["cuenta_id"])
    resumen = _resumen(datos, destino, titular)
    pagado = await session.scalar(
        select(Transaction.id).where(Transaction.idempotency_key == _huella_qr(payload.qr))
    )
    if pagado is not None:
        raise _qr_ya_pagado()
    return resumen


@router.post("/pagar")
async def pagar(
    payload: QRPagarIn,
    response: Response,
    user: User = Depends(current_user),
    sesion: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    datos = _datos_qr(payload.qr)
    origen = await _buscar_cuenta_propia(session, user, payload.cuenta_origen_id)
    if origen.id == datos["cuenta_id"]:
        raise ApiError(
            ErrorCode.SAME_ACCOUNT,
            "Elige una cuenta distinta a la de destino.",
        )
    destino, titular = await _destino_visible(session, datos["cuenta_id"])
    _resumen(datos, destino, titular)
    if origen.moneda != destino.moneda:
        raise ApiError(
            ErrorCode.CURRENCY_MISMATCH,
            "Solo puedes pagar entre cuentas de la misma moneda.",
        )
    monto = datos["monto_centimos"]
    if monto > _limite_sin_pin() and not payload.pin:
        raise ApiError(
            "QR_AUTH_REQUIRED",
            "Este monto requiere autorización con PIN.",
            status_code=status.HTTP_403_FORBIDDEN,
        )
    # Un PIN enviado siempre se comprueba: si no, bajo el límite cualquier PIN
    # aprobaría el pago y el usuario creería que el suyo fue validado.
    if payload.pin:
        await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)

    # La clave del libro mayor es la huella del QR: su UNIQUE deja un solo pago,
    # incluso con dos a la vez. La clave del cliente va en la huella de la
    # petición: repetirla es un reintento y devuelve el pago original; otra
    # clave u otra cuenta es un segundo pago del mismo QR y se rechaza.
    try:
        tx, reutilizada = await post(
            session,
            tipo="pago_qr",
            asientos=[
                Asiento(origen.id, "debito", monto),
                Asiento(destino.id, "credito", monto),
            ],
            idempotency_key=_huella_qr(payload.qr),
            fingerprint=f"clave={payload.idempotency_key}",
        )
    except ApiError as exc:
        if exc.detail["code"] == ErrorCode.IDEMPOTENCY_KEY_REUSED:
            raise _qr_ya_pagado() from exc
        raise
    if not reutilizada:
        session.add(
            Transfer(
                transaction_id=tx.id,
                cuenta_origen=origen.id,
                cuenta_destino=destino.id,
                monto=monto,
                motivo=datos["concepto"] or None,
                estado="confirmada",
            )
        )
    cuerpo = {
        "transaction_id": tx.id,
        "estado": tx.estado,
        "monto_centimos": monto,
        "moneda": origen.moneda,
        "created_at": _iso(tx.created_at),
    }
    await session.commit()
    response.status_code = status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    return cuerpo
