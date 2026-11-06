
import logging
import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from sqlalchemy import text
from starlette.middleware.cors import CORSMiddleware

from app.api.v1.routers import (
    accounts,
    admin,
    auth,
    dev,
    directory,
    kyc,
    loans,
    otp,
    profile,
    qr,
    transfers,
)
from app.core.config import settings
from app.core.errors import ApiError
from app.db.base import engine


logging.basicConfig(level=logging.INFO)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Verificar el esquema al arrancar.
    # Las migraciones se aplican como paso operativo.
    from app.db.migrations import require_current_schema

    async with engine.connect() as conn:
        await conn.run_sync(require_current_schema)

    yield


app = FastAPI(
    title=settings.APP_NAME,
    version="0.2.0",
    lifespan=lifespan,
)


# Cabeceras de seguridad para todas las respuestas.
_CABECERAS_DE_SEGURIDAD = {
    "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
}


@app.middleware("http")
async def cabeceras_de_seguridad(
    request: Request,
    call_next,
):
    response = await call_next(request)

    for nombre, valor in _CABECERAS_DE_SEGURIDAD.items():
        response.headers.setdefault(nombre, valor)

    if request.url.path.startswith("/v1/"):
        response.headers.setdefault("Cache-Control", "no-store")

    return response


# CORS exclusivo para el panel administrativo configurado.
if settings.admin_cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.admin_cors_origins,
        allow_credentials=False,
        allow_methods=["GET"],
        allow_headers=["Authorization", "Content-Type"],
    )


@app.exception_handler(ApiError)
async def api_error_handler(
    request: Request,
    error: ApiError,
):
    return JSONResponse(
        status_code=error.status_code,
        content=error.detail,
    )


@app.get("/health", tags=["Infra"])
async def health():
    return {
        "status": "ok",
        "version": os.getenv("RENDER_GIT_COMMIT", "local"),
    }


@app.get("/health/db", tags=["Infra"])
async def health_db():
    inicio = time.perf_counter()

    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))

    except Exception:
        logging.getLogger(__name__).exception(
            "health/db: la base no respondio"
        )

        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "unavailable",
                "database": engine.dialect.name,
            },
        )

    return {
        "status": "ok",
        "database": engine.dialect.name,
        "latency_ms": round(
            (time.perf_counter() - inicio) * 1000,
            1,
        ),
    }


# =====================================================
# REGISTRO DE RUTAS DE CUYCASHUTP
# =====================================================

# Autenticacion y verificacion
app.include_router(auth.router)
app.include_router(otp.router)
app.include_router(kyc.router)

# Cuentas y movimientos de dinero
app.include_router(accounts.router)

# Transferencias y recargas
# Necesario para /v1/transfers y /v1/topups
app.include_router(transfers.router)

# API de QR - Issue #77
# /v1/qr/emitir
# /v1/qr/validar
# /v1/qr/pagar
app.include_router(qr.router)

# Directorio y perfil
app.include_router(directory.router)
app.include_router(profile.router)

# Herramientas de desarrollo
app.include_router(dev.router)

# Prestamos y administracion
app.include_router(loans.router)
app.include_router(admin.router)
