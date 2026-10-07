import logging

import httpx
from fastapi import APIRouter, Request, Response, status

from app.core.config import settings
from app.core.errors import ApiError, ErrorCode

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/kyc", tags=["KYC"])


@router.post("/liveness/challenge")
async def challenge(request: Request):
    """Abre un desafío de liveness: el servicio decide las tareas y su orden."""
    return await _reenviar("liveness/challenge", request)


@router.post("/identity/verify-full")
async def verify_full(request: Request):
    """Verificación completa: documento + todos los segmentos del liveness."""
    return await _reenviar("identity/verify-full", request)


async def _reenviar(path: str, request: Request) -> Response:
    """
    Reenvía al microservicio de KYC agregando la API key.

    Es lo que cierra el R1 del ADR-0001: la app deja de llevar la clave, que en
    un binario es extraíble con `strings` o con un proxy mirando el tráfico.

    Solo las dos rutas que usa la app, no un comodín: con `/{path}` cualquiera
    podía usar con nuestra clave las rutas sueltas del servicio (`/verify`,
    `/document/validate`), que no forman parte del registro.

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
