"""
Resolver un destinatario y guardar frecuentes.

Se busca por DNI o por alias; los dos son únicos. El alias lleva siempre una
letra, así que un valor de 8 dígitos solo puede ser un DNI.

Buscar por alias NO devuelve el DNI: el alias es público (se comparte para
cobrar) y no debe servir para averiguar el documento de nadie. Buscar por DNI
sí lo devuelve, porque quien pregunta ya lo tenía.

Resolver un DNI devuelve el nombre de una persona, así que es la superficie de
raspado de identidades: el nombre va enmascarado y TODA consulta (aquí, en el
alta de frecuentes y en `POST /v1/transfers`) descuenta del mismo presupuesto,
ver `app.services.rate_limit`.
"""

from typing import List, Optional, Tuple

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, Beneficiary, User, _uuid, utcnow
from app.services import alias as alias_svc
from app.services.rate_limit import consumir_consulta_de_destinatario

router = APIRouter(prefix="/v1", tags=["Directorio"])


def enmascarar(nombres: str, apellidos: str) -> str:
    """
    `Carlos Alberto Nina` -> `C*** A*** N***`.

    Confirma lo justo para que quien ya conoce al destinatario lo reconozca, y
    no lo bastante para que quien teclea DNIs al azar recolecte nombres.

    `split()` sin argumentos descarta espacios dobles, tabuladores y bordes; es
    lo que evita el `IndexError` de `p[0]` sobre una cadena vacía. Un nombre
    vacío da `""`, no un error: esto corre en el camino más caliente de la app.
    """
    partes = "{} {}".format(nombres or "", apellidos or "").split()
    return " ".join("{}***".format(p[0].upper()) for p in partes)


def cuenta_publica_json(c: Account, *, propia: bool) -> dict:
    """
    Lo que se puede decir de una cuenta a quien quiere enviarle dinero.

    `cuenta_id` es el UUID: no revela el número completo ni el DNI. El nombre
    que el titular le puso a su cuenta es suyo: solo sale cuando la cuenta es
    del que pregunta.
    """
    return {
        "cuenta_id": c.id,
        "tipo": c.tipo,
        "moneda": c.moneda,
        "numero_masked": "••••{}".format(c.numero[-4:]),
        "nombre": c.nombre if propia else None,
    }


async def _destinatario(session: AsyncSession, criterio) -> Tuple[User, List[Account]]:
    filas = (
        await session.execute(
            select(User, Account)
            .join(Account, Account.user_id == User.id)
            .where(
                criterio,
                Account.estado == "activa",
                Account.tipo != "sistema",
            )
            .order_by(Account.created_at, Account.id)
        )
    ).all()
    if not filas:
        # Una persona con todas sus cuentas bloqueadas o cerradas cae aquí, y
        # es lo correcto: existe pero no puede recibir, así que no es un
        # destinatario. La respuesta es idéntica a la de un DNI o alias
        # inexistente.
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI o alias en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return filas[0][0], [cuenta for _, cuenta in filas]


