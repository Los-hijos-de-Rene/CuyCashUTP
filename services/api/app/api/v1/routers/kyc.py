import json
import logging
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, Header, Request, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import ApiError, ErrorCode
from app.db.base import get_session
from app.services import kyc_tickets

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/kyc", tags=["KYC"])


@router.post("/liveness/challenge")
async def challenge(request: Request):
    """Abre un desafío de liveness: el servicio decide las tareas y su orden."""
    return await _reenviar("liveness/challenge", request)


@router.post("/document/validate")
async def validate_document(request: Request):
    """Calidad del frente del DNI, al momento de fotografiarlo (paso 2)."""
    return await _reenviar("document/validate", request)


@router.post("/document/mrz")
async def read_document_back(request: Request):
    """Lee el reverso del DNI y lo coteja con el número declarado (paso 2)."""
    return await _reenviar("document/mrz", request)


@router.post("/identity/verify-full")
async def verify_full(
    request: Request,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id", max_length=128),
    session: AsyncSession = Depends(get_session),
):
    """
    Verificación completa: documento + todos los segmentos del liveness.

    Si el servicio aprueba TODO, aquí se emite el `kyc_ticket` que exige
    `/register`: el veredicto deja de ser algo que la app "dice" y pasa a ser
    algo que el backend recuerda.
    """
    response = await _reenviar("identity/verify-full", request)
    if response.status_code != status.HTTP_200_OK:
        return response
    try:
        verdict = json.loads(response.body)
    except ValueError:
        return response
    if not isinstance(verdict, dict):
        return response

    ticket = await kyc_tickets.issue(session, verdict, x_device_id or "")
    if ticket is not None:
        verdict["kyc_ticket"] = ticket
    return JSONResponse(content=verdict)


async def _reenviar(path: str, request: Request) -> Response:
    """
    Reenvía al microservicio de KYC agregando la API key.

    Es lo que cierra el R1 del ADR-0001: la app deja de llevar la clave, que en
    un binario es extraíble con `strings` o con un proxy mirando el tráfico.

    Solo las rutas que usa el registro, no un comodín: con `/{path}` cualquiera
    podía usar con nuestra clave las rutas sueltas del servicio (`/verify`,
    `/liveness/evaluate`), que la app no necesita.

    El cuerpo se reenvía como STREAM. `verify-full` sube decenas de fotogramas;
    acumularlos en memoria tumba el servicio con pocos usuarios simultáneos.
    """
    if not settings.KYC_BASE_URL or not settings.KYC_API_KEY:
        raise ApiError(
            ErrorCode.SERVICE_UNAVAILABLE,
            "La verificación de identidad no está disponible.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    url = f"{settings.KYC_BASE_URL.rstrip('/')}/api/v1/{path}"
    headers = {
        "X-API-Key": settings.KYC_API_KEY,
        "content-type": request.headers.get("content-type", "application/json"),
    }

    try:
        async with httpx.AsyncClient(timeout=120) as client:
            upstream = await client.request(
                request.method, url, headers=headers, content=request.stream()
            )
    except httpx.HTTPError as error:
        logger.error("KYC no alcanzable: %s", error)
        raise ApiError(
            ErrorCode.SERVICE_UNAVAILABLE,
            "No pudimos contactar la verificación de identidad.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    # Un 401/403 del servicio es NUESTRA clave mal configurada, no algo que el
    # usuario pueda corregir: para la app es "no disponible".
    if upstream.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN):
        logger.error("El KYC rechazó la API key del backend (%s)", upstream.status_code)
        raise ApiError(
            ErrorCode.SERVICE_UNAVAILABLE,
            "La verificación de identidad no está disponible.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        media_type=upstream.headers.get("content-type"),
    )
