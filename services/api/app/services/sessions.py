from datetime import timedelta
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import new_token, token_digest
from app.db.models import Session as SessionRow
from app.db.models import utcnow


async def open_session(
    session: AsyncSession, user_id: str, device_id: str
) -> tuple:
    """Devuelve (token en claro, fila). El token solo existe aquí; se guarda su hash."""
    token = new_token()
    row = SessionRow(
        user_id=user_id,
        device_id=device_id,
        token_hash=token_digest(token),
        expires_at=utcnow() + timedelta(seconds=settings.SESSION_TTL_SECONDS),
    )
    session.add(row)
    await session.flush()
    return token, row


async def resolve(session: AsyncSession, token: str) -> Optional[SessionRow]:
    """Valida el token y desliza el vencimiento si sigue vivo."""
    result = await session.execute(
        select(SessionRow).where(SessionRow.token_hash == token_digest(token))
    )
    row = result.scalar_one_or_none()
    if row is None or row.revoked_at is not None:
        return None

    expires = row.expires_at
    if expires.tzinfo is None:
        from datetime import timezone

        expires = expires.replace(tzinfo=timezone.utc)
    if expires <= utcnow():
        return None

    row.expires_at = utcnow() + timedelta(seconds=settings.SESSION_TTL_SECONDS)
    await session.flush()
    return row


async def revoke(session: AsyncSession, row: SessionRow) -> None:
    row.revoked_at = utcnow()
    await session.flush()


async def revoke_all(session: AsyncSession, user_id: str) -> int:
    """
    Cierra TODAS las sesiones del usuario, incluida la del teléfono que
    disparó el cambio: restablecer el PIN no otorga acceso.

    Poder hacer esto en una sentencia es la razón de usar tokens opacos en base
    y no JWT autocontenidos.
    """
    result = await session.execute(
        update(SessionRow)
        .where(SessionRow.user_id == user_id, SessionRow.revoked_at.is_(None))
        .values(revoked_at=utcnow())
    )
    await session.flush()
    return result.rowcount or 0
