"""
Movimiento de dinero: envío entre personas (HU06) y recarga de saldo.

El PIN se verifica EL ÚLTIMO, después de validar cuenta, destinatario y monto.
Verificarlo antes gastaría intentos de bloqueo en peticiones que iban a
fallar igual, y el bloqueo es una defensa demasiado cara para desperdiciarla.

Los `ApiError` de `ledger.post` se dejan propagar: el motor no hace rollback y
seguir usando la sesión tras un fallo escribiría basura. Al cerrarse la sesión
sin commit, todo lo pendiente se descarta.
"""

from typing import Optional, Tuple

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel, Field, StrictInt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routers.accounts import _iso
from app.core.deps import current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.core.security import averify_pin
from app.db.base import get_session
from app.db.models import Account, Transaction, Transfer, User
from app.db.models import Session as SessionRow
from app.services import accounts as accounts_service
from app.services import lockout
from app.services.rate_limit import consumir_consulta_de_destinatario
from app.services.ledger import Asiento, post

router = APIRouter(prefix="/v1", tags=["Dinero"])

MONTO_MINIMO = 1
MONTO_MAXIMO = 200_000  # S/ 2,000.00


class TransferIn(BaseModel):
    cuenta_origen_id: str
    destinatario_dni: str = Field(min_length=8, max_length=8, pattern=r"^\d{8}$")
    # StrictInt: dinero es entero de céntimos; que "100" o 100.7 se coerzan en
    # silencio es justo lo que no debe pasar aquí.
    monto_centimos: StrictInt
    motivo: Optional[str] = Field(default=None, max_length=40)
    pin: str
    idempotency_key: str = Field(min_length=8, max_length=64)


class TopUpIn(BaseModel):
    cuenta_id: str
    monto_centimos: StrictInt
    pin: str
    idempotency_key: str = Field(min_length=8, max_length=64)


def _validar_monto(centimos: int) -> None:
    if centimos < MONTO_MINIMO or centimos > MONTO_MAXIMO:
        raise ApiError(
            ErrorCode.AMOUNT_OUT_OF_RANGE,
            f"El monto debe estar entre S/ 0.01 y S/ {MONTO_MAXIMO / 100:,.2f}.",
        )


async def _clave_ya_usada(session: AsyncSession, idempotency_key: str) -> bool:
    return (
        await session.execute(
            select(Transaction.id).where(Transaction.idempotency_key == idempotency_key)
        )
    ).scalar_one_or_none() is not None


async def _cuenta_propia(
    session: AsyncSession, user: User, cuenta_id: str, idempotency_key: str
) -> Tuple[Account, bool]:
    """
    La cuenta del titular y si la petición es el reintento de una operación ya
    registrada.

    Orden deliberado: 404 por cuenta ajena PRIMERO, luego la clave, luego el
    estado. Si el antifraude bloquea la cuenta por un envío cuya respuesta se
    perdió, el reintento debe recibir la transacción original (200) y no un
    "tu cuenta no está activa" que no dice nada sobre su dinero. Un reintento
    con datos distintos sigue acabando en 409 dentro del motor.
    """
    cuenta = await _buscar_cuenta_propia(session, user, cuenta_id)
    reintento = await _clave_ya_usada(session, idempotency_key)
    if cuenta.estado != "activa" and not reintento:
        raise ApiError(
            ErrorCode.ACCOUNT_BLOCKED,
            "Esa cuenta no está activa.",
            status_code=status.HTTP_409_CONFLICT,
        )
    return cuenta, reintento


