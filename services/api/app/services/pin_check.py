"""
Verificar el PIN de un titular que YA tiene sesión (cambiar PIN, activar huella).

Cuenta para el mismo bloqueo que el login: con sesión abierta, un PIN errado
sigue siendo un intento de adivinarlo. Si el intento bloquea, también se cierra
la sesión que lo pidió: quien no sabe el PIN no debe seguir dentro.
"""

from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.core.security import averify_pin
from app.db.models import Session as SessionRow
from app.db.models import User
from app.services import lockout, sessions


def _bloqueado(hasta, kind: str = "dni") -> ApiError:
    return ApiError(
        ErrorCode.IDENTIFIER_LOCKED if kind == "dni" else ErrorCode.DEVICE_LOCKED,
        "El ingreso está bloqueado por ahora.",
        status_code=status.HTTP_423_LOCKED,
        extra={"locked_until": hasta.isoformat()},
    )


async def verify(session: AsyncSession, user: User, pin: str, row: SessionRow) -> None:
    for kind, value in (("dni", user.dni), ("device", row.device_id)):
        hasta = await lockout.locked_until(session, kind, value)
        if hasta is not None:
            raise _bloqueado(hasta, kind)

    if await averify_pin(pin, user.pin_hash):
        await lockout.register_success(session, user.dni, row.device_id)
        return

    disparo = await lockout.register_failure_detail(session, user.dni, row.device_id)
    if disparo is not None:
        await sessions.revoke(session, row)
        await session.commit()
        raise _bloqueado(*disparo)
    restantes = await lockout.attempts_left(session, user.dni)
    await session.commit()
    raise ApiError(
        ErrorCode.INVALID_CREDENTIALS,
        "Tu PIN actual no es correcto.",
        status_code=status.HTTP_401_UNAUTHORIZED,
        extra={"attempts_left": restantes},
    )
