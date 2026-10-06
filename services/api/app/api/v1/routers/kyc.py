import logging

import httpx
from fastapi import APIRouter, Request, Response, status

from app.core.config import settings
from app.core.errors import ApiError, ErrorCode

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/v1/kyc", tags=["KYC"])


@router.api_route("/{path:path}", methods=["GET", "POST"])
async def proxy(path: str, request: Request):
    """
    Reenvía al microservicio de KYC agregando la API key.

    Es lo que cierra el R1 del ADR-0001: la app deja de llevar la clave, que en
    un binario es extraíble con `strings` o con un proxy mirando el tráfico.

    El cuerpo se reenvía como STREAM. `verify-full` sube unos 50 fotogramas, de
    varios MB por petición; acumularlos en memoria tumba el servicio con pocos
    usuarios simultáneos.
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

    return Response(
        content=upstream.content,
        status_code=upstream.status_code,
        media_type=upstream.headers.get("content-type"),
    )
