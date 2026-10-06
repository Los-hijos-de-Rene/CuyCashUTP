"""
Borra y recrea el esquema completo.

Existe porque el servicio crea tablas con `Base.metadata.create_all`, que NO
altera las que ya existen: un CHECK modificado no llega nunca a una base ya
desplegada. Mientras no haya datos reales, recrear es más barato que migrar.

Es DESTRUCTIVO. El cerrojo de abajo está puesto para el día en que sí haya
datos y alguien lo ejecute por costumbre.

El cerrojo es una lista de PERMITIDOS, no de prohibidos: sin
ALLOW_DESTRUCTIVE_RESET=1 solo se acepta SQLite y los hosts locales
(localhost, 127.0.0.1). Una lista de prohibidos (neon.tech, ENV=production...)
siempre está incompleta: basta con un proveedor que nadie anticipó, y aquí el
fallo es irreversible. Todo se compara en minúsculas.
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings  # noqa: E402
from app.db import models  # noqa: E402,F401  (registra las tablas en Base.metadata)
from app.db.base import Base  # noqa: E402
from sqlalchemy.engine import make_url  # noqa: E402
from sqlalchemy.ext.asyncio import create_async_engine  # noqa: E402

HOSTS_LOCALES = {"localhost", "127.0.0.1"}


def _es_local(destino: str) -> bool:
    url = make_url(destino)
    if url.get_backend_name().lower() == "sqlite":
        return True
    return (url.host or "").lower() in HOSTS_LOCALES


async def main() -> None:
    destino = settings.DATABASE_URL
    # ENV=production se mantiene como freno extra, aunque el destino sea local.
    produccion = os.getenv("ENV", "").lower() == "production"
    if (produccion or not _es_local(destino)) and os.getenv("ALLOW_DESTRUCTIVE_RESET") != "1":
        print(
            "Rechazado: el destino no es local.\n"
            "Esto BORRA todos los datos. Si es lo que quieres, repite con "
            "ALLOW_DESTRUCTIVE_RESET=1.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    engine = create_async_engine(destino)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()
    print(f"Esquema recreado en {destino.split('@')[-1]}")


if __name__ == "__main__":
    asyncio.run(main())
