import asyncio
from typing import Optional

from fastapi import APIRouter, Depends, Header, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.deps import bearer_token, current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.core.security import ahash_pin, averify_pin, new_token, pin_is_valid, token_digest
from app.db.base import get_session
from app.db.models import Device, KycVerification, OtpTicket, User, utcnow
from app.db.models import Session as SessionRow
from app.schemas import (
    AuthenticateIn,
    BiometricSessionIn,
    ChangePinIn,
    CheckPinIn,
    EnrollBiometricIn,
    RegisterIn,
    ResetPinIn,
    SessionIn,
)
from app.services import alias as alias_svc
from app.services import accounts, biometric, devices, kyc_tickets, lockout, otp, pin_check, sessions

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


def _nombre_normalizado(crudo: str) -> str:
    """
    Minúsculas y un solo espacio entre palabras. Se guarda así para que el
    mismo nombre no exista en dos formas ("JAIR" y "Jair"); la app pone la
    mayúscula al mostrarlo.
    """
    return " ".join(crudo.split()).lower()


def _usuario_json(user: User) -> dict:
    """Quién abrió la sesión. Toda respuesta que abre sesión lo devuelve:
    tras cerrar sesión el teléfono olvida al usuario y el login es la única
    fuente del nombre."""
    return {
        "id": user.id,
        "dni": user.dni,
        "alias": user.alias,
        "full_name": f"{user.nombres} {user.apellidos}".strip(),
    }