async def _buscar_cuenta_propia(
    session: AsyncSession, user: User, cuenta_id: str
) -> Account:
    # Filtrar por titular en la consulta: una cuenta ajena es indistinguible de
    # una inexistente, así no se confirma qué ids existen.
    cuenta = (
        await session.execute(
            select(Account).where(Account.id == cuenta_id, Account.user_id == user.id)
        )
    ).scalar_one_or_none()
    if cuenta is None:
        raise ApiError(
            ErrorCode.ACCOUNT_NOT_FOUND,
            "No encontramos esa cuenta.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return cuenta


def _bloqueado(hasta, code: str = ErrorCode.IDENTIFIER_LOCKED) -> ApiError:
    return ApiError(
        code,
        "Tu cuenta está bloqueada por ahora.",
        status_code=status.HTTP_423_LOCKED,
        extra={"locked_until": hasta.isoformat()},
    )


async def _exigir_pin(
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


def _respuesta(tx: Transaction, monto: int) -> dict:
    return {
        "transaction_id": tx.id,
        "estado": tx.estado,
        "monto_centimos": monto,
        "created_at": _iso(tx.created_at),
    }


@router.post("/transfers")
async def transferir(
    payload: TransferIn,
    response: Response,
    user: User = Depends(current_user),
    sesion: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    origen, reintento = await _cuenta_propia(
        session, user, payload.cuenta_origen_id, payload.idempotency_key
    )

    if payload.destinatario_dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes enviarte dinero a ti mismo.")

    # Esta búsqueda es un oráculo del padrón: responde 404 antes de verificar
    # el PIN, así que no gasta intentos de bloqueo. Comparte presupuesto con
    # `/directory/resolve`; si no, se esquivaría usando la ruta sin tope. Se
    # cobra también en los reintentos: su búsqueda no filtra por estado y el
    # destinatario del payload es el que quiera el cliente.
    consumir_consulta_de_destinatario(user.id)

    consulta = (
        select(Account)
        .join(User, User.id == Account.user_id)
        .where(User.dni == payload.destinatario_dni, Account.tipo == "ahorro")
        .order_by(Account.created_at, Account.id)
    )
    if not reintento:
        # (Hoy `abrir_cuenta` crea UNA cuenta de ahorro por persona; con
        # multicuenta, el destino de un reintento debería resolverse desde la
        # transacción original y no por "la primera cuenta".)
        # En un reintento el destino pudo bloquearse después del envío; el
        # motor devuelve la original sin mirar estados.
        consulta = consulta.where(Account.estado == "activa")
    destino = (await session.execute(consulta)).scalars().first()
    if destino is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )

    _validar_monto(payload.monto_centimos)
    await _exigir_pin(session, user, sesion.device_id, payload.pin)

    # Cuentas y montos ya los incorpora el motor a la huella; solo se aporta lo
    # que él no ve. El motivo en blanco y el ausente son la misma petición.
    motivo = (payload.motivo or "").strip() or None
    tx, reutilizada = await post(
        session,
        tipo="transferencia",
        asientos=[
            Asiento(origen.id, "debito", payload.monto_centimos),
            Asiento(destino.id, "credito", payload.monto_centimos),
        ],
        idempotency_key=payload.idempotency_key,
        fingerprint=f"motivo={motivo or ''}",
    )
    if not reutilizada:
        session.add(
            Transfer(
                transaction_id=tx.id,
                cuenta_origen=origen.id,
                cuenta_destino=destino.id,
                monto=payload.monto_centimos,
                motivo=motivo,
                estado="confirmada",
            )
        )
    # La respuesta se arma ANTES del commit: tras él los atributos podrían estar
    # expirados y leerlos en async reventaría.
    cuerpo = _respuesta(tx, payload.monto_centimos)
    await session.commit()

    response.status_code = status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    return cuerpo


@router.post("/topups")
async def recargar(
    payload: TopUpIn,
    response: Response,
    user: User = Depends(current_user),
    sesion: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    """
    Cash-in simulado.

    El dinero sale de la caja de CuyCash, que es la única cuenta a la que el
    esquema le permite quedar en negativo. Sin esa contraparte el asiento no
    cuadraría y la conciliación de la épica 6 no tendría nada que cuadrar.
    """
    cuenta, _ = await _cuenta_propia(
        session, user, payload.cuenta_id, payload.idempotency_key
    )
    _validar_monto(payload.monto_centimos)
    await _exigir_pin(session, user, sesion.device_id, payload.pin)

    caja = await accounts_service.cuenta_de_sistema(session)
    tx, reutilizada = await post(
        session,
        tipo="recarga",
        asientos=[
            Asiento(caja.id, "debito", payload.monto_centimos),
            Asiento(cuenta.id, "credito", payload.monto_centimos),
        ],
        idempotency_key=payload.idempotency_key,
        fingerprint="",  # tipo, cuenta y monto ya los deriva el motor
    )
    cuerpo = _respuesta(tx, payload.monto_centimos)
    await session.commit()

    response.status_code = status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    return cuerpo
