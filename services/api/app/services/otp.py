import secrets
from datetime import timedelta, timezone
from typing import Optional, Tuple

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import ApiError, ErrorCode
from app.core.security import new_token, token_digest
from app.db.models import OtpChallenge, OtpTicket, User, utcnow
from app.services import lockout
from app.services.notifier import notifier


def _aware(moment):
    return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc)


def mask_email(email: str) -> str:
    at = email.find("@")
    if at <= 0:
        return email
    return f"{email[0]}{'•' * 5}{email[at:]}"


def _new_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


async def request_challenge(
    session: AsyncSession, purpose: str, identifier: str
) -> dict:
    """
    Abre un reto.

    La respuesta es IDÉNTICA exista o no la cuenta. Si dijera "ese correo no
    está registrado", cualquiera podría averiguar qué cuentas hay probando
    correos: se crea el reto igual, y el aviso simplemente no se envía a nadie.
    """
    bloqueo = await lockout.locked_until(session, "otp", identifier)
    if bloqueo is not None:
        raise ApiError(
            ErrorCode.CHALLENGE_CANCELLED,
            "Este flujo quedó detenido. Vuelve a empezar más tarde.",
            extra={"locked_until": bloqueo.isoformat()},
        )

    user = await _find_user(session, purpose, identifier)
    code = _new_code()
    ahora = utcnow()
    challenge = OtpChallenge(
        purpose=purpose,
        identifier=identifier,
        user_id=user.id if user else None,
        code_hash=token_digest(code),
        expires_at=ahora + timedelta(seconds=settings.OTP_TTL_SECONDS),
        cooldown_until=ahora + timedelta(seconds=settings.OTP_COOLDOWN_SECONDS),
        attempts_left=settings.OTP_MAX_ATTEMPTS,
        resends_left=settings.OTP_MAX_RESENDS,
    )
    session.add(challenge)
    await session.flush()

    if user is not None:
        await notifier.send(user.email, code, purpose)

    correo = user.email if user else identifier
    return {
        "challenge_id": challenge.id,
        "masked_email": mask_email(correo),
        "expires_at": challenge.expires_at,
        "cooldown_until": challenge.cooldown_until,
        "attempts_left": challenge.attempts_left,
        "resends_left": challenge.resends_left,
    }


async def _find_user(
    session: AsyncSession, purpose: str, identifier: str
) -> Optional[User]:
    campo = User.dni if purpose == "device" else User.email
    result = await session.execute(select(User).where(campo == identifier))
    return result.scalars().first()


async def _load(session: AsyncSession, challenge_id: str) -> OtpChallenge:
    result = await session.execute(
        select(OtpChallenge).where(OtpChallenge.id == challenge_id)
    )
    challenge = result.scalar_one_or_none()
    if challenge is None:
        raise ApiError(ErrorCode.CHALLENGE_EXPIRED, "El código ya no es válido.")
    if challenge.cancelled_reason is not None:
        raise ApiError(
            ErrorCode.CHALLENGE_CANCELLED,
            "Este flujo quedó detenido.",
            extra={"reason": challenge.cancelled_reason},
        )
    return challenge


async def verify(session: AsyncSession, challenge_id: str, code: str) -> Tuple[str, dict]:
    challenge = await _load(session, challenge_id)

    if challenge.consumed_at is not None:
        raise ApiError(ErrorCode.CHALLENGE_EXPIRED, "El código ya se usó.")
    # El vencimiento se evalúa ANTES que el código y no consume intentos: no
    # tiene sentido castigar por algo que ya no se podía acertar.
    if utcnow() >= _aware(challenge.expires_at):
        raise ApiError(ErrorCode.CHALLENGE_EXPIRED, "Este código venció.")

    if token_digest(code) != challenge.code_hash:
        challenge.attempts_left -= 1
        if challenge.attempts_left <= 0:
            await _cancel(session, challenge, "attempts")
            raise ApiError(
                ErrorCode.CHALLENGE_CANCELLED,
                "Se detuvo el flujo por intentos fallidos.",
                extra={"reason": "attempts"},
            )
        await session.flush()
        raise ApiError(
            ErrorCode.INVALID_CREDENTIALS,
            "El código no es correcto.",
            extra={"attempts_left": challenge.attempts_left},
        )

    challenge.consumed_at = utcnow()
    ticket = new_token()
    session.add(
        OtpTicket(
            token_hash=token_digest(ticket),
            purpose=challenge.purpose,
            identifier=challenge.identifier,
            user_id=challenge.user_id,
            expires_at=utcnow() + timedelta(seconds=settings.OTP_TICKET_TTL_SECONDS),
        )
    )
    await session.flush()
    return ticket, {"purpose": challenge.purpose}


async def resend(session: AsyncSession, challenge_id: str) -> dict:
    challenge = await _load(session, challenge_id)
    if challenge.resends_left <= 0:
        await _cancel(session, challenge, "resends")
        raise ApiError(
            ErrorCode.CHALLENGE_CANCELLED,
            "Se detuvo el flujo por exceso de reenvíos.",
            extra={"reason": "resends"},
        )

    ahora = utcnow()
    code = _new_code()
    challenge.code_hash = token_digest(code)
    challenge.resends_left -= 1
    challenge.expires_at = ahora + timedelta(seconds=settings.OTP_TTL_SECONDS)
    challenge.cooldown_until = ahora + timedelta(seconds=settings.OTP_COOLDOWN_SECONDS)
    await session.flush()

    if challenge.user_id is not None:
        user = await session.get(User, challenge.user_id)
        if user is not None:
            await notifier.send(user.email, code, challenge.purpose)

    return {
        "expires_at": challenge.expires_at,
        "cooldown_until": challenge.cooldown_until,
        "resends_left": challenge.resends_left,
    }


async def _cancel(session: AsyncSession, challenge: OtpChallenge, reason: str) -> None:
    """
    Invalida el reto y enfría el identificador. Después de esto NO hay camino
    de reenvío: volver a empezar exige rehacer el flujo.
    """
    challenge.cancelled_reason = reason
    from app.db.models import Lockout

    session.add(
        Lockout(
            subject_type="otp",
            subject_value=challenge.identifier,
            level=1,
            locked_until=utcnow() + timedelta(seconds=settings.OTP_LOCKOUT_SECONDS),
        )
    )
    await session.flush()


async def consume_ticket(
    session: AsyncSession, token: str, purpose: str
) -> OtpTicket:
    result = await session.execute(
        select(OtpTicket).where(OtpTicket.token_hash == token_digest(token))
    )
    ticket = result.scalar_one_or_none()
    if (
        ticket is None
        or ticket.used_at is not None
        or ticket.purpose != purpose
        or utcnow() >= _aware(ticket.expires_at)
    ):
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Verifica tu identidad de nuevo.",
            status_code=401,
        )
    return ticket
