import os
import sys

# SQLite en memoria: el mismo esquema, sin Postgres levantado ni esperar a un
# contenedor. Lo que se prueba aquí es la lógica, no el motor.
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
# Sin espera artificial los tests no tardan de más; la uniformidad de tiempos
# se verifica aparte.
os.environ.setdefault("UNIFORM_RESPONSE_SECONDS", "0")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.db.base import Base, get_session  # noqa: E402
from app.main import app  # noqa: E402


@pytest_asyncio.fixture
async def client():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    maker = async_sessionmaker(engine, expire_on_commit=False)

    async def override():
        async with maker() as session:
            yield session

    app.dependency_overrides[get_session] = override
    # El lifespan crearía el esquema contra la base real: se omite.
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
    await engine.dispose()


@pytest.fixture
def otp_codes(monkeypatch):
    """Captura los códigos en vez de enviarlos, para poder verificarlos."""
    enviados = []

    class Captura:
        async def send(self, destination, code, purpose):
            enviados.append({"destination": destination, "code": code, "purpose": purpose})

    from app.services import otp as otp_service

    monkeypatch.setattr(otp_service, "notifier", Captura())
    return enviados
