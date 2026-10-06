import asyncio
from typing import Optional

from fastapi import APIRouter, Depends, Header, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.deps import bearer_token
from app.core.errors import ApiError, ErrorCode
from app.core.security import ahash_pin, averify_pin, new_token, pin_is_valid, token_digest
from app.db.base import get_session
from app.db.models import Device, OtpTicket, User, utcnow
from app.schemas import AuthenticateIn, CheckPinIn, RegisterIn, ResetPinIn, SessionIn
from app.services import accounts, lockout, otp, sessions

router = APIRouter(prefix="/v1/auth", tags=["Auth"])

# Tokens de un solo uso que acreditan "el PIN fue correcto". Viven en memoria
# porque son de vida muy corta y no sobreviven a un reinicio a propósito.
_pending: dict = {}


async def _uniform_delay(started: float) -> None:
    """
    Iguala la duración de la respuesta.

    Sin esto, un DNI inexistente responde más rápido que uno real —no hay hash
    que verificar— y ese canal temporal reabre la enumeración de cuentas que la
    app cerró con el mensaje genérico.
    """
    restante = settings.UNIFORM_RESPONSE_SECONDS - (asyncio.get_event_loop().time() - started)
    if restante > 0:
        await asyncio.sleep(restante)


def _alias(nombres: str, dni: str) -> str:
    primero = nombres.strip().split()[0].lower() if nombres.strip() else ""
    slug = "".join(c for c in primero if c.isalnum())
    return f"@{slug}" if slug else f"@{dni}"


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterIn,
    x_device_id: str = Header(..., alias="X-Device-Id"),
    session: AsyncSession = Depends(get_session),
):
    if not pin_is_valid(payload.pin):
        raise ApiError(ErrorCode.WEAK_PIN, "Elige un PIN menos previsible.")

    existing = await session.execute(select(User).where(User.dni == payload.dni))
    if existing.scalars().first() is not None:
        raise ApiError(ErrorCode.IDENTIFIER_TAKEN, "Este DNI ya está registrado.")

    user = User(
        dni=payload.dni,
        nombres=payload.nombres,
        apellidos=payload.apellidos,
        email=str(payload.email),
        alias=_alias(payload.nombres, payload.dni),
        pin_hash=await ahash_pin(payload.pin),
    )
    session.add(user)
    await session.flush()
    # Antes del commit a propósito: si la apertura falla, el alta entera
    # revierte. Una identidad sin cuenta no tendría quién la repare.
    await accounts.abrir_cuenta(session, user.id)
    # El alta ABRE sesión y vincula este teléfono.
    #
    # Se puede porque quien llega aquí acaba de probar su identidad con
    # documento y liveness, que es una prueba más fuerte que el código por
    # correo con el que se vincula un teléfono en el login. Exigir además el
    # OTP sería pedir lo menor después de lo mayor, y dejaría la pantalla de
    # éxito sin forma de cumplir lo que promete.
    #
    # El vínculo es de ESTE teléfono, no de la cuenta: entrar desde otro
    # seguirá pidiendo el código.
    session.add(Device(user_id=user.id, device_id=x_device_id))
    token, _ = await sessions.open_session(session, user.id, x_device_id)
    await session.commit()
    return {
        "id": user.id,
        "dni": user.dni,
        "alias": user.alias,
        "full_name": f"{user.nombres} {user.apellidos}".strip(),
        "session_token": token,
    }


@router.post("/authenticate")
async def authenticate(
    payload: AuthenticateIn,
    x_device_id: str = Header(...),
    session: AsyncSession = Depends(get_session),
):
    started = asyncio.get_event_loop().time()

    for kind, value in (("dni", payload.identifier), ("device", x_device_id)):
        bloqueo = await lockout.locked_until(session, kind, value)
        if bloqueo is not None:
            await _uniform_delay(started)
            code = (
                ErrorCode.IDENTIFIER_LOCKED if kind == "dni" else ErrorCode.DEVICE_LOCKED
            )
            raise ApiError(
                code,
                "El ingreso está bloqueado por ahora.",
                status_code=status.HTTP_423_LOCKED,
                extra={"locked_until": bloqueo.isoformat()},
            )

    result = await session.execute(select(User).where(User.dni == payload.identifier))
    user = result.scalars().first()

    # Se verifica el PIN incluso sin usuario, contra un hash de descarte, para
    # que el tiempo de respuesta no revele si el DNI existe.
    ok = (
        await averify_pin(payload.pin, user.pin_hash)
        if user
        else await _burn_cycles(payload.pin)
    )

    if not user or not ok:
        bloqueo = await lockout.register_failure(session, payload.identifier, x_device_id)
        restantes = await lockout.attempts_left(session, payload.identifier)
        await session.commit()
        await _uniform_delay(started)
        if bloqueo is not None:
            raise ApiError(
                ErrorCode.IDENTIFIER_LOCKED,
                "El ingreso está bloqueado por ahora.",
                status_code=status.HTTP_423_LOCKED,
                extra={"locked_until": bloqueo.isoformat()},
            )
        raise ApiError(
            ErrorCode.INVALID_CREDENTIALS,
            "Los datos no son correctos.",
            status_code=status.HTTP_401_UNAUTHORIZED,
            extra={"attempts_left": restantes},
        )

    await lockout.register_success(session, payload.identifier, x_device_id)

    known = await session.execute(
        select(Device).where(Device.user_id == user.id, Device.device_id == x_device_id)
    )
    trusted = known.scalars().first()

    pending = new_token()
    _pending[token_digest(pending)] = (user.id, x_device_id)

    if trusted is not None:
        trusted.last_seen_at = utcnow()
        token, _ = await sessions.open_session(session, user.id, x_device_id)
        await session.commit()
        await _uniform_delay(started)
        return {
            "result": "session",
            "session_token": token,
            "user": {"id": user.id, "dni": user.dni, "alias": user.alias},
        }

    await session.commit()
    await _uniform_delay(started)
    # PIN correcto pero teléfono desconocido: falta el OTP de dispositivo.
    return {
        "result": "device_verification_required",
        "pending_token": pending,
        "masked_email": otp.mask_email(user.email),
    }


