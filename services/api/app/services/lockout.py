from datetime import datetime, timedelta, timezone

# Inicio de ventana "desde siempre": una fila recién creada tiene que contar
# el fallo que la creó, no empezar a contar después de él.
EPOCH = datetime(1970, 1, 1, tzinfo=timezone.utc)
from typing import Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.models import Lockout, LoginAttempt, utcnow


async def _get(session: AsyncSession, kind: str, value: str) -> Optional[Lockout]:
    result = await session.execute(
        select(Lockout).where(
            Lockout.subject_type == kind, Lockout.subject_value == value
        )
    )
    return result.scalar_one_or_none()


def _aware(moment: Optional[datetime]) -> Optional[datetime]:
    """SQLite devuelve datetimes sin zona; se normalizan a UTC."""
    if moment is None:
        return None
    return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc)


def _identifier_window_start(entry: Optional[Lockout]) -> datetime:
    """
    Desde cuándo cuentan los fallos del DNI: el último ingreso correcto o
    bloqueo (`updated_at`), pero nunca antes de `IDENTIFIER_WINDOW_SECONDS`.
    Así un fallo suelto de hace días deja de restar intentos.
    """
    reset = (_aware(entry.updated_at) if entry else None) or EPOCH
    ventana = utcnow() - timedelta(seconds=settings.IDENTIFIER_WINDOW_SECONDS)
    return max(reset, ventana)


async def locked_until(
    session: AsyncSession, kind: str, value: str
) -> Optional[datetime]:
    entry = await _get(session, kind, value)
    if entry is None:
        return None
    until = _aware(entry.locked_until)
    return until if until and utcnow() < until else None


async def register_failure(
    session: AsyncSession, dni: str, device_id: str
) -> Optional[datetime]:
    """Como `register_failure_detail`, pero solo devuelve el instante."""
    disparo = await register_failure_detail(session, dni, device_id)
    return disparo[0] if disparo else None


async def register_failure_detail(
    session: AsyncSession, dni: str, device_id: str
) -> Optional[Tuple[datetime, str]]:
    """
    Anota un intento fallido en los DOS contadores y devuelve el bloqueo si
    alguno se disparó.

    Se llama también cuando el DNI no existe: si solo contara para cuentas
    reales, el propio bloqueo delataría cuáles lo son.
    """
    session.add(LoginAttempt(dni=dni, device_id=device_id, succeeded=False))
    await session.flush()

    identifier_until = await _register_identifier_failure(session, dni)
    device_until = await _register_device_failure(session, device_id)

    # Se devuelve también QUÉ sujeto se disparó ('dni' | 'device'): quien
    # responde al cliente necesita el código de error que corresponde, no
    # decir "tu cuenta está bloqueada" cuando el bloqueado es el teléfono.
    candidates = [
        (u, kind)
        for u, kind in ((identifier_until, "dni"), (device_until, "device"))
        if u is not None
    ]
    return max(candidates, key=lambda c: c[0]) if candidates else None


async def _register_identifier_failure(
    session: AsyncSession, dni: str
) -> Optional[datetime]:
    """Contador consecutivo con escalado: 15 min → 1 h → 24 h."""
    entry = await _get(session, "dni", dni)
    if entry is None:
        # `updated_at` marca el INICIO de la ventana de conteo, no la última
        # escritura: por eso arranca en el epoch.
        entry = Lockout(
            subject_type="dni", subject_value=dni, level=0, updated_at=EPOCH
        )
        session.add(entry)
        await session.flush()

    window_start = _identifier_window_start(entry)
    result = await session.execute(
        select(func.count())
        .select_from(LoginAttempt)
        .where(
            LoginAttempt.dni == dni,
            LoginAttempt.succeeded.is_(False),
            LoginAttempt.created_at >= window_start,
        )
    )
    fallos = result.scalar_one()

    if fallos < settings.IDENTIFIER_MAX_ATTEMPTS:
        return None

    entry.level += 1
    niveles = settings.identifier_lockout_levels
    duracion = niveles[min(entry.level, len(niveles)) - 1]
    entry.locked_until = utcnow() + timedelta(seconds=duracion)
    entry.updated_at = utcnow()
    await session.flush()
    return _aware(entry.locked_until)


async def _register_device_failure(
    session: AsyncSession, device_id: str
) -> Optional[datetime]:
    """
    VENTANA DESLIZANTE, no contador que se reinicia.

    Si un login correcto lo pusiera a cero, bastaría con intercalar una entrada
    válida cada N intentos para barrer cuentas indefinidamente. Contando los
    fallos de los últimos minutos, esa maniobra no sirve de nada.
    """
    desde = utcnow() - timedelta(seconds=settings.DEVICE_WINDOW_SECONDS)
    result = await session.execute(
        select(func.count())
        .select_from(LoginAttempt)
        .where(
            LoginAttempt.device_id == device_id,
            LoginAttempt.succeeded.is_(False),
            LoginAttempt.created_at >= desde,
        )
    )
    fallos = result.scalar_one()
    if fallos < settings.DEVICE_MAX_ATTEMPTS:
        return None

    entry = await _get(session, "device", device_id)
    if entry is None:
        entry = Lockout(subject_type="device", subject_value=device_id, level=0)
        session.add(entry)
    entry.level += 1
    entry.locked_until = utcnow() + timedelta(seconds=settings.DEVICE_LOCKOUT_SECONDS)
    entry.updated_at = utcnow()
    await session.flush()
    return _aware(entry.locked_until)


async def register_success(session: AsyncSession, dni: str, device_id: str) -> None:
    """
    Un ingreso correcto limpia el contador del DNI, pero NO el del dispositivo:
    ese usa ventana deslizante justamente para que no se pueda reiniciar.
    """
    session.add(LoginAttempt(dni=dni, device_id=device_id, succeeded=True))
    entry = await _get(session, "dni", dni)
    if entry is not None:
        entry.level = 0
        entry.locked_until = None
        entry.updated_at = utcnow()
    await session.flush()


async def attempts_left(session: AsyncSession, dni: str) -> int:
    entry = await _get(session, "dni", dni)
    window_start = _identifier_window_start(entry)
    fallos = (
        await session.execute(
            select(func.count())
            .select_from(LoginAttempt)
            .where(
                LoginAttempt.dni == dni,
                LoginAttempt.succeeded.is_(False),
                LoginAttempt.created_at >= window_start,
            )
        )
    ).scalar_one()
    return max(settings.IDENTIFIER_MAX_ATTEMPTS - fallos, 0)


def next_lockout_seconds(level: int) -> int:
    niveles = settings.identifier_lockout_levels
    return niveles[min(level, len(niveles) - 1)]
