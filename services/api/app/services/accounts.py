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
# Una caja por moneda: el libro cuadra por moneda y una recarga en dólares no
# puede salir de la caja de soles.
NUMEROS_SISTEMA = {"PEN": "19100000000000", "USD": "19100000000001"}
NUMERO_SISTEMA = NUMEROS_SISTEMA["PEN"]
MAX_CUENTAS = 5


async def generar_numero(session: AsyncSession) -> str:
    """14 dígitos: prefijo + 11 aleatorios, reintentando ante colisión."""
    for _ in range(20):
        candidato = PREFIJO + "".join(str(secrets.randbelow(10)) for _ in range(11))
        # Reservados: los números fijos de las cajas. Si un titular recibiera
        # uno, crear esa caja chocaría después contra la UNIQUE sin pista.
        if candidato in NUMEROS_SISTEMA.values():
            continue
        existe = (
            await session.execute(select(Account.id).where(Account.numero == candidato))
        ).scalar_one_or_none()
        if existe is None:
            return candidato
    raise RuntimeError("No se pudo generar un número de cuenta libre")


async def abrir_cuenta(
    session: AsyncSession,
    user_id: str,
    *,
    tipo: str = "ahorro",
    moneda: str = "PEN",
    nombre: Optional[str] = None,
    idempotency_key: Optional[str] = None,
) -> Account:
    """Cuenta activa y en cero. No valida reglas de negocio ni hace commit."""
    cuenta = Account(
        user_id=user_id,
        numero=await generar_numero(session),
        tipo=tipo,
        moneda=moneda,
        estado="activa",
        nombre=nombre,
        idempotency_key=idempotency_key,
        saldo_disponible=0,
        saldo_contable=0,
    )
    session.add(cuenta)
    await session.flush()
    return cuenta


async def _buscar_caja(session: AsyncSession, moneda: str = "PEN") -> Optional[Account]:
    # Por `numero` y no por `tipo`: la UNIQUE de `numero` es lo que de verdad
    # impide una segunda caja, y así la búsqueda es coherente con ella.
    return (
        await session.execute(
            select(Account).where(Account.numero == NUMEROS_SISTEMA[moneda])
        )
    ).scalar_one_or_none()


async def cuenta_de_sistema(session: AsyncSession, moneda: str = "PEN") -> Account:
    """
    La caja de CuyCash en esa moneda: contraparte de toda recarga.

    Se crea bajo demanda (y no al arrancar) para que no dependa del orden de
    arranque ni de que el lifespan haya corrido. No hace commit.
    Su saldo es, por construcción, el negativo del dinero inyectado en la
    demo. Es la única cuenta a la que el CHECK le permite estar en rojo.
    """
    caja = await _buscar_caja(session, moneda)
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
                    numero=NUMEROS_SISTEMA[moneda],
                    tipo="sistema",
                    moneda=moneda,
                    estado="activa",
                    saldo_disponible=0,
                    saldo_contable=0,
                )
            )
    except IntegrityError:
        caja = await _buscar_caja(session, moneda)
        if caja is None:
            raise  # no era la UNIQUE del número: otra restricción, no se disfraza
        return caja
    caja = await _buscar_caja(session, moneda)
    assert caja is not None
    return caja
