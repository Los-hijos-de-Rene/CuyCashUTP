"""
Apertura y numeración de cuentas.
"""

import secrets

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Account

# Prefijo de CuyCash. El resto es aleatorio: derivar el número del DNI haría
# que publicar una cuenta publicara el documento de su titular.
PREFIJO = "191"
NUMERO_SISTEMA = "19100000000000"


async def generar_numero(session: AsyncSession) -> str:
    """14 dígitos: prefijo + 11 aleatorios, reintentando ante colisión."""
    for _ in range(20):
        candidato = PREFIJO + "".join(str(secrets.randbelow(10)) for _ in range(11))
        existe = (
            await session.execute(select(Account.id).where(Account.numero == candidato))
        ).scalar_one_or_none()
        if existe is None:
            return candidato
    raise RuntimeError("No se pudo generar un número de cuenta libre")


async def abrir_cuenta(session: AsyncSession, user_id: str) -> Account:
    """Cuenta de ahorros en soles, activa y en cero. No hace commit."""
    cuenta = Account(
        user_id=user_id,
        numero=await generar_numero(session),
        tipo="ahorro",
        moneda="PEN",
        estado="activa",
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(cuenta)
    await session.flush()
    return cuenta


async def cuenta_de_sistema(session: AsyncSession) -> Account:
    """
    La caja de CuyCash: contraparte de toda recarga.

    Se crea bajo demanda (y no al arrancar) para que no dependa del orden de
    arranque ni de que el lifespan haya corrido. No hace commit.
    Su saldo es, por construcción, el negativo del dinero inyectado en la
    demo. Es la única cuenta a la que el CHECK le permite estar en rojo.
    """
    caja = (
        await session.execute(select(Account).where(Account.tipo == "sistema"))
    ).scalar_one_or_none()
    if caja is not None:
        return caja

    caja = Account(
        user_id=None,
        numero=NUMERO_SISTEMA,
        tipo="sistema",
        moneda="PEN",
        estado="activa",
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(caja)
    await session.flush()
    return caja