async def _burn_cycles(pin: str) -> bool:
    """Hash de descarte: iguala el coste cuando el DNI no existe."""
    await ahash_pin(pin)
    return False


@router.post("/sessions")
async def open_session(
    payload: SessionIn,
    x_device_id: str = Header(...),
    session: AsyncSession = Depends(get_session),
):
    entry = _pending.pop(token_digest(payload.pending_token), None)
    if entry is None:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Vuelve a ingresar tu PIN.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    user_id, device_id = entry
    if device_id != x_device_id:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Vuelve a ingresar tu PIN.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )

    if payload.otp_ticket is None:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Verifica el dispositivo para continuar.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    ticket = await otp.consume_ticket(session, payload.otp_ticket, "device")
    if ticket.user_id != user_id:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Verifica el dispositivo para continuar.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    ticket.used_at = utcnow()
    session.add(Device(user_id=user_id, device_id=x_device_id))

    token, _ = await sessions.open_session(session, user_id, x_device_id)
    await session.commit()
    return {"result": "session", "session_token": token}


@router.delete("/sessions/current", status_code=status.HTTP_204_NO_CONTENT)
async def sign_out(
    authorization: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
):
    # Deliberadamente NO usa `current_session_row`: cerrar sesión es idempotente
    # y responde 204 aunque el token ya esté vencido o revocado. Exigir 401
    # aquí haría fallar el "salir" de la app justo cuando la sesión ya no existe.
    token = bearer_token(authorization)
    if token is not None:
        row = await sessions.resolve(session, token)
        if row is not None:
            await sessions.revoke(session, row)
            await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/pin/check-current")
async def check_current_pin(
    payload: CheckPinIn, session: AsyncSession = Depends(get_session)
):
    """
    ¿El PIN propuesto es el que la cuenta ya tiene?

    Preguntado a discreción sería un ORÁCULO del PIN, así que exige un ticket
    de OTP y cada ticket admite pocas consultas.
    """
    ticket = await otp.consume_ticket(session, payload.otp_ticket, "recovery")
    if ticket.checks_left <= 0:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Verifica tu identidad de nuevo.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    ticket.checks_left -= 1
    await session.flush()

    user = await session.get(User, ticket.user_id) if ticket.user_id else None
    es_actual = bool(user and await averify_pin(payload.pin, user.pin_hash))
    await session.commit()
    return {"is_current": es_actual}


@router.post("/pin/reset")
async def reset_pin(payload: ResetPinIn, session: AsyncSession = Depends(get_session)):
    ticket = await otp.consume_ticket(session, payload.otp_ticket, "recovery")
    if not pin_is_valid(payload.new_pin):
        raise ApiError(ErrorCode.WEAK_PIN, "Elige un PIN menos previsible.")

    user = await session.get(User, ticket.user_id) if ticket.user_id else None
    if user is None:
        # El ticket existe pero no hay cuenta detrás (correo no registrado):
        # se responde igual que en el caso bueno para no delatarlo.
        ticket.used_at = utcnow()
        await session.commit()
        return {"revoked_sessions": 0}

    if await averify_pin(payload.new_pin, user.pin_hash):
        raise ApiError(ErrorCode.PIN_UNCHANGED, "Tu nuevo PIN debe ser distinto al anterior.")

    user.pin_hash = await ahash_pin(payload.new_pin)
    user.pin_updated_at = utcnow()
    ticket.used_at = utcnow()
    # Cambiar el PIN cierra TODAS las sesiones, incluida la de este teléfono:
    # restablecer no otorga acceso.
    revocadas = await sessions.revoke_all(session, user.id)
    await session.commit()
    return {"revoked_sessions": revocadas}
