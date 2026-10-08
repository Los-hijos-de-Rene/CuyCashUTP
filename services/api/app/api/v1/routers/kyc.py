import asyncio
import json
import logging
import time
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

    Si el KYC está DESPERTANDO, se reintenta (ver `_pedir_con_reintento`). Para
    poder reenviar, el cuerpo se guarda en memoria en vez de pasarlo como
    stream: un `verify-full` son ~1-2 MB (fotogramas clave, no video), que la
    API aguanta sin problema a esta escala.
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
    upstream = await _pedir_con_reintento(request.method, url, headers, await request.body())

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


# Lo que responde el borde de Render mientras el servicio arranca o se
# reinicia: la petición NO llegó a procesarse en el KYC, así que repetirla es
# seguro (no se consume un token de desafío dos veces).
_DESPERTANDO = {
    status.HTTP_502_BAD_GATEWAY,
    status.HTTP_503_SERVICE_UNAVAILABLE,
    status.HTTP_504_GATEWAY_TIMEOUT,
}


async def _pedir_con_reintento(
    method: str, url: str, headers: dict, body: bytes
) -> httpx.Response:
    """
    Llama al KYC y, si está despertando, reintenta hasta KYC_WAKE_TIMEOUT_SECONDS.

    En el plan gratuito de Render el KYC se duerme tras ~15 min sin tráfico;
    la primera petición lo despierta (~30 s) y mientras tanto el borde de
    Render responde 502. Sin reintento, ese 502 le llegaba al usuario como "no
    pudimos conectar", en medio del registro.

    Solo se reintenta lo que NO llegó al KYC (502/503/504 del borde, conexión
    rechazada). Un timeout de lectura no: el KYC pudo haber procesado la
    petición, y repetirla gastaría el token de desafío dos veces.
    """
    limite = time.monotonic() + settings.KYC_WAKE_TIMEOUT_SECONDS
    intento = 0
    async with httpx.AsyncClient(timeout=120) as client:
        while True:
            intento += 1
            try:
                upstream = await client.request(method, url, headers=headers, content=body)
                if upstream.status_code not in _DESPERTANDO:
                    return upstream
                motivo = f"HTTP {upstream.status_code}"
            except (httpx.ConnectError, httpx.ConnectTimeout) as error:
                upstream = None
                motivo = type(error).__name__
            except httpx.HTTPError as error:
                logger.error("KYC no alcanzable: %s", error)
                raise ApiError(
                    ErrorCode.SERVICE_UNAVAILABLE,
                    "No pudimos contactar la verificación de identidad.",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                )

            if time.monotonic() + settings.KYC_RETRY_DELAY_SECONDS > limite:
                logger.error("KYC sigue sin responder tras %d intentos (%s)", intento, motivo)
                raise ApiError(
                    ErrorCode.SERVICE_UNAVAILABLE,
                    "La verificación de identidad está iniciando. Inténtalo en un momento.",
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                )
            logger.warning("KYC despertando (%s); reintento %d", motivo, intento)
            await asyncio.sleep(settings.KYC_RETRY_DELAY_SECONDS)
