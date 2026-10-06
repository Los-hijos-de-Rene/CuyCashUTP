"""
Perfil del titular: sus datos (solo lectura) y su alias.

Los datos vienen del KYC: cambiarlos exigiría volver a verificar la identidad,
así que aquí solo se leen. El correo nunca sale completo: es el canal del OTP de
recuperación y no tiene por qué viajar entero a cada apertura del perfil.
"""

import re
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Device
from app.db.models import Session as SessionRow
from app.db.models import User
from app.schemas import AliasIn
from app.services import biometric, otp, sessions

router = APIRouter(prefix="/v1", tags=["Perfil"])

_ALIAS = re.compile(r"^@[a-z0-9_.]{3,20}$")


def _iso(momento: datetime) -> str:
    """UTC con sufijo `Z`, el formato del resto del contrato."""
    utc = momento.replace(tzinfo=timezone.utc) if momento.tzinfo is None else momento
    return utc.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


def normalizar_alias(texto: str) -> str:
    """Minúsculas, sin espacios en los bordes y con `@` delante."""
    limpio = texto.strip().lower()
    return limpio if limpio.startswith("@") else f"@{limpio}"


@router.get("/me")
async def me(user: User = Depends(current_user)):
    return {
        "dni": user.dni,
        "nombres": user.nombres,
        "apellidos": user.apellidos,
        "email_masked": otp.mask_email(user.email),
        "alias": user.alias,
        "kyc_status": user.kyc_status,
        "created_at": _iso(user.created_at),
    }


@router.patch("/me/alias")
async def cambiar_alias(
    payload: AliasIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    alias = normalizar_alias(payload.alias)
    if not _ALIAS.match(alias):
        raise ApiError(
            ErrorCode.INVALID_ALIAS,
            "Usa de 3 a 20 letras, números, punto o guion bajo.",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )
    user.alias = alias
    await session.commit()
    return {"alias": alias}


@router.get("/devices")
async def listar_dispositivos(
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    filas = (
        await session.execute(select(Device).where(Device.user_id == user.id))
    ).scalars().all()
    con_huella = await biometric.devices_with_credential(session, user.id)

    def _utc(d):
        return d.replace(tzinfo=timezone.utc) if d.tzinfo is None else d

    ordenadas = sorted(
        filas, key=lambda d: (d.device_id != row.device_id, -_utc(d.last_seen_at).timestamp())
    )
    return {
        "dispositivos": [
            {
                "id": d.id,
                "nombre": d.nombre,
                "plataforma": d.plataforma,
                "vinculado_el": _iso(d.trusted_at),
                "ultimo_uso": _iso(d.last_seen_at),
                "es_este": d.device_id == row.device_id,
                "con_huella": d.device_id in con_huella,
            }
            for d in ordenadas
        ]
    }


@router.delete("/devices/{dispositivo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def desvincular(
    dispositivo_id: str,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Saca a un teléfono: cierra sus sesiones, revoca su huella y borra la
    confianza, así que volver a entrar desde ahí pedirá el OTP de dispositivo.
    Este teléfono no se desvincula aquí: para eso está "Cerrar sesión".
    """
    fila = await session.get(Device, dispositivo_id)
    if fila is None or fila.user_id != user.id:
        raise ApiError(
            ErrorCode.DEVICE_NOT_FOUND,
            "Ese dispositivo ya no está vinculado.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    if fila.device_id == row.device_id:
        raise ApiError(
            ErrorCode.CANNOT_UNLINK_CURRENT,
            "Para salir de este teléfono, cierra sesión.",
            status_code=status.HTTP_409_CONFLICT,
        )
    await sessions.revoke_device(session, user.id, fila.device_id)
    await biometric.revoke(session, user.id, device_id=fila.device_id)
    await session.delete(fila)
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