@router.get("/directory/resolve")
async def resolver(
    dni: Optional[str] = Query(None, min_length=8, max_length=8, pattern=r"^\d{8}$"),
    alias: Optional[str] = Query(None, max_length=60),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    """Exactamente uno de `dni` o `alias`. El alias se normaliza como al guardarlo."""
    if (dni is None) == (alias is None):
        raise ApiError(
            ErrorCode.INVALID_RECIPIENT_QUERY,
            "Busca por DNI o por alias.",
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )
    if alias is not None:
        alias = alias_svc.normalizar(alias)
        # Un alias malformado no puede existir: se rechaza sin gastar cupo,
        # igual que un DNI malformado.
        if not alias_svc.es_valido(alias):
            raise ApiError(
                ErrorCode.INVALID_RECIPIENT_QUERY,
                "Ese alias no tiene un formato válido.",
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            )
    # El propio DNI o alias no es un error: lista las otras cuentas del titular
    # para pasar dinero entre ellas. Igual descuenta del presupuesto, para que
    # el tope no dependa de qué se teclea.
    consumir_consulta_de_destinatario(user.id)
    criterio = User.dni == dni if dni is not None else User.alias == alias
    destinatario, cuentas = await _destinatario(session, criterio)
    propia = destinatario.id == user.id
    return {
        # Solo se repite el DNI que el que pregunta ya escribió (o el suyo).
        "dni": destinatario.dni if dni is not None or propia else None,
        "alias": destinatario.alias,
        "nombre_enmascarado": enmascarar(destinatario.nombres, destinatario.apellidos),
        "cuentas": [cuenta_publica_json(c, propia=propia) for c in cuentas],
    }


class BeneficiaryIn(BaseModel):
    cuenta_destino_id: str = Field(min_length=1, max_length=36)
    apodo: str = Field(min_length=1, max_length=40)


@router.get("/beneficiaries")
async def listar(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # No gasta cupo: solo devuelve a quienes el propio titular ya validó al
    # guardarlos. La cuenta se lee al vuelo: si dejó de estar activa, `null`.
    filas = (
        await session.execute(
            select(Beneficiary, User, Account)
            .outerjoin(User, User.dni == Beneficiary.beneficiario_dni)
            .outerjoin(
                Account,
                (Account.id == Beneficiary.cuenta_destino_id) & (Account.estado == "activa"),
            )
            .where(Beneficiary.user_id == user.id)
            .order_by(Beneficiary.created_at.desc(), Beneficiary.id)
        )
    ).all()

    return {
        "beneficiarios": [
            {
                "id": b.id,
                "dni": b.beneficiario_dni,
                "apodo": b.apodo,
                "nombre_enmascarado": (
                    enmascarar(otro.nombres, otro.apellidos) if otro else None
                ),
                "cuenta": (
                    cuenta_publica_json(cuenta, propia=cuenta.user_id == user.id)
                    if cuenta
                    else None
                ),
            }
            for b, otro, cuenta in filas
        ]
    }


@router.post("/beneficiaries", status_code=status.HTTP_201_CREATED)
async def guardar(
    payload: BeneficiaryIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # Guardar valida que la cuenta exista y reciba: 201 vs 404 es otro oráculo
    # del padrón, así que cuesta del mismo cupo. Una cuenta propia SÍ se puede
    # guardar ("Mi sueldo").
    consumir_consulta_de_destinatario(user.id)
    fila = (
        await session.execute(
            select(Account, User)
            .join(User, User.id == Account.user_id)
            .where(
                Account.id == payload.cuenta_destino_id,
                Account.tipo != "sistema",
                Account.estado == "activa",
            )
        )
    ).first()
    if fila is None:
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos esa cuenta en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    cuenta, titular = fila

    # Upsert atómico en la base. Doble toque en "guardar": con "buscar y luego
    # insertar", dos peticiones ven "no existe", ambas insertan y la UNIQUE
    # (user_id, cuenta_destino_id) tumba a la segunda con un 500. `ON CONFLICT DO UPDATE`
    # no tiene ventana entre mirar y escribir. Se prefiere al SAVEPOINT +
    # releer de `accounts.cuenta_de_sistema` porque no depende de que el
    # ganador ya sea visible al releer (con un SAVEPOINT el perdedor puede no
    # verlo aún y re-lanzar el error).
    insertar = (
        pg_insert if session.get_bind().dialect.name == "postgresql" else sqlite_insert
    )
    await session.execute(
        insertar(Beneficiary)
        .values(
            id=_uuid(),
            user_id=user.id,
            beneficiario_dni=titular.dni,
            cuenta_destino_id=cuenta.id,
            apodo=payload.apodo,
            created_at=utcnow(),
        )
        .on_conflict_do_update(
            index_elements=["user_id", "cuenta_destino_id"],
            set_={"apodo": payload.apodo},
        )
    )
    await session.commit()
    return {"ok": True}


@router.delete("/beneficiaries/{beneficiary_id}", status_code=status.HTTP_204_NO_CONTENT)
async def eliminar(
    beneficiary_id: str,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # Idempotente: borrar algo que no existe (o que es de otro titular) responde
    # igual que borrar algo que sí, así no se confirman ids ajenos.
    fila = (
        await session.execute(
            select(Beneficiary).where(
                Beneficiary.id == beneficiary_id, Beneficiary.user_id == user.id
            )
        )
    ).scalar_one_or_none()
    if fila is not None:
        await session.delete(fila)
        await session.commit()
