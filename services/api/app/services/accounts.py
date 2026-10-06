"""
Apertura y numeración de cuentas.
"""

import secrets
from typing import Optional

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
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
        # Reservado: es el número fijo de la caja del sistema. Si un titular lo
        # recibiera, crear la caja chocaría después contra la UNIQUE sin pista.
        if candidato == NUMERO_SISTEMA:
            continue
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


async def _buscar_caja(session: AsyncSession) -> Optional[Account]:
    # Por `numero` y no por `tipo`: la UNIQUE de `numero` es lo que de verdad
    # impide una segunda caja, y así la búsqueda es coherente con ella.
    return (
        await session.execute(select(Account).where(Account.numero == NUMERO_SISTEMA))
    ).scalar_one_or_none()


async def cuenta_de_sistema(session: AsyncSession) -> Account:
    """
    La caja de CuyCash: contraparte de toda recarga.

    Se crea bajo demanda (y no al arrancar) para que no dependa del orden de
    arranque ni de que el lifespan haya corrido. No hace commit.
    Su saldo es, por construcción, el negativo del dinero inyectado en la
    demo. Es la única cuenta a la que el CHECK le permite estar en rojo.
    """
    caja = await _buscar_caja(session)
    if caja is not None:
        return caja

    # Dos primeras recargas simultáneas ven "no existe" y ambas insertan: la
    # UNIQUE de `numero` rechaza a la segunda. Sin SAVEPOINT, ese IntegrityError
    # deja la sesión de la petición inutilizable (hay que hacer rollback de todo
    # y reintentar la lectura en la misma sesión no sirve). Con él, solo se
    # deshace el insert y la sesión sigue sirviendo para releer la caja ganadora.
    try:
        async with session.begin_nested():
            session.add(
                Account(
                    user_id=None,
                    numero=NUMERO_SISTEMA,
                    tipo="sistema",
                    moneda="PEN",
                    estado="activa",
                    saldo_disponible=0,
                    saldo_contable=0,
                )
            )
    except IntegrityError:
        caja = await _buscar_caja(session)
        if caja is None:
            raise  # no era la UNIQUE del número: otra restricción, no se disfraza
        return caja
    caja = await _buscar_caja(session)
    assert caja is not None
    return caja
