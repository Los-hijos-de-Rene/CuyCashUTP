"""
El script de recreación del esquema.

Es destructivo, así que lo que importa es que el cerrojo funcione y que no
muera por la forma de la cadena de conexión justo cuando se le necesita.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from reset_schema import _es_local  # noqa: E402

from app.db.base import _engine_config  # noqa: E402

NEON = (
    "postgresql://usuario:clave@ep-algo.us-east-2.aws.neon.tech/neondb"
    "?sslmode=require&channel_binding=require"
)


def test_la_cadena_de_neon_se_normaliza_para_asyncpg():
    """
    Copiada del panel tal cual: viene como `postgresql://` y con parámetros de
    libpq. Sin normalizar, SQLAlchemy busca psycopg2 —que no está instalado— y
    el script muere antes de tocar nada.
    """
    url, connect_args = _engine_config(NEON)

    assert url.startswith("postgresql+asyncpg://")
    assert "sslmode" not in url
    assert "channel_binding" not in url
    # Una base gestionada solo acepta TLS: perder esa intención es no conectar.
    assert connect_args == {"ssl": True}


def test_neon_no_se_considera_local():
    """El cerrojo tiene que ver un destino remoto donde lo hay."""
    assert _es_local(NEON) is False


def test_sqlite_y_localhost_si_son_locales():
    assert _es_local("sqlite+aiosqlite:///./cuycash.db") is True
    assert _es_local("postgresql+asyncpg://u:c@localhost:5432/cuycash") is True
    assert _es_local("postgresql+asyncpg://u:c@127.0.0.1:5432/cuycash") is True
