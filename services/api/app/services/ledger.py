"""
El único módulo que escribe en el libro mayor.

Transferencia, recarga, desembolso y cuota pasan todos por `post`. Es lo que
permite que las garantías del libro —partida doble, atomicidad, idempotencia—
se prueben una vez y valgan para siempre: si cada ruta insertara sus propios
asientos, cada ruta tendría que acordarse de todo esto.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.db.models import Account, LedgerEntry, Transaction


@dataclass(frozen=True)
class Asiento:
    """El monto es SIEMPRE positivo; el signo lo dice `direccion`."""

    account_id: str
    direccion: str  # 'debito' | 'credito'
    monto: int


async def post(
    session: AsyncSession,
    *,
    tipo: str,
    asientos: List[Asiento],
    idempotency_key: str,
    fingerprint: str,
    referencia: Optional[str] = None,
) -> Tuple[Transaction, bool]:
    """
    Registra una operación completa. Devuelve (transacción, reutilizada).

    No hace commit: quien llama decide cuándo cerrar, para poder escribir en la
    misma transacción de base de datos las filas que acompañan a los asientos
    (la fila de `transfers`, por ejemplo). Tampoco hace rollback ante un
    failure: quien llama debe descartar la sesión si recibe un `ApiError`.
    """
    # Un descuadre no es un caso de negocio que el usuario pueda provocar: es
    # un bug de quien construyó los asientos. Reventar es la respuesta correcta.
    assert asientos, "Una operación sin asientos no es una operación"
    assert all(a.direccion in ("debito", "credito") for a in asientos), (
        "La dirección es 'debito' o 'credito'"
    )
    assert all(a.monto > 0 for a in asientos), "Los montos son siempre positivos"
    debitos = sum(a.monto for a in asientos if a.direccion == "debito")
    creditos = sum(a.monto for a in asientos if a.direccion == "credito")
    assert debitos == creditos, f"Asientos descuadrados: {debitos} != {creditos}"

    # 1) BLOQUEAR las cuentas, 2) recién entonces mirar la clave de idempotencia.
    #
    # El orden importa y es el contrario al intuitivo. Si se consultara la clave
    # antes de bloquear, dos peticiones con la misma clave verían ambas "no
    # existe", la segunda esperaría al bloqueo de la primera y, al obtenerlo,
    # insertaría la clave duplicada: la UNIQUE la rechazaría con un
    # IntegrityError (un 500) en vez de devolver la transacción original.
    # Bloqueando primero, la segunda petición espera aquí hasta que la primera
    # hace commit y su consulta de abajo (READ COMMITTED, el nivel por defecto
    # de Postgres) ya ve la fila confirmada. No hay ventana entre consulta e
    # inserción porque ambas ocurren con las cuentas bloqueadas.
    #
    # Esto es seguro SOLO MIENTRAS toda operación bloquee al menos una cuenta
    # que comparta con sus reintentos. Lo rompería: (a) una operación futura
    # que no bloquee cuenta alguna; (b) subir el nivel de aislamiento a
    # REPEATABLE READ/SERIALIZABLE, donde la instantánea se fija antes de
    # esperar. En esos casos hay que capturar también el IntegrityError de
    # `idempotency_key` y resolverlo como reutilización.
    #
    # `order_by(id)`: `IN (...)` no garantiza en qué orden Postgres toma los
    # bloqueos; ordenar explícitamente es lo que hace que A→B y B→A pidan los
    # bloqueos en la misma secuencia y no se abracen.
    ids = sorted({a.account_id for a in asientos})
    cuentas: Dict[str, Account] = {
        c.id: c
        for c in (
            await session.execute(
                select(Account)
                .where(Account.id.in_(ids))
                .order_by(Account.id)
                .with_for_update()
            )
        ).scalars()
    }
    # Una cuenta inexistente es un bug de quien armó los asientos, no del usuario.
    assert len(cuentas) == len(ids), "Hay asientos sobre cuentas que no existen"

    existente = (
        await session.execute(
            select(Transaction).where(Transaction.idempotency_key == idempotency_key)
        )
    ).scalar_one_or_none()
    if existente is not None:
        if existente.request_fingerprint != fingerprint:
            # Misma clave, otros datos: no es un reintento. Devolver la
            # original haría creer al usuario que envió lo que acaba de escribir.
            raise ApiError(
                ErrorCode.IDEMPOTENCY_KEY_REUSED,
                "Esa operación ya se envió con otros datos. Vuelve a empezar.",
                status_code=status.HTTP_409_CONFLICT,
            )
        return existente, True

    # Cada asiento mueve UNA moneda y el libro cuadra por moneda: mezclarlas
    # haría que "débitos == créditos" sumara soles con dólares.
    assert len({c.moneda for c in cuentas.values()}) == 1, "Monedas mezcladas"

    # Se valida el débito TOTAL por cuenta, no asiento por asiento: dos débitos
    # de 600 sobre una cuenta con 1000 pasarían cada uno por separado.
    # La cuenta de sistema es la contraparte de las recargas y puede quedar en
    # rojo (el CHECK de la tabla solo se lo permite a ella).
    por_cuenta: Dict[str, int] = {}
    for a in asientos:
        if a.direccion == "debito":
            por_cuenta[a.account_id] = por_cuenta.get(a.account_id, 0) + a.monto
    for account_id, total in por_cuenta.items():
        cuenta = cuentas[account_id]
        if cuenta.tipo != "sistema" and cuenta.saldo_disponible < total:
            raise ApiError(
                ErrorCode.INSUFFICIENT_FUNDS,
                "No te alcanza el saldo disponible.",
            )

    tx = Transaction(
        tipo=tipo,
        estado="confirmada",
        idempotency_key=idempotency_key,
        request_fingerprint=fingerprint,
        referencia=referencia,
    )
    session.add(tx)
    await session.flush()

    for a in asientos:
        cuenta = cuentas[a.account_id]
        delta = -a.monto if a.direccion == "debito" else a.monto
        cuenta.saldo_disponible += delta
        cuenta.saldo_contable += delta
        session.add(
            LedgerEntry(
                transaction_id=tx.id,
                account_id=cuenta.id,
                direccion=a.direccion,
                monto=a.monto,
                moneda=cuenta.moneda,
                saldo_posterior=cuenta.saldo_disponible,
            )
        )

    await session.flush()
    return tx, False
