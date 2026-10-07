from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


class Base(DeclarativeBase):
    pass


# Parámetros que los Postgres gestionados (Neon, Supabase, Render) incluyen en
# la cadena que entregan para copiar y pegar. Son de `libpq`/psycopg2: asyncpg
# no los conoce y rechaza la conexión al arrancar, antes de atender nada.
_LIBPQ_ONLY = {"sslmode", "channel_binding", "options", "target_session_attrs"}


def _engine_config(url: str) -> tuple:
    """
    Normaliza la cadena de conexión y separa el modo TLS.

    Dos arreglos, los dos para que una cadena copiada del panel de un Postgres
    gestionado funcione tal cual:

    1. `postgresql://` se promueve a `postgresql+asyncpg://`. Sin el driver
       explícito, SQLAlchemy busca psycopg2, que no está instalado, y el
       servicio no llega a arrancar.
    2. Se quitan los parámetros de libpq y, si alguno pedía cifrado, se traduce
       a lo que asyncpg sí entiende: `ssl` en los argumentos de conexión. Una
       base gestionada solo acepta TLS, así que perder esa intención por el
       camino equivale a no poder conectarse.
    """
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    if not url.startswith("postgresql+asyncpg"):
        return url, {}

    parts = urlsplit(url)
    params = parse_qsl(parts.query, keep_blank_values=True)

    descartados = {k: v for k, v in params if k in _LIBPQ_ONLY}
    conservados = [(k, v) for k, v in params if k not in _LIBPQ_ONLY]

    limpia = urlunsplit(parts._replace(query=urlencode(conservados)))

    exige_tls = descartados.get("sslmode", "") not in ("", "disable", "allow")
    return limpia, {"ssl": True} if exige_tls else {}


_url, _connect_args = _engine_config(settings.DATABASE_URL)

# `pool_pre_ping`: Neon suspende el cómputo tras 5 min sin uso y cierra las
# conexiones; sin el ping, la primera petición después del reposo tomaba una
# conexión muerta del pool y respondía 500 (visto en producción el
# 2026-10-07 con scripts/smoke_prod.sh). El ping (`SELECT 1` al sacar una
# conexión) la descarta y abre otra. Cuesta un viaje corto por petición.
engine = create_async_engine(
    _url, future=True, connect_args=_connect_args, pool_pre_ping=True
)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)


async def get_session() -> AsyncSession:
    async with SessionLocal() as session:
        yield session
