"""
Perfil del titular: sus datos (solo lectura) y su alias.

Los datos vienen del KYC: cambiarlos exigiría volver a verificar la identidad,
así que aquí solo se leen. El correo nunca sale completo: es el canal del OTP de
recuperación y no tiene por qué viajar entero a cada apertura del perfil.
"""

import re
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import User
from app.schemas import AliasIn
from app.services import otp

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
