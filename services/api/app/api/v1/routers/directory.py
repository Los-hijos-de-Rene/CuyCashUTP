"""
Resolver un destinatario y guardar frecuentes.

El DNI es el identificador porque es lo único que hoy distingue a una persona
sin ambigüedad: no hay celular en el modelo y el alias se deriva del nombre,
así que dos homónimos colisionan.

Resolver un DNI devuelve el nombre de una persona, así que es la superficie de
raspado de identidades: el nombre va enmascarado y TODA consulta (aquí, en el
alta de frecuentes y en `POST /v1/transfers`) descuenta del mismo presupuesto,
ver `app.services.rate_limit`.
"""

from typing import Tuple

from fastapi import APIRouter, Depends, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import current_user
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.db.models import Account, Beneficiary, User
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


async def _destinatario(session: AsyncSession, dni: str) -> Tuple[User, Account]:
    fila = (
        await session.execute(
            select(User, Account)
            .join(Account, Account.user_id == User.id)
            .where(
                User.dni == dni,
                Account.estado == "activa",
                Account.tipo == "ahorro",
            )
            .order_by(Account.created_at, Account.id)
        )
    ).first()
    if fila is None:
        # Una persona con la cuenta bloqueada o cerrada cae aquí, y es lo
        # correcto: existe pero no puede recibir, así que no es un
        # destinatario. La respuesta es idéntica a la de un DNI inexistente.
        raise ApiError(
            ErrorCode.RECIPIENT_NOT_FOUND,
            "No encontramos a nadie con ese DNI en CuyCash.",
            status_code=status.HTTP_404_NOT_FOUND,
        )
    return fila[0], fila[1]


@router.get("/directory/resolve")
async def resolver(
    dni: str = Query(min_length=8, max_length=8, pattern=r"^\d{8}$"),
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    if dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes enviarte dinero a ti mismo.")

    consumir_consulta_de_destinatario(user.id)
    destinatario, cuenta = await _destinatario(session, dni)
    return {
        "dni": destinatario.dni,
        "nombre_enmascarado": enmascarar(destinatario.nombres, destinatario.apellidos),
        "cuenta_destino_numero_masked": "••••{}".format(cuenta.numero[-4:]),
    }


class BeneficiaryIn(BaseModel):
    dni: str = Field(min_length=8, max_length=8, pattern=r"^\d{8}$")
    apodo: str = Field(min_length=1, max_length=40)


@router.get("/beneficiaries")
async def listar(
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    # Un solo join en vez de una consulta por frecuente. No gasta cupo: solo
    # devuelve a quienes el propio titular ya validó al guardarlos.
    filas = (
        await session.execute(
            select(Beneficiary, User)
            .outerjoin(User, User.dni == Beneficiary.beneficiario_dni)
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
            }
            for b, otro in filas
        ]
    }


@router.post("/beneficiaries", status_code=status.HTTP_201_CREATED)
async def guardar(
    payload: BeneficiaryIn,
    user: User = Depends(current_user),
    session: AsyncSession = Depends(get_session),
):
    if payload.dni == user.dni:
        raise ApiError(ErrorCode.SELF_TRANSFER, "No puedes guardarte a ti mismo.")
    # Guardar valida que el DNI sea cliente: 201 vs 404 es otro oráculo del
    # padrón, así que cuesta del mismo presupuesto.
    consumir_consulta_de_destinatario(user.id)
    await _destinatario(session, payload.dni)

    existente = (
        await session.execute(
            select(Beneficiary).where(
                Beneficiary.user_id == user.id,
                Beneficiary.beneficiario_dni == payload.dni,
            )
        )
    ).scalar_one_or_none()
    if existente is not None:
        existente.apodo = payload.apodo
    else:
        session.add(
            Beneficiary(
                user_id=user.id, beneficiario_dni=payload.dni, apodo=payload.apodo
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
