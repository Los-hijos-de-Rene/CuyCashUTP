"""
Tickets de KYC aprobado: lo que une el veredicto del servicio de KYC con el
alta de la cuenta.

Se emite en el proxy de `verify-full` (solo si el servicio aprobó TODO,
incluido el cotejo del DNI con el reverso) y se consume en `/register`, que
exige que sea del mismo DNI y del mismo teléfono.
"""

from datetime import timedelta, timezone
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import ApiError, ErrorCode
from app.core.security import new_token, token_digest
from app.db.models import KycTicket, utcnow


def _aware(moment):
    return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc)


def approved_dni(verdict: dict) -> Optional[str]:
    """
    El DNI del documento si la respuesta de `verify-full` es una aprobación
    completa; None en cualquier otro caso.

    Exige el cotejo con el reverso: una aprobación sin `document_data` (un
    cliente que no mandó el reverso) no prueba de QUIÉN es el documento, así
    que no da ticket.
    """
    if verdict.get("overall_result") is not True:
        return None
    data = verdict.get("document_data")
    if not isinstance(data, dict):
        return None
    dni = data.get("dni")
    if data.get("valid") is not True or data.get("matches_expected") is not True:
        return None
    if not isinstance(dni, str) or len(dni) != 8 or not dni.isdigit():
        return None
    return dni


async def issue(session: AsyncSession, verdict: dict, device_id: str) -> Optional[str]:
    """Emite un ticket si [verdict] es una aprobación completa. Devuelve el token."""
    dni = approved_dni(verdict)
    if dni is None or not device_id:
        return None
    token = new_token()
    match = verdict.get("face_match") or {}
    session.add(
        KycTicket(
            token_hash=token_digest(token),
            dni=dni,
            device_id=device_id[:128],
            document_valid=bool((verdict.get("document_validation") or {}).get("is_valid")),
            is_live=bool((verdict.get("liveness") or {}).get("is_live")),
            face_match=bool(match.get("is_match")),
            face_distance=match.get("distance"),
            expires_at=utcnow() + timedelta(seconds=settings.KYC_TICKET_TTL_SECONDS),
        )
    )
    await session.commit()
    return token


def _invalido() -> ApiError:
    return ApiError(
        ErrorCode.KYC_INVALID,
        "Tu verificación de identidad no es válida o venció. Vuelve a verificarte.",
        status_code=403,
    )


async def find_valid(
    session: AsyncSession, token: str, dni: str, device_id: str
) -> KycTicket:
    """
    El ticket si sirve para registrar ESTE DNI desde ESTE teléfono.

    Todos los rechazos responden igual: distinguir "venció" de "es de otro
    DNI" le diría a quien prueba tickets ajenos cuál le falta.
    """
    result = await session.execute(
        select(KycTicket).where(KycTicket.token_hash == token_digest(token))
    )
    ticket = result.scalar_one_or_none()
    if (
        ticket is None
        or ticket.used_at is not None
        or utcnow() >= _aware(ticket.expires_at)
        or ticket.dni != dni
        or ticket.device_id != device_id
    ):
        raise _invalido()
    return ticket


async def consume(session: AsyncSession, ticket_id: str) -> None:
    """
    Marca el ticket como usado con un UPDATE condicional: si dos registros
    simultáneos traen el mismo ticket, solo uno lo consume.
    """
    result = await session.execute(
        update(KycTicket)
        .where(KycTicket.id == ticket_id, KycTicket.used_at.is_(None))
        .values(used_at=utcnow())
    )
    if result.rowcount != 1:
        raise _invalido()
