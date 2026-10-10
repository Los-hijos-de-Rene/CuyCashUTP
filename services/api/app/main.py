import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.api.v1.routers import accounts, auth, dev, directory, kyc, otp, profile, transfers
from app.core.config import settings
from app.core.errors import ApiError
from app.db.base import Base, engine

logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Para la demo el esquema se crea al arrancar. Con datos reales esto pasa
    # a migraciones versionadas (Alembic).
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(title=settings.APP_NAME, version="0.2.0", lifespan=lifespan)

# Cabeceras de seguridad en TODA respuesta. La app móvil no las necesita para
# funcionar; existen para que nada que hable con esta API por un navegador
# (Swagger en /docs, un dashboard futuro) quede expuesto:
# - HSTS: tras la primera visita por HTTPS, el navegador no vuelve a intentar
#   HTTP (Render ya redirige 301, pero esa primera petición viajaría en claro).
# - nosniff: un JSON nunca se interpreta como HTML o script (XSS reflejado).
# - frame DENY: la API no se incrusta en otra página (clickjacking).
# - no-store: saldos y movimientos no quedan en cachés intermedias.
_CABECERAS_DE_SEGURIDAD = {
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
}


@app.middleware("http")
async def cabeceras_de_seguridad(request: Request, call_next):
    response = await call_next(request)
    for nombre, valor in _CABECERAS_DE_SEGURIDAD.items():
        response.headers.setdefault(nombre, valor)
    if request.url.path.startswith("/v1/"):
        response.headers.setdefault("Cache-Control", "no-store")
    return response

# Sin CORSMiddleware A PROPÓSITO: el único cliente es la app nativa, que no
# aplica CORS. Sin la cabecera Access-Control-Allow-Origin, un navegador
# bloquea cualquier lectura desde otro origen. El día que exista el dashboard
# web se añade con una lista blanca de orígenes exactos, nunca "*".


@app.exception_handler(ApiError)
async def api_error_handler(request: Request, error: ApiError):
    """El cuerpo ya viene con `code`; se devuelve tal cual, sin envolverlo."""
    return JSONResponse(status_code=error.status_code, content=error.detail)


@app.get("/health", tags=["Infra"])
async def health():
    """
    Vida del proceso. Es el health check de Render: no toca la base para
    que un Neon dormido (scale to zero) no haga reiniciar el servicio.

    `version` es el commit que corre (Render lo pone en `RENDER_GIT_COMMIT`).
    El pipeline de CD lo espera para saber que el despliegue terminó, y tras
    un rollback dice a qué versión se volvió. El repositorio es público: el
    commit no revela nada que no esté ya en GitHub.
    """
    return {"status": "ok", "version": os.getenv("RENDER_GIT_COMMIT", "local")}


@app.get("/health/db", tags=["Infra"])
async def health_db():
    """
    Disponibilidad de la base: un `SELECT 1` y cuánto tardó. Para el
    monitoreo externo; 503 si la base no responde, sin el detalle del error
    (la cadena de conexión no debe salir nunca en una respuesta).
    """
    inicio = time.perf_counter()
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception:  # noqa: BLE001 — cualquier fallo es "no disponible"
        logging.getLogger(__name__).exception("health/db: la base no respondió")
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "unavailable", "database": engine.dialect.name},
        )
    return {
        "status": "ok",
        "database": engine.dialect.name,
        "latency_ms": round((time.perf_counter() - inicio) * 1000, 1),
    }


app.include_router(auth.router)
app.include_router(otp.router)
app.include_router(kyc.router)
app.include_router(accounts.router)
app.include_router(transfers.router)
app.include_router(directory.router)
app.include_router(profile.router)
# Responde 404 salvo en local con DEV_TOOLS (ver routers/dev.py).
app.include_router(dev.router)
