import os
import sys
from dataclasses import dataclass

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


@pytest_asyncio.fixture
async def db_de_client(client):
    """
    Sesión sobre la MISMA base que ve el `client` HTTP.

    Para montar escenarios imposibles de crear por HTTP (una cuenta bloqueada,
    una sesión vencida). Reutiliza el override de `get_session` de `client`:
    mismo motor y misma conexión, así que lo que se escriba aquí lo ve la API
    y viceversa. Quien escriba debe hacer `commit()`.
    """
    gen = app.dependency_overrides[get_session]()
    session = await gen.__anext__()
    try:
        yield session
    finally:
        await gen.aclose()  # cierra la sesión, no queda el generador colgando


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


@pytest_asyncio.fixture
async def db():
    """
    Sesión directa contra el esquema, sin pasar por HTTP.

    La usan las pruebas del libro mayor: lo que verifican son las restricciones
    de la base (partida doble, montos positivos, idempotencia), y meterlas por
    un endpoint solo añadiría ruido entre la regla y su comprobación.
    """
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    maker = async_sessionmaker(engine, expire_on_commit=False)
    async with maker() as session:
        yield session
    await engine.dispose()


PIN_DE_PRUEBA = "839201"  # pasa `pin_is_valid`: ni repetido ni secuencia


@dataclass
class Registrado:
    dni: str
    token: str
    user_id: str

    @property
    def auth(self) -> dict:
        return {"Authorization": f"Bearer {self.token}"}


async def registrar(client, otp_codes, *, dni: str, nombres: str, apellidos: str) -> Registrado:
    """
    Registra un titular y abre su sesión por el camino REAL.

    Registrarse no abre sesión, y un teléfono desconocido no entra solo con el
    PIN: hay que pasar por authenticate -> OTP de dispositivo -> sessions. Se
    recorre completo en vez de insertar filas, para que estos fixtures
    sigan válidos si el contrato de auth se endurece.
    """
    email = f"{dni}@correo.pe"
    device = {"X-Device-Id": f"dev-{dni}"}

    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": dni,
            "nombres": nombres,
            "apellidos": apellidos,
            "email": email,
            "pin": PIN_DE_PRUEBA,
        },
    )
    assert r.status_code == 201, r.text
    user_id = r.json()["id"]

    a = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": dni, "pin": PIN_DE_PRUEBA},
        headers=device,
    )
    assert a.status_code == 200, a.text
    assert a.json()["result"] == "device_verification_required", a.text
    pending = a.json()["pending_token"]

    c = await client.post(
        "/v1/otp/challenges", json={"purpose": "device", "identifier": dni}
    )
    assert c.status_code == 200, c.text
    # Por destinatario Y propósito: otro OTP al mismo correo emitido antes
    # (p. ej. de recuperación) no debe confundirse con el de dispositivo.
    code = [
        e["code"]
        for e in otp_codes
        if e["destination"] == email and e["purpose"] == "device"
    ][-1]
    v = await client.post(
        f"/v1/otp/challenges/{c.json()['challenge_id']}/verify", json={"code": code}
    )
    assert v.status_code == 200, v.text

    s = await client.post(
        "/v1/auth/sessions",
        json={"pending_token": pending, "otp_ticket": v.json()["otp_ticket"]},
        headers=device,
    )
    assert s.status_code == 200, s.text
    return Registrado(dni=dni, token=s.json()["session_token"], user_id=user_id)


@pytest_asyncio.fixture
async def registrado(client, otp_codes):
    """Un titular con sesión abierta."""
    return await registrar(
        client, otp_codes, dni="71234567", nombres="Jenny Marisol", apellidos="Ruiz"
    )


@pytest_asyncio.fixture
async def otro_registrado(client, otp_codes):
    """Un segundo titular, para las pruebas de aislamiento entre usuarios."""
    return await registrar(
        client, otp_codes, dni="45678912", nombres="Luis Alberto", apellidos="Quispe"
    )
