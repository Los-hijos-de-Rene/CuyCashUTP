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
from app.db.base import get_session
from app.db.models import Account, LedgerEntry, Transaction, Transfer, User
from app.db.models import Session as SessionRow
from app.services import accounts as accounts_service
from app.services.autorizacion import exigir_pin_de_operacion
from app.services.rate_limit import consumir_consulta_de_destinatario
from app.services.ledger import Asiento, post

router = APIRouter(prefix="/v1", tags=["Dinero"])

MONTO_MINIMO = 1
MONTO_MAXIMO = 200_000  # S/ 2,000.00


class TransferIn(BaseModel):
    cuenta_origen_id: str
    cuenta_destino_id: str = Field(min_length=1, max_length=36)
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


SIMBOLOS = {"PEN": "S/", "USD": "US$"}


def _validar_monto(centimos: int, moneda: str) -> None:
    if centimos < MONTO_MINIMO or centimos > MONTO_MAXIMO:
        s = SIMBOLOS[moneda]
        raise ApiError(
            ErrorCode.AMOUNT_OUT_OF_RANGE,
            f"El monto debe estar entre {s} 0.01 y {s} {MONTO_MAXIMO / 100:,.2f}.",
        )


async def _clave_ya_usada(
    session: AsyncSession, idempotency_key: str, cuenta_id: str
) -> bool:
    """
    Si esa clave ya registró una operación QUE TOCA ESTA CUENTA.

    Acotarla a la cuenta es lo que impide que el atajo de reintento se use
    sobre claves ajenas. `Transaction.idempotency_key` es único en todo el
    sistema y la tabla no tiene titular, así que la pregunta "¿esta clave ya se
    usó?" sin acotar la contesta igual para la clave de un desconocido: con eso
    se compraban los relajos que el reintento concede (saltarse
    `ACCOUNT_BLOCKED`, resolver destinatarios no activos) sobre una operación
    que no es del solicitante. El vínculo se busca por los asientos, que son lo
    único que ata una transacción a una cuenta.
    """
    return (
        await session.execute(
            select(LedgerEntry.id)
            .join(Transaction, Transaction.id == LedgerEntry.transaction_id)
            .where(
                Transaction.idempotency_key == idempotency_key,
                LedgerEntry.account_id == cuenta_id,
            )
            .limit(1)
        )
    ).scalars().first() is not None


async def _destino_original(
    session: AsyncSession, cuenta_origen_id: str, idempotency_key: str
) -> Optional[Account]:
    """
    La cuenta destino del envío que esa clave YA registró desde esta cuenta;
    `None` si no hay tal envío.

    Un reintento no vuelve a buscar el destino del payload: es el de la
    operación original. Así no consulta el padrón ni gasta presupuesto, ni
    puede distinguir "no existe" de "existe bloqueada".
    """
    return (
        await session.execute(
            select(Account)
            .join(Transfer, Transfer.cuenta_destino == Account.id)
            .join(Transaction, Transaction.id == Transfer.transaction_id)
            .where(
                Transaction.idempotency_key == idempotency_key,
                Transfer.cuenta_origen == cuenta_origen_id,
            )
            .limit(1)
        )
    ).scalars().first()


def _clave_reusada() -> ApiError:
    return ApiError(
        ErrorCode.IDEMPOTENCY_KEY_REUSED,
        "Esa operación ya se envió con otros datos. Vuelve a empezar.",
        status_code=status.HTTP_409_CONFLICT,
    )


async def _cuenta_propia(
    session: AsyncSession, user: User, cuenta_id: str, idempotency_key: str
) -> Tuple[Account, bool]:
    """
    La cuenta del titular y si la petición es el reintento de una operación ya
    registrada SOBRE ESA CUENTA.

    Orden deliberado: 404 por cuenta ajena PRIMERO, luego la clave, luego el
    estado. Si el antifraude bloquea la cuenta por un envío cuya respuesta se
    perdió, el reintento debe recibir la transacción original (200) y no un
    "tu cuenta no está activa" que no dice nada sobre su dinero. Un reintento
    con datos distintos sigue acabando en 409 dentro del motor.
    """
    cuenta = await _buscar_cuenta_propia(session, user, cuenta_id)
    reintento = await _clave_ya_usada(session, idempotency_key, cuenta.id)
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
    origen = await _buscar_cuenta_propia(session, user, payload.cuenta_origen_id)

    if payload.cuenta_destino_id == origen.id:
        raise ApiError(ErrorCode.SAME_ACCOUNT, "Elige una cuenta distinta a la de origen.")

    destino = await _destino_original(session, origen.id, payload.idempotency_key)
    if destino is not None:
        # REINTENTO del MISMO envío desde la MISMA cuenta. No se vuelve a tocar
        # el padrón: el destino es el de la operación original, así que esta
        # rama no distingue "esa cuenta no existe" de "existe pero está
        # bloqueada" y no descuenta presupuesto. Esto último es lo que hace
        # posible la pregunta "¿se cobró?": quien tiene un envío con resultado
        # desconocido debe poder repetirlo hasta saberlo, y un 429 lo dejaría
        # sin respuesta para siempre.
        if destino.id != payload.cuenta_destino_id:
            # La clave es de un envío a OTRA cuenta (aunque sea de la misma
            # persona): devolver la original haría creer al usuario que envió
            # a donde acaba de elegir. La respuesta no depende de si la cuenta
            # del payload existe, así que no es oráculo.
            raise _clave_reusada()
    else:
        if origen.estado != "activa":
            raise ApiError(
                ErrorCode.ACCOUNT_BLOCKED,
                "Esa cuenta no está activa.",
                status_code=status.HTTP_409_CONFLICT,
            )
        # Buscar una cuenta por id también es un oráculo (existe o no): responde
        # 404 antes de verificar el PIN, así que no gasta intentos de bloqueo.
        # Comparte presupuesto con `/directory/resolve`; si no, se esquivaría
        # usando la ruta sin tope.
        consumir_consulta_de_destinatario(user.id)
        destino = (
            await session.execute(
                select(Account).where(
                    Account.id == payload.cuenta_destino_id,
                    # Una caja no es un destinatario, y una cuenta bloqueada
                    # tampoco: la respuesta es la de una cuenta inexistente.
                    Account.tipo != "sistema",
                    Account.estado == "activa",
                )
            )
        ).scalar_one_or_none()
        if destino is None:
            raise ApiError(
                ErrorCode.RECIPIENT_NOT_FOUND,
                "No encontramos esa cuenta en CuyCash.",
                status_code=status.HTTP_404_NOT_FOUND,
            )
        if destino.moneda != origen.moneda:
            # Antes del PIN: no gasta intentos. Y antes del motor, cuyo
            # `assert` de monedas es la última defensa, no la respuesta.
            raise ApiError(
                ErrorCode.CURRENCY_MISMATCH,
                "Solo puedes enviar entre cuentas de la misma moneda.",
            )

    _validar_monto(payload.monto_centimos, origen.moneda)
    await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)

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
    _validar_monto(payload.monto_centimos, cuenta.moneda)
    await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)

    caja = await accounts_service.cuenta_de_sistema(session, cuenta.moneda)
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
