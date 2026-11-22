"""
Límite diario de pagos con QR, por titular y moneda.

POR QUÉ. Con el QR estático el pagador escribe el monto y el mismo QR admite
muchos pagos. El tope por operación (`MONTO_MAXIMO` de `transfers`) no frena a
quien tiene el teléfono y el PIN de otro: le basta con pagar varias veces. El
límite diario acota el daño de una cuenta comprometida a un día.

QUÉ CUENTA. Todo `pago_qr` que el pagador hace, estático o dinámico, sin
importar desde cuál de sus cuentas: el tope es del TITULAR, no de la cuenta, o
abrir cinco cuentas lo multiplicaría por cinco. Las monedas no se suman entre
sí (no hay tipo de cambio en CuyCash). Envíos y recargas no cuentan aquí.

EL DÍA es el calendario de Lima (UTC-5, sin horario de verano): "hoy" para el
usuario termina a su medianoche, no a la de UTC.

CONCURRENCIA. Dos pagos simultáneos del mismo titular leerían ambos "me queda
cupo" y lo superarían juntos. Por eso la fila se BLOQUEA (FOR UPDATE) antes de
mirar el consumo y no se suelta hasta el commit del pago. La fila se crea con
`INSERT ... ON CONFLICT DO NOTHING`, sin ventana entre mirar y crear. Se
bloquea ANTES que las cuentas del libro mayor y una petición solo toma una
fila de consumo, así que no se forma un ciclo de bloqueos.

REINTENTOS. El consumo se suma solo si el libro mayor registró un pago NUEVO
(`reutilizada=False`). Un reintento no suma ni se rechaza por límite: el pago
ya ocurrió, aunque sea de ayer.
"""

from datetime import date, datetime, timedelta, timezone
from typing import Optional

from fastapi import status
from sqlalchemy import select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError
from app.db.models import QrConsumoDiario

# Céntimos por día y moneda. S/ 5,000 equivale a dos pagos y medio del máximo
# por operación (S/ 2,000); en dólares, aproximadamente lo mismo.
LIMITE_DIARIO_QR = {"PEN": 500_000, "USD": 150_000}

_SIMBOLOS = {"PEN": "S/", "USD": "US$"}
_LIMA = timezone(timedelta(hours=-5))


def hoy_en_lima(ahora: Optional[datetime] = None) -> date:
    return (ahora or datetime.now(timezone.utc)).astimezone(_LIMA).date()


def _clave(user_id: str, moneda: str, fecha: date):
    return (
        QrConsumoDiario.user_id == user_id,
        QrConsumoDiario.moneda == moneda,
        QrConsumoDiario.fecha == fecha,
    )


async def consumido(session: AsyncSession, user_id: str, moneda: str, fecha: date) -> int:
    """Lo pagado ese día, sin bloquear. Para mostrar, no para decidir."""
    valor = await session.scalar(
        select(QrConsumoDiario.consumido).where(*_clave(user_id, moneda, fecha))
    )
    return valor or 0


async def disponible(session: AsyncSession, user_id: str, moneda: str, fecha: date) -> int:
    return max(0, LIMITE_DIARIO_QR[moneda] - await consumido(session, user_id, moneda, fecha))


async def bloquear(session: AsyncSession, user_id: str, moneda: str, fecha: date) -> int:
    """Crea la fila si falta, la bloquea hasta el commit y devuelve lo consumido."""
    insertar = pg_insert if session.get_bind().dialect.name == "postgresql" else sqlite_insert
    await session.execute(
        insertar(QrConsumoDiario)
        .values(user_id=user_id, moneda=moneda, fecha=fecha, consumido=0)
        .on_conflict_do_nothing(index_elements=["user_id", "moneda", "fecha"])
    )
    return await session.scalar(
        select(QrConsumoDiario.consumido)
        .where(*_clave(user_id, moneda, fecha))
        .with_for_update()
    )


def exigir_cupo(ya_consumido: int, monto: int, moneda: str) -> None:
    limite = LIMITE_DIARIO_QR[moneda]
    if ya_consumido + monto <= limite:
        return
    resta = max(0, limite - ya_consumido)
    s = _SIMBOLOS[moneda]
    detalle = (
        f"Superas tu límite diario de pagos con QR ({s} {limite / 100:,.2f}). "
        f"Hoy aún puedes pagar {s} {resta / 100:,.2f}."
        if resta
        else f"Llegaste a tu límite diario de pagos con QR ({s} {limite / 100:,.2f})."
    )
    raise ApiError(
        "QR_DAILY_LIMIT",
        detalle,
        status_code=status.HTTP_400_BAD_REQUEST,
        extra={"limite_centimos": limite, "disponible_centimos": resta, "moneda": moneda},
    )


async def sumar(
    session: AsyncSession, user_id: str, moneda: str, fecha: date, monto: int
) -> None:
    """Solo con la fila ya bloqueada por `bloquear` en esta misma transacción."""
    await session.execute(
        update(QrConsumoDiario)
        .where(*_clave(user_id, moneda, fecha))
        .values(consumido=QrConsumoDiario.consumido + monto)
    )
