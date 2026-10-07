"""
Autorizar con el PIN una operación de un titular con sesión (mover dinero,
abrir una cuenta).

Los fallos alimentan el MISMO bloqueo que el login (sujeto `dni`, y de paso el
del dispositivo): se agotan los intentos se gasten entrando u operando.
"""

from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.core.security import averify_pin
from app.db.models import User
from app.services import lockout


def _bloqueado(hasta, code: str = ErrorCode.IDENTIFIER_LOCKED) -> ApiError:
    return ApiError(
        code,
        "Tu cuenta está bloqueada por ahora.",
        status_code=status.HTTP_423_LOCKED,
        extra={"locked_until": hasta.isoformat()},
    )


async def exigir_pin_de_operacion(
    session: AsyncSession, user: User, device_id: str, pin: str
) -> None:
    """
    Autoriza el movimiento con el PIN. Los fallos alimentan el MISMO bloqueo que
    el login (sujeto `dni`, y de paso el del dispositivo): se agotan los
    intentos se gasten entrando o enviando.
    """
    for kind, value, code in (
        ("dni", user.dni, ErrorCode.IDENTIFIER_LOCKED),
        ("device", device_id, ErrorCode.DEVICE_LOCKED),
    ):
        hasta = await lockout.locked_until(session, kind, value)
        if hasta is not None:
            raise _bloqueado(hasta, code)

    if await averify_pin(pin, user.pin_hash):
        # Sin commit: viaja con el movimiento. Si el movimiento falla, el
        # reinicio del contador se descarta con él, lo cual es lo prudente.
        # OJO: esto escribe una `LoginAttempt(succeeded=True)` por cada
        # movimiento. `login_attempts` ya no es solo el registro de ingresos:
        # una auditoría leerá "sesión iniciada" donde hubo una transferencia.
        await lockout.register_success(session, user.dni, device_id)
        return

    disparo = await lockout.register_failure_detail(session, user.dni, device_id)
    restantes = await lockout.attempts_left(session, user.dni)
    # El fallo TIENE que persistirse antes de lanzar el error: al propagarse la
    # excepción la sesión se cierra sin commit y el intento no contaría nunca,
    # con lo que el bloqueo sería decorativo.
    await session.commit()
    if disparo is not None:
        hasta, kind = disparo
        raise _bloqueado(
            hasta,
            ErrorCode.IDENTIFIER_LOCKED if kind == "dni" else ErrorCode.DEVICE_LOCKED,
        )
    raise ApiError(
        ErrorCode.INVALID_CREDENTIALS,
        "PIN incorrecto.",
        # 403 y no 401: la sesión es válida, lo que falla es la autorización de
        # ESTA operación. Un 401 haría que el cliente cerrara la sesión.
        status_code=status.HTTP_403_FORBIDDEN,
        extra={"intentos_restantes": restantes},
    )
