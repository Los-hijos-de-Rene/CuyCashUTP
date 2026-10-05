"""
El único módulo que escribe en el libro mayor.

Transferencia, recarga, desembolso y cuota pasan todos por `post`. Es lo que
permite que las garantías del libro —partida doble, atomicidad, idempotencia—
se prueben una vez y valgan para siempre: si cada ruta insertara sus propios
asientos, cada ruta tendría que acordarse de todo esto.

Las invariantes de entrada son `assert`: un descuadre o un monto negativo son
bugs de quien llama, no casos de negocio. Con `python -O` los `assert` se
eliminan y se iría con ellos la partida doble: NO ejecutar este servicio con
`-O` ni con PYTHONOPTIMIZE (el Dockerfile no lo hace; que nadie lo "optimice").

Reglas de este módulo que conviene tener presentes:
- La validación de fondos ignora los créditos de la MISMA transacción: se
  compara el débito total de cada cuenta contra su saldo previo. Una operación
  de neto positivo para esa cuenta (débito y crédito sobre ella) se rechaza si
  el saldo previo no cubre el débito. Es deliberado y conservador; si los
  préstamos o reversiones necesitan netear, hay que decidirlo expresamente.
- DEUDA CONOCIDA: toda recarga bloquea la fila de la caja del sistema, así que
  las recargas se serializan entre sí. La caja no tiene control de fondos y
  podría llevarse con `UPDATE ... SET saldo = saldo + :delta` sin bloqueo, pero
  eso es un rediseño que no toca ahora.
"""

import hashlib
import json
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from fastapi import status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError, ErrorCode
from app.db.models import Account, LedgerEntry, Transaction


@dataclass(frozen=True)
class Asiento:
    """El monto es SIEMPRE positivo; el signo lo dice `direccion`."""

    account_id: str
    direccion: str  # 'debito' | 'credito'
    monto: int


# Espejo del CHECK `ck_transactions_tipo`: validarlo aquí evita que un tipo
# inventado reviente con IntegrityError DESPUÉS de haber tomado los bloqueos.
TIPOS = ("transferencia", "recarga", "pago_qr", "desembolso", "cuota", "ajuste")
# `idempotency_key` y `request_fingerprint` son String(64): SQLite no lo hace
# cumplir, Postgres sí, y la diferencia solo se descubriría en producción.
LARGO_MAXIMO_CLAVE = 64


def _huella_completa(tipo: str, asientos: List[Asiento], fingerprint: str) -> str:
    """
    Huella que se guarda y se compara: la parte CANÓNICA la deriva el motor de
    lo que va a escribir (tipo + asientos ordenados) y se combina con la del
    llamador, que aporta lo que el motor no ve (el motivo, por ejemplo).

    Así la garantía "misma clave = misma operación" no depende de que cada
    llamador futuro acuerde meter en su huella todas las cuentas y montos: un
    reintento con otro destinatario cambia los asientos y, por tanto, la huella.
    SHA-256 en hex son exactamente 64 caracteres: cabe en la columna.
    """
    canonica = json.dumps(
        [tipo, sorted((a.account_id, a.direccion, a.monto) for a in asientos)],
        separators=(",", ":"),
    )
    return hashlib.sha256((canonica + "|" + fingerprint).encode("utf-8")).hexdigest()


def _resolver_clave_existente(existente: Transaction, huella: str) -> Tuple[Transaction, bool]:
    if existente.request_fingerprint != huella:
        # Misma clave, otros datos: no es un reintento. Devolver la original
        # haría creer al usuario que envió lo que acaba de escribir.
        raise ApiError(
            ErrorCode.IDEMPOTENCY_KEY_REUSED,
            "Esa operación ya se envió con otros datos. Vuelve a empezar.",
            status_code=status.HTTP_409_CONFLICT,
        )
    return existente, True


async def _buscar_por_clave(
    session: AsyncSession, idempotency_key: str
) -> Optional[Transaction]:
    return (
        await session.execute(
            select(Transaction).where(Transaction.idempotency_key == idempotency_key)
        )
    ).scalar_one_or_none()


