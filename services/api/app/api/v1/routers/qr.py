"""
Cobros y pagos con QR (issue #77).

Dos tipos de QR, como en el estándar EMVCo (estático/dinámico):
- Estático ("Mi QR"): identifica la cuenta que recibe; el pagador elige el
  monto. Permanente, admite muchos pagos, se revoca al regenerarlo.
- Dinámico (cobro): monto fijo, caduca y admite un solo pago.

El token del QR es una referencia firmada a una fila de `qr_codigos`
(`app/services/qr_firmado.py`): lo que el QR vale lo decide el servidor.

El PIN se exige SIEMPRE para pagar. Con un umbral sin PIN, quien robara una
sesión vaciaría la cuenta en pagos chicos: con monto libre, el pagador decide
cuánto, y con cobros dinámicos el atacante puede emitirlos él mismo.

Además hay un límite diario por titular y moneda (`app/services/limite_diario.py`):
el PIN frena a quien no lo sabe; el límite acota el daño de quien sí.
"""

import os
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Response, status
from pydantic import BaseModel, Field, StrictInt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routers.accounts import _iso
from app.api.v1.routers.transfers import _buscar_cuenta_propia, _validar_monto
from app.core.deps import current_session_row, current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, QrCodigo, Transaction, Transfer, User, utcnow
from app.db.models import Session as SessionRow
from app.services import limite_diario
from app.services.autorizacion import exigir_pin_de_operacion
from app.services.ledger import Asiento, post
from app.services.qr_firmado import (
    clave_de_pago_libre,
    huella_de_pago,
    leer_token,
    nuevo_id,
    token_de,
)

router = APIRouter(prefix="/v1/qr", tags=["QR"])


class QREmitirIn(BaseModel):
    cuenta_id: str = Field(min_length=1, max_length=36)
    monto_centimos: StrictInt
    concepto: str = Field(default="", max_length=40)
    caducidad_segundos: StrictInt = Field(default=300, ge=30, le=86400)


class QREstaticoIn(BaseModel):
    cuenta_id: str = Field(min_length=1, max_length=36)


class QRValidarIn(BaseModel):
    qr: str = Field(min_length=1, max_length=2048)
    # Una app que no lo manda no sabe pedir un monto: ante un QR estático se le
    # responde `QR_UPDATE_REQUIRED` en vez de un `monto_centimos` null que la
    # haría fallar al leerlo.
    acepta_monto_libre: bool = False


class QRPagarIn(BaseModel):
    qr: str = Field(min_length=1, max_length=2048)
    cuenta_origen_id: str = Field(min_length=1, max_length=36)
    idempotency_key: str = Field(min_length=8, max_length=64)
    pin: Optional[str] = Field(default=None, max_length=64)
    # Obligatorio para un QR estático. En uno dinámico es opcional y, si llega,
    # debe ser el del cobro.
    monto_centimos: Optional[StrictInt] = None
    # Nota del pagador en un QR estático. `transfers.motivo` es VARCHAR(40).
    mensaje: Optional[str] = Field(default=None, max_length=40)


