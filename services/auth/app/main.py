import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.v1.routers import auth, kyc, otp
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


app = FastAPI(title=settings.APP_NAME, version="0.1.0", lifespan=lifespan)


@app.exception_handler(ApiError)
async def api_error_handler(request: Request, error: ApiError):
    """El cuerpo ya viene con `code`; se devuelve tal cual, sin envolverlo."""
    return JSONResponse(status_code=error.status_code, content=error.detail)


@app.get("/health", tags=["Infra"])
async def health():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(otp.router)
app.include_router(kyc.router)