async def post(
    session: AsyncSession,
    *,
    tipo: str,
    asientos: List[Asiento],
    idempotency_key: str,
    fingerprint: str,
    referencia: Optional[str] = None,
    permitir_cuentas_inactivas: bool = False,
) -> Tuple[Transaction, bool]:
    """
    Registra una operación completa. Devuelve (transacción, reutilizada).

    No hace commit: quien llama decide cuándo cerrar, para poder escribir en la
    misma transacción de base de datos las filas que acompañan a los asientos
    (la fila de `transfers`, por ejemplo). Tampoco hace rollback ante un
    failure: quien llama debe descartar la sesión si recibe un `ApiError`.

    `fingerprint` son los parámetros del llamador que el motor no ve; el motor
    le suma tipo y asientos (ver `_huella_completa`).
    `permitir_cuentas_inactivas` exime de la validación de estado: solo para
    reversiones y ajustes, que sí deben poder tocar una cuenta bloqueada.
    """
    # Un descuadre no es un caso de negocio que el usuario pueda provocar: es
    # un bug de quien construyó los asientos. Reventar es la respuesta correcta.
    assert tipo in TIPOS, f"Tipo de transacción desconocido: {tipo}"
    assert 0 < len(idempotency_key) <= LARGO_MAXIMO_CLAVE, (
        f"La clave de idempotencia debe tener entre 1 y {LARGO_MAXIMO_CLAVE} caracteres"
    )
    assert asientos, "Una operación sin asientos no es una operación"
    assert all(a.direccion in ("debito", "credito") for a in asientos), (
        "La dirección es 'debito' o 'credito'"
    )
    assert all(a.monto > 0 for a in asientos), "Los montos son siempre positivos"
    debitos = sum(a.monto for a in asientos if a.direccion == "debito")
    creditos = sum(a.monto for a in asientos if a.direccion == "credito")
    assert debitos == creditos, f"Asientos descuadrados: {debitos} != {creditos}"
    huella = _huella_completa(tipo, asientos, fingerprint)

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
    # esperar. En esos casos la red de seguridad es el `except IntegrityError`
    # del insert de más abajo, que resuelve la clave duplicada como reutilización.
    #
    # `order_by(id)`: `IN (...)` no garantiza en qué orden Postgres toma los
    # bloqueos; ordenar explícitamente es lo que hace que A→B y B→A pidan los
    # bloqueos en la misma secuencia y no se abracen.
    ids = {a.account_id for a in asientos}
    cuentas: Dict[str, Account] = {
        c.id: c
        for c in (
            await session.execute(
                select(Account)
                .where(Account.id.in_(ids))
                .order_by(Account.id)
                .with_for_update()
                # Sin esto, una `Account` ya presente en el identity map de la
                # sesión (la caja de `cuenta_de_sistema`, el origen y destino
                # que cargó la ruta) se devuelve SIN repoblar: la validación de
                # fondos y la aritmética usarían el saldo de ANTES de esperar
                # el bloqueo, y el UPDATE (valor absoluto calculado aquí)
                # pisaría el cambio de la transacción concurrente.
                .execution_options(populate_existing=True)
            )
        ).scalars()
    }
    # Una cuenta inexistente es un bug de quien armó los asientos, no del usuario.
    assert len(cuentas) == len(ids), "Hay asientos sobre cuentas que no existen"

    existente = await _buscar_por_clave(session, idempotency_key)
    if existente is not None:
        return _resolver_clave_existente(existente, huella)

    if not permitir_cuentas_inactivas:
        # Se valida DESPUÉS de la idempotencia: reintentar una operación que ya
        # se confirmó debe devolverla aunque la cuenta se haya bloqueado luego.
        # Toda cuenta tocada debe estar activa, también la que recibe: una
        # cuenta cerrada no debe acumular saldo.
        for cuenta in cuentas.values():
            if cuenta.estado != "activa":
                raise ApiError(
                    ErrorCode.ACCOUNT_BLOCKED,
                    "Una de las cuentas no está disponible para operar.",
                    status_code=status.HTTP_409_CONFLICT,
                )

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
        request_fingerprint=huella,
        referencia=referencia,
    )
    try:
        # SAVEPOINT: si la UNIQUE de la clave salta (el caso que el orden de
        # arriba evita, pero que reaparece con aislamiento más alto o con una
        # operación que no bloquee cuentas), el rollback es solo del savepoint
        # y la sesión del llamador no queda envenenada.
        async with session.begin_nested():
            session.add(tx)
            await session.flush()
    except IntegrityError:
        existente = await _buscar_por_clave(session, idempotency_key)
        if existente is None:
            raise  # no era la clave: otra restricción, no se disfraza
        return _resolver_clave_existente(existente, huella)

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
