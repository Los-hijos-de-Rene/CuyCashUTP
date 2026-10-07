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
from sqlalchemy.engine import make_url  # noqa: E402
from sqlalchemy.pool import NullPool, StaticPool  # noqa: E402

from app.db.base import Base, get_session  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(autouse=True)
def _presupuesto_de_consultas_limpio():
    """El presupuesto vive en memoria del proceso: que no pase de un test a otro."""
    from app.services import rate_limit

    rate_limit.reiniciar_para_pruebas()
    yield


def _url_postgres_de_pruebas():
    """
    `TEST_POSTGRES_URL` si está definida, validada; si no, `None` (SQLite).

    Cerrojo, no aviso: los fixtures hacen `drop_all` AL ENTRAR. Si la URL
    apuntara a una base con datos, se perderían antes de que nadie lea un
    docstring. Se exige el sufijo `_test` en el nombre de la base.
    """
    url = os.environ.get("TEST_POSTGRES_URL")
    if not url:
        return None
    nombre = make_url(url).database or ""
    if not nombre.endswith("_test"):
        raise RuntimeError(
            f"TEST_POSTGRES_URL apunta a la base '{nombre}': el fixture borra "
            "TODO el esquema, así que el nombre debe terminar en '_test'."
        )
    return url


async def _motor_limpio():
    """
    Motor con el esquema recién creado: Postgres real si hay
    `TEST_POSTGRES_URL` (el CI, mismo motor que producción), SQLite en memoria
    si no (desarrollo local, sin Docker). Devuelve `(motor, es_postgres)`.
    """
    url = _url_postgres_de_pruebas()
    if url:
        # NullPool: una conexión por tarea. Con el pool por defecto (5+10) la
        # cola serializaría parte de la contención que los tests de
        # concurrencia quieren provocar, y un atasco saltaría como `QueuePool
        # timeout` y no como abrazo mortal.
        engine = create_async_engine(url, poolclass=NullPool)
    else:
        engine = create_async_engine(
            "sqlite+aiosqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    return engine, url is not None


async def _desechar(engine, es_postgres: bool) -> None:
    if es_postgres:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def client():
    engine, es_postgres = await _motor_limpio()
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
    await _desechar(engine, es_postgres)


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
async def db_engine():
    """
    Motor de la base de las pruebas del libro. Mismo criterio que `client`:
    Postgres real con `TEST_POSTGRES_URL` (desechable, debe terminar en
    `_test`: se BORRA TODO al entrar y al salir), SQLite en memoria si no.
    """
    engine, es_postgres = await _motor_limpio()
    yield engine
    await _desechar(engine, es_postgres)


@pytest_asyncio.fixture
async def db(db_engine):
    """
    Sesión directa contra el esquema, sin pasar por HTTP.

    La usan las pruebas del libro mayor: lo que verifican son las restricciones
    de la base (partida doble, montos positivos, idempotencia), y meterlas por
    un endpoint solo añadiría ruido entre la regla y su comprobación.
    """
    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as session:
        yield session


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
    Registra un titular y devuelve su sesión por el camino REAL.

    El alta abre sesión y vincula el teléfono que la pidió, así que no hace
    falta pasar por authenticate -> OTP -> sessions. Ese camino sigue siendo
    el del LOGIN desde un teléfono desconocido y tiene sus propios tests;
    aquí se recorre el del alta, que es el que viven estos fixtures.

    `otp_codes` se mantiene en la firma para que los fixtures que lo piden
    sigan capturando los códigos en vez de enviarlos de verdad.
    """
    del otp_codes  # el alta ya no emite ningún OTP; ver docstring.
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": dni,
            "nombres": nombres,
            "apellidos": apellidos,
            "email": f"{dni}@correo.pe",
            "pin": PIN_DE_PRUEBA,
        },
        headers={"X-Device-Id": f"dev-{dni}"},
    )
    assert r.status_code == 201, r.text
    cuerpo = r.json()
    return Registrado(
        dni=dni, token=cuerpo["session_token"], user_id=cuerpo["id"]
    )


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