def _secreto_firma() -> str:
    secreto = os.environ.get("QR_SIGNING_SECRET", "")
    if len(secreto.encode("utf-8")) < 32:
        raise ApiError(
            "QR_NOT_CONFIGURED",
            "El servicio QR no está disponible.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    return secreto


def _error(codigo: str, mensaje: str, http: int = status.HTTP_400_BAD_REQUEST) -> ApiError:
    return ApiError(codigo, mensaje, status_code=http)


def _qr_invalido() -> ApiError:
    # Firma mala, forma mala o id que no existe responden igual: distinguirlos
    # le diría a quien prueba tokens cuáles existen.
    return _error("QR_INVALID", "El QR es inválido o ha vencido.")


def _qr_ya_pagado() -> ApiError:
    return _error("QR_ALREADY_PAID", "Este QR ya fue pagado.", status.HTTP_409_CONFLICT)


def _aware(momento: datetime) -> datetime:
    # SQLite devuelve fechas sin zona aunque se guarden con ella.
    return momento if momento.tzinfo else momento.replace(tzinfo=timezone.utc)


async def _fila_qr(session: AsyncSession, token: str) -> QrCodigo:
    """Resuelve el token a su fila SIN mirar vigencia: eso depende del caso."""
    try:
        qr_id = leer_token(token, secreto=_secreto_firma())
    except ValueError as exc:
        raise _qr_invalido() from exc
    fila = await session.get(QrCodigo, qr_id)
    if fila is None:
        raise _qr_invalido()
    return fila


def _exigir_vigente(fila: QrCodigo) -> None:
    if fila.estado != "activo":
        raise _error("QR_REVOKED", "Este QR ya no está activo. Pide uno nuevo.")
    if fila.expires_at is not None and utcnow() >= _aware(fila.expires_at):
        raise _error("QR_EXPIRED", "El QR ha vencido.")


def _ocultar_nombre(texto: str) -> str:
    primera = (texto or "").strip().split()
    if not primera:
        return "***"
    nombre = primera[0]
    return nombre[0] + "*" * min(max(len(nombre) - 1, 2), 5)


async def _destino_visible(session: AsyncSession, cuenta_id: str) -> tuple[Account, User]:
    resultado = await session.execute(
        select(Account, User)
        .join(User, User.id == Account.user_id)
        .where(
            Account.id == cuenta_id,
            Account.tipo != "sistema",
            Account.estado == "activa",
        )
    )
    encontrado = resultado.first()
    if encontrado is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos esa cuenta en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return encontrado[0], encontrado[1]


def _es_libre(fila: QrCodigo) -> bool:
    return fila.tipo == "estatico"


def _resumen(fila: QrCodigo, destino: Account, titular: User) -> dict:
    libre = _es_libre(fila)
    if not libre:
        _validar_monto(fila.monto, destino.moneda)
    return {
        "tipo": "libre" if libre else "fijo",
        "cuenta_destino_id": destino.id,
        "nombre_enmascarado": (
            f"{_ocultar_nombre(titular.nombres)} {_ocultar_nombre(titular.apellidos)}"
        ),
        "monto_centimos": None if libre else fila.monto,
        "moneda": destino.moneda,
        "concepto": fila.concepto,
        "caduca_en": None if libre else _aware(fila.expires_at).isoformat(),
        # Siempre: el campo queda porque los APK publicados lo leen.
        "requiere_pin": True,
    }


async def _cuenta_para_cobrar(session: AsyncSession, user: User, cuenta_id: str) -> Account:
    cuenta = await _buscar_cuenta_propia(session, user, cuenta_id)
    if cuenta.tipo == "sistema" or cuenta.estado != "activa":
        raise ApiError(
            ErrorCode.ACCOUNT_BLOCKED,
            "Esa cuenta no está disponible.",
            status_code=status.HTTP_409_CONFLICT,
        )
    return cuenta


def _qr_estatico_respuesta(fila: QrCodigo, cuenta: Account, secreto: str) -> dict:
    return {
        "id": fila.id,
        "qr": token_de(fila.id, secreto=secreto),
        "tipo": "libre",
        "cuenta_id": cuenta.id,
        "moneda": cuenta.moneda,
        "created_at": _iso(fila.created_at),
    }


async def _bloquear_cuenta(session: AsyncSession, cuenta_id: str) -> None:
    # Serializa "Mi QR" por cuenta: dos pedidos a la vez verían "no hay" y el
    # segundo chocaría contra el índice parcial. En SQLite no hace nada (la
    # base entera se serializa sola).
    await session.execute(
        select(Account.id).where(Account.id == cuenta_id).with_for_update()
    )


async def _estatico_activo(session: AsyncSession, cuenta_id: str) -> Optional[QrCodigo]:
    return (
        await session.execute(
            select(QrCodigo).where(
                QrCodigo.cuenta_id == cuenta_id,
                QrCodigo.tipo == "estatico",
                QrCodigo.estado == "activo",
            )
        )
    ).scalar_one_or_none()


def _nuevo_estatico(cuenta_id: str) -> QrCodigo:
    return QrCodigo(
        id=nuevo_id(), cuenta_id=cuenta_id, tipo="estatico", estado="activo",
        concepto="", created_at=utcnow(),
    )


@router.post("/estatico")
async def mi_qr(
    payload: QREstaticoIn,
    response: Response,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """El QR permanente de una cuenta: lo devuelve si existe y si no, lo crea."""
    cuenta = await _cuenta_para_cobrar(session, user, payload.cuenta_id)
    secreto = _secreto_firma()
    await _bloquear_cuenta(session, cuenta.id)
    fila = await _estatico_activo(session, cuenta.id)
    creado = fila is None
    if creado:
        fila = _nuevo_estatico(cuenta.id)
        session.add(fila)
        await session.flush()
    cuerpo = _qr_estatico_respuesta(fila, cuenta, secreto)
    await session.commit()
    response.status_code = status.HTTP_201_CREATED if creado else status.HTTP_200_OK
    return cuerpo


@router.post("/estatico/regenerar", status_code=status.HTTP_201_CREATED)
async def regenerar_mi_qr(
    payload: QREstaticoIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """Revoca el QR permanente vigente (si hay) y emite otro, en una transacción."""
    cuenta = await _cuenta_para_cobrar(session, user, payload.cuenta_id)
    secreto = _secreto_firma()
    await _bloquear_cuenta(session, cuenta.id)
    anterior = await _estatico_activo(session, cuenta.id)
    if anterior is not None:
        anterior.estado = "revocado"
        anterior.revocado_at = utcnow()
        # El índice parcial exige que el viejo deje de estar activo ANTES de
        # insertar el nuevo.
        await session.flush()
    fila = _nuevo_estatico(cuenta.id)
    session.add(fila)
    await session.flush()
    cuerpo = _qr_estatico_respuesta(fila, cuenta, secreto)
    await session.commit()
    return cuerpo


@router.post("/emitir", status_code=status.HTTP_201_CREATED)
async def emitir(
    payload: QREmitirIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """Cobro dinámico: monto fijo, un solo pago y caducidad."""
    cuenta = await _cuenta_para_cobrar(session, user, payload.cuenta_id)
    _validar_monto(payload.monto_centimos, cuenta.moneda)
    secreto = _secreto_firma()
    expira = utcnow() + timedelta(seconds=payload.caducidad_segundos)
    fila = QrCodigo(
        id=nuevo_id(),
        cuenta_id=cuenta.id,
        tipo="dinamico",
        monto=payload.monto_centimos,
        concepto=payload.concepto.strip(),
        expires_at=expira,
        estado="activo",
        created_at=utcnow(),
    )
    session.add(fila)
    cuerpo = {
        "id": fila.id,
        "qr": token_de(fila.id, secreto=secreto),
        "monto_centimos": payload.monto_centimos,
        "moneda": cuenta.moneda,
        "concepto": fila.concepto,
        "caduca_en": expira.isoformat(),
    }
    await session.commit()
    return cuerpo


@router.post("/validar")
async def consultar(
    payload: QRValidarIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """Lo que el pagador ve antes de confirmar. No mueve dinero."""
    fila = await _fila_qr(session, payload.qr)
    _exigir_vigente(fila)
    if _es_libre(fila) and not payload.acepta_monto_libre:
        raise _error(
            "QR_UPDATE_REQUIRED",
            "Actualiza CuyCash para pagar este QR.",
        )
    destino, titular = await _destino_visible(session, fila.cuenta_id)
    resumen = _resumen(fila, destino, titular)
    if not _es_libre(fila):
        # Avisa antes de pedir el PIN, no al confirmar.
        pagado = await session.scalar(
            select(Transaction.id).where(Transaction.idempotency_key == huella_de_pago(fila.id))
        )
        if pagado is not None:
            raise _qr_ya_pagado()
    # Para que la app avise antes de pedir el PIN. Informativo: el que decide
    # es `/pagar`, con la fila bloqueada.
    resumen["disponible_hoy_centimos"] = await limite_diario.disponible(
        session, user.id, destino.moneda, limite_diario.hoy_en_lima()
    )
    return resumen


@router.post("/pagar")
async def pagar(
    payload: QRPagarIn,
    response: Response,
    user: User = Depends(current_user),
    sesion: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    fila = await _fila_qr(session, payload.qr)
    libre = _es_libre(fila)
    origen = await _buscar_cuenta_propia(session, user, payload.cuenta_origen_id)
    if origen.id == fila.cuenta_id:
        raise ApiError(
            ErrorCode.SAME_ACCOUNT,
            "Elige una cuenta distinta a la de destino.",
        )

    if libre:
        # La clave del cliente, acotada a su titular: el mismo QR admite muchos
        # pagos y cada uno es su propia operación.
        clave = clave_de_pago_libre(user.id, payload.idempotency_key)
        mensaje = (payload.mensaje or "").strip() or None
        huella = f"qr={fila.id}|mensaje={mensaje or ''}"
    else:
        # La clave es el QR: su UNIQUE deja un solo pago, incluso con dos a la
        # vez. La del cliente va en la huella: repetirla es un reintento y
        # devuelve el pago original; otra clave es un segundo pago y se rechaza.
        clave = huella_de_pago(fila.id)
        mensaje = fila.concepto or None
        huella = f"clave={payload.idempotency_key}"

    # Un pago que ya entró se puede volver a preguntar aunque el QR haya
    # vencido o se haya revocado después: un QR_EXPIRED le haría creer al
    # usuario que no pagó. Decide el libro mayor (misma huella o 409).
    ya_registrado = await session.scalar(
        select(Transaction.id).where(Transaction.idempotency_key == clave)
    )
    if ya_registrado is None:
        _exigir_vigente(fila)

    if libre:
        if payload.monto_centimos is None:
            raise _error("QR_AMOUNT_REQUIRED", "Ingresa el monto que vas a pagar.")
        monto = payload.monto_centimos
    else:
        if payload.monto_centimos is not None and payload.monto_centimos != fila.monto:
            raise _error("QR_AMOUNT_FIXED", "El monto de este cobro no se puede cambiar.")
        monto = fila.monto

    destino, titular = await _destino_visible(session, fila.cuenta_id)
    if origen.moneda != destino.moneda:
        raise ApiError(
            ErrorCode.CURRENCY_MISMATCH,
            "Solo puedes pagar entre cuentas de la misma moneda.",
        )
    _validar_monto(monto, destino.moneda)

    # El cupo del día se bloquea ANTES del PIN (no gastar intentos en un pago
    # que iba a rechazarse) y se suma DESPUÉS del libro mayor, solo si el pago
    # es nuevo. La clave se vuelve a mirar con la fila ya bloqueada: un
    # reintento que esperó al pago original no debe chocar con el límite que
    # ese mismo pago consumió.
    hoy = limite_diario.hoy_en_lima()
    ya_consumido = await limite_diario.bloquear(session, user.id, origen.moneda, hoy)
    if ya_registrado is None:
        ya_registrado = await session.scalar(
            select(Transaction.id).where(Transaction.idempotency_key == clave)
        )
    if ya_registrado is None:
        limite_diario.exigir_cupo(ya_consumido, monto, origen.moneda)

    if not payload.pin:
        raise _error(
            "QR_AUTH_REQUIRED",
            "Confirma el pago con tu PIN.",
            status.HTTP_403_FORBIDDEN,
        )
    await exigir_pin_de_operacion(session, user, sesion.device_id, payload.pin)

    try:
        tx, reutilizada = await post(
            session,
            tipo="pago_qr",
            asientos=[
                Asiento(origen.id, "debito", monto),
                Asiento(destino.id, "credito", monto),
            ],
            idempotency_key=clave,
            fingerprint=huella,
            referencia=f"qr:{fila.id}",
        )
    except ApiError as exc:
        if not libre and exc.detail["code"] == ErrorCode.IDEMPOTENCY_KEY_REUSED:
            raise _qr_ya_pagado() from exc
        raise
    if not reutilizada:
        await limite_diario.sumar(session, user.id, origen.moneda, hoy, monto)
        session.add(
            Transfer(
                transaction_id=tx.id,
                cuenta_origen=origen.id,
                cuenta_destino=destino.id,
                monto=monto,
                motivo=mensaje,
                estado="confirmada",
            )
        )
    cuerpo = {
        "transaction_id": tx.id,
        "estado": tx.estado,
        "monto_centimos": monto,
        "moneda": origen.moneda,
        "created_at": _iso(tx.created_at),
    }
    await session.commit()
    response.status_code = status.HTTP_200_OK if reutilizada else status.HTTP_201_CREATED
    return cuerpo
