"""
Dependencias compartidas por los routers que mueven dinero.

La autorización vive en un solo sitio a propósito: repetida en cada router, el
día que alguien añada una ruta se olvidará de ponerla y esa ruta quedará abierta.
"""

from typing import Optional

from fastapi import Depends, Header, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Session as SessionRow
from app.db.models import User
from app.services import sessions


def bearer_token(authorization: Optional[str]) -> Optional[str]:
    """El token de `Authorization: Bearer <token>`, o None si no hay uno utilizable."""
    if not authorization:
        return None
    esquema, _, token = authorization.partition(" ")
    token = token.strip()
    if esquema.lower() != "bearer" or not token:
        return None
    return token


def _unauthenticated() -> ApiError:
    # UN solo mensaje para todos los casos (sin cabecera, token inventado,
    # vencido, revocado, usuario borrado). Si se distinguieran desde fuera,
    # quien sondea sabría qué tokens existieron alguna vez.
    return ApiError(
        ErrorCode.UNAUTHENTICATED,
        "Tu sesión no es válida. Vuelve a entrar.",
        status_code=status.HTTP_401_UNAUTHORIZED,
    )


async def current_session_row(
    authorization: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
) -> SessionRow:
    """
    La fila de sesión del `Authorization: Bearer`, o 401.

    Se valida contra la tabla `sessions`, no contra un JWT autocontenido: es lo
    que permite cerrar todas las sesiones de un usuario en una sentencia cuando
    cambia su PIN. `sessions.resolve` además desliza el vencimiento.
    """
    token = bearer_token(authorization)
    if token is None:
        raise _unauthenticated()
    row = await sessions.resolve(session, token)
    if row is None:
        raise _unauthenticated()
    return row


async def current_user(
    row: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
) -> User:
    """El titular de la sesión, o 401. Es lo que debe exigir todo endpoint de dinero."""
    user = await session.get(User, row.user_id)
    if user is None:
        raise _unauthenticated()
    return user
