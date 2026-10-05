"""
Borra y recrea el esquema completo.

Existe porque el servicio crea tablas con `Base.metadata.create_all`, que NO
altera las que ya existen: un CHECK modificado no llega nunca a una base ya
desplegada. Mientras no haya datos reales, recrear es más barato que migrar.

Es DESTRUCTIVO. El cerrojo de abajo está puesto para el día en que sí haya
datos y alguien lo ejecute por costumbre.
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings  # noqa: E402
from app.db import models  # noqa: E402,F401  (registra las tablas en Base.metadata)
from app.db.base import Base  # noqa: E402
from sqlalchemy.ext.asyncio import create_async_engine  # noqa: E402


async def main() -> None:
    destino = settings.DATABASE_URL
    produccion = "neon.tech" in destino or os.getenv("ENV") == "production"
    if produccion and os.getenv("ALLOW_DESTRUCTIVE_RESET") != "1":
        print(
            "Rechazado: el destino parece producción.\n"
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