# Veces que se pide otro alias si un registro simultáneo se llevó el sugerido.
_INTENTOS_DE_ALIAS = 3


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(
    payload: RegisterIn,
    x_device_id: str = Header(..., alias="X-Device-Id", max_length=128),
    x_device_name: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
):
    if not pin_is_valid(payload.pin):
        raise ApiError(ErrorCode.WEAK_PIN, "Elige un PIN menos previsible.")

    existing = await session.execute(select(User).where(User.dni == payload.dni))
    if existing.scalars().first() is not None:
        raise ApiError(ErrorCode.IDENTIFIER_TAKEN, "Este DNI ya está registrado.")

    # El KYC lo decide el SERVIDOR, no la app: sin un ticket de aprobación de
    # este mismo DNI y este mismo teléfono, no hay alta (con KYC_REQUIRED).
    # Un ticket que llega se valida siempre, esté o no encendido el requisito.
    kyc_ticket = None
    if payload.kyc_ticket:
        kyc_ticket = await kyc_tickets.find_valid(
            session, payload.kyc_ticket, payload.dni, x_device_id
        )
    elif settings.KYC_REQUIRED:
        raise ApiError(
            ErrorCode.KYC_REQUIRED,
            "Verifica tu identidad antes de crear la cuenta.",
            status_code=status.HTTP_403_FORBIDDEN,
        )

    nombres = _nombre_normalizado(payload.nombres)
    apellidos = _nombre_normalizado(payload.apellidos)
    pin_hash = await ahash_pin(payload.pin)
    # El alias es único: `libre` sugiere uno que hoy no existe, pero otro
    # registro simultáneo puede llevárselo antes del INSERT. La UNIQUE lo
    # detecta y se pide otro.
    #
    # Se deshace la transacción ENTERA, no un SAVEPOINT: este INSERT es la
    # primera escritura del alta, así que no se pierde nada. Y en SQLite el
    # SAVEPOINT sin BEGIN previo confirma al liberarse, lo que dejaría un
    # usuario sin cuenta si la apertura de abajo falla.
    for _ in range(_INTENTOS_DE_ALIAS):
        user = User(
            dni=payload.dni,
            nombres=nombres,
            apellidos=apellidos,
            email=str(payload.email),
            alias=await alias_svc.libre(session, nombres),
            pin_hash=pin_hash,
        )
        session.add(user)
        try:
            await session.flush()
        except IntegrityError:
            await session.rollback()
            ganador = await session.execute(select(User.id).where(User.dni == payload.dni))
            if ganador.first() is not None:
                raise ApiError(ErrorCode.IDENTIFIER_TAKEN, "Este DNI ya está registrado.")
            continue
        break
    else:
        raise ApiError(
            ErrorCode.SERVICE_UNAVAILABLE,
            "No pudimos completar el registro. Inténtalo de nuevo.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    if kyc_ticket is not None:
        # Después del bucle del alias, que puede deshacer la transacción: si
        # el ticket se consumiera antes, un reintento lo perdería. En la misma
        # transacción que el alta: o quedan las dos cosas, o ninguna.
        await kyc_tickets.consume(session, kyc_ticket.id)
        user.kyc_status = "verified"
        session.add(
            KycVerification(
                user_id=user.id,
                verdict="approved",
                document_valid=kyc_ticket.document_valid,
                is_live=kyc_ticket.is_live,
                face_match=kyc_ticket.face_match,
                face_distance=kyc_ticket.face_distance,
            )
        )
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
    vinculado = Device(user_id=user.id, device_id=x_device_id)
    devices.touch(vinculado, x_device_name)
    session.add(vinculado)
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
    x_device_id: str = Header(..., max_length=128),
    x_device_name: Optional[str] = Header(None),
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
    _pending[token_digest(pending)] = (user.id, x_device_id, x_device_name)

    if trusted is not None:
        trusted.last_seen_at = utcnow()
        devices.touch(trusted, x_device_name)
        token, _ = await sessions.open_session(session, user.id, x_device_id)
        await session.commit()
        await _uniform_delay(started)
        return {
            "result": "session",
            "session_token": token,
            "user": _usuario_json(user),
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
    x_device_id: str = Header(..., max_length=128),
    x_device_name: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
):
    entry = _pending.pop(token_digest(payload.pending_token), None)
    if entry is None:
        raise ApiError(
            ErrorCode.INVALID_TICKET,
            "Vuelve a ingresar tu PIN.",
            status_code=status.HTTP_401_UNAUTHORIZED,
        )
    user_id, device_id, nombre_pendiente = entry
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
    vinculado = Device(user_id=user_id, device_id=x_device_id)
    devices.touch(vinculado, x_device_name or nombre_pendiente)
    session.add(vinculado)

    token, _ = await sessions.open_session(session, user_id, x_device_id)
    user = (
        await session.execute(select(User).where(User.id == user_id))
    ).scalar_one()
    # Se arma antes del commit: tras él los atributos podrían estar expirados.
    cuerpo = {
        "result": "session",
        "session_token": token,
        "user": _usuario_json(user),
    }
    await session.commit()
    return cuerpo


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
    # Y las huellas de todos los teléfonos: si no, la huella abriría la
    # sesión que el restablecimiento acaba de cerrar.
    await biometric.revoke(session, user.id)
    await session.commit()
    return {"revoked_sessions": revocadas}


@router.post("/pin/change")
async def change_pin(
    payload: ChangePinIn,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """
    Cambiar el PIN con la sesión abierta. A diferencia de `/pin/reset`, este
    teléfono sigue dentro: quien lo pide acaba de probar el PIN actual. Los
    OTROS teléfonos pierden sus sesiones y sus huellas.
    """
    await pin_check.verify(session, user, payload.current_pin, row)
    if not pin_is_valid(payload.new_pin):
        raise ApiError(ErrorCode.WEAK_PIN, "Elige un PIN menos previsible.")
    if await averify_pin(payload.new_pin, user.pin_hash):
        raise ApiError(ErrorCode.PIN_UNCHANGED, "Tu nuevo PIN debe ser distinto al anterior.")

    user.pin_hash = await ahash_pin(payload.new_pin)
    user.pin_updated_at = utcnow()
    revocadas = await sessions.revoke_all_except(session, user.id, row.device_id)
    await biometric.revoke(session, user.id, except_device=row.device_id)
    await session.commit()
    return {"revoked_sessions": revocadas}


@router.post("/biometric/enroll")
async def enroll_biometric(
    payload: EnrollBiometricIn,
    row: SessionRow = Depends(current_session_row),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """El secreto se devuelve UNA vez; el servidor solo guarda su hash."""
    await pin_check.verify(session, user, payload.pin, row)
    secreto = await biometric.issue(session, user.id, row.device_id)
    await session.commit()
    return {"credential": secreto}


@router.delete("/biometric/current", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_biometric(
    row: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    await biometric.revoke(session, row.user_id, device_id=row.device_id)
    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


def _biometria_rechazada() -> ApiError:
    # UN solo rechazo para todo: credencial inventada, revocada, de otro
    # teléfono, de otro DNI o DNI inexistente. Distinguirlos delataría cuáles
    # DNI tienen huella activa.
    return ApiError(
        ErrorCode.BIOMETRIC_REVOKED,
        "Entra con tu PIN.",
        status_code=status.HTTP_401_UNAUTHORIZED,
    )


@router.post("/sessions/biometric")
async def biometric_session(
    payload: BiometricSessionIn,
    x_device_id: str = Header(..., max_length=128),
    x_device_name: Optional[str] = Header(None),
    session: AsyncSession = Depends(get_session),
):
    """
    No suma intentos al bloqueo: el secreto tiene 256 bits y no se adivina.
    Pero SÍ respeta un bloqueo vigente: la huella no es un atajo para saltarlo.
    """
    for kind, value in (("dni", payload.dni), ("device", x_device_id)):
        bloqueo = await lockout.locked_until(session, kind, value)
        if bloqueo is not None:
            code = ErrorCode.IDENTIFIER_LOCKED if kind == "dni" else ErrorCode.DEVICE_LOCKED
            raise ApiError(
                code,
                "El ingreso está bloqueado por ahora.",
                status_code=status.HTTP_423_LOCKED,
                extra={"locked_until": bloqueo.isoformat()},
            )

    user = (
        await session.execute(select(User).where(User.dni == payload.dni))
    ).scalars().first()
    if user is None or not await biometric.valid_for(
        session, user.id, x_device_id, payload.credential
    ):
        raise _biometria_rechazada()

    vinculado = (
        await session.execute(
            select(Device).where(Device.user_id == user.id, Device.device_id == x_device_id)
        )
    ).scalars().one()
    vinculado.last_seen_at = utcnow()
    devices.touch(vinculado, x_device_name)
    token, _ = await sessions.open_session(session, user.id, x_device_id)
    await session.commit()
    return {
        "result": "session",
        "session_token": token,
        "user": _usuario_json(user),
    }
