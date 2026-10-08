"""
Datos de prueba en LOCAL: reiniciar la base y sembrar usuarios ficticios.

Uso (desde services/api, con docker compose arriba):

    docker compose exec auth python -m scripts.dev reset-y-seed   # base vacía + usuarios de prueba
    docker compose exec auth python -m scripts.dev seed           # solo agrega los que falten
    docker compose exec auth python -m scripts.dev reset          # solo vacía la base

Lo mismo está en el menú de desarrollo de la app (flavor local): mantener
presionado el logo en la pantalla de bienvenida. Documentado en
services/api/README.md, sección "Datos de prueba en local".

Se niega a correr si la base no es local o si ENV=production.
"""

import asyncio
import sys

from app.db.base import SessionLocal
from app.services import dev_tools

COMANDOS = ("reset", "seed", "reset-y-seed")


async def main(comando: str) -> None:
    if not dev_tools.puede_correr():
        print(
            "Rechazado: la base no es local (o ENV=production). Este comando BORRA datos.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    async with SessionLocal() as session:
        if comando in ("reset", "reset-y-seed"):
            await dev_tools.reiniciar(session)
            print("Base vaciada.")
        if comando in ("seed", "reset-y-seed"):
            creados = await dev_tools.sembrar(session)
            print(f"Usuarios de prueba creados: {', '.join(creados) or 'ninguno (ya existían)'}")

    if comando != "reset":
        print(f"\nPIN de todos los usuarios de prueba: {dev_tools.PIN_DE_PRUEBA}")
        for u in dev_tools.USUARIOS_DE_PRUEBA:
            print(f"  {u.nombres} {u.apellidos}  DNI {u.dni}  {u.alias}  (S/ {dev_tools.SALDO_INICIAL / 100:,.2f})")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in COMANDOS:
        print(f"Uso: python -m scripts.dev [{' | '.join(COMANDOS)}]", file=sys.stderr)
        raise SystemExit(2)
    asyncio.run(main(sys.argv[1]))
