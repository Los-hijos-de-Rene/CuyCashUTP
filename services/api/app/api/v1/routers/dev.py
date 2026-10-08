"""
Rutas de desarrollo LOCAL para el menú de desarrollo de la app (flavor local).

Para quien no lo sepa: en producción NO existen. Si no se cumple el cerrojo de
`dev_tools.rutas_habilitadas()` (DEV_TOOLS=true, DEV_TOOLS_KEY, base local),
cada ruta responde 404 como si no estuviera, y además exige la clave en
`X-Dev-Key`. Lo mismo se puede hacer por terminal con `scripts/dev.py`.
"""

import hmac
from typing import Optional

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.base import get_session
from app.services import dev_tools

router = APIRouter(prefix="/v1/dev", tags=["Desarrollo (solo local)"])


async def _solo_local(x_dev_key: Optional[str] = Header(None, alias="X-Dev-Key")) -> None:
    if not dev_tools.rutas_habilitadas():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not Found")
    if not hmac.compare_digest(x_dev_key or "", settings.DEV_TOOLS_KEY):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Clave de desarrollo inválida")


def _usuarios() -> list:
    return [
        {"dni": u.dni, "nombre": f"{u.nombres} {u.apellidos}", "alias": u.alias}
        for u in dev_tools.USUARIOS_DE_PRUEBA
    ]


@router.post("/reset-y-seed", dependencies=[Depends(_solo_local)])
async def reiniciar_y_sembrar(session: AsyncSession = Depends(get_session)):
    """Vacía la base local y crea los usuarios de prueba con saldo."""
    await dev_tools.reiniciar(session)
    await dev_tools.sembrar(session)
    return {"usuarios": _usuarios(), "pin": dev_tools.PIN_DE_PRUEBA}


@router.post("/seed", dependencies=[Depends(_solo_local)])
async def sembrar(session: AsyncSession = Depends(get_session)):
    """Crea los usuarios de prueba que falten, sin borrar nada."""
    creados = await dev_tools.sembrar(session)
    return {"usuarios": _usuarios(), "creados": creados, "pin": dev_tools.PIN_DE_PRUEBA}


@router.get("/otp", dependencies=[Depends(_solo_local)])
async def ultimos_otp():
    """Últimos códigos OTP enviados (el notificador `log` los guarda aquí)."""
    return {
        "codigos": [
            {
                "destino": o.destino,
                "codigo": o.codigo,
                "proposito": o.proposito,
                "momento": o.momento.isoformat(),
            }
            for o in dev_tools.ultimos_otps()
        ]
    }
