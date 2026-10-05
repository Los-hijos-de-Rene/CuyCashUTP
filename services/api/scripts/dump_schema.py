"""
Genera `schema.sql` a partir de los modelos de SQLAlchemy.

El script existe para que el DDL no se escriba a mano. Un esquema mantenido en
paralelo al código se desincroniza en la primera semana, y la evidencia de
consistencia entre modelo y base deja de significar nada. Aquí los dos salen
de la misma fuente: si divergen, es que alguien editó el archivo generado.

Uso:
    .venv/bin/python scripts/dump_schema.py > schema.sql
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy.dialects import postgresql  # noqa: E402
from sqlalchemy.schema import CreateIndex, CreateTable  # noqa: E402

from app.db.base import Base  # noqa: E402
from app.db import models  # noqa: E402,F401  (importar registra las tablas)

CABECERA = """\
-- CuyCash · esquema de la base de identidad y cuentas
--
-- ARCHIVO GENERADO. No editar a mano.
-- Se produce con:  .venv/bin/python scripts/dump_schema.py > schema.sql
-- La fuente de verdad son los modelos en app/db/models.py.
--
-- Diseño y justificación de cada decisión: docs/modelo-datos.md
"""


def main() -> None:
    dialecto = postgresql.dialect()
    print(CABECERA)
    # `sorted_tables` las ordena por dependencia: ninguna llave foránea
    # apunta a una tabla que todavía no exista.
    for tabla in Base.metadata.sorted_tables:
        print(f"{CreateTable(tabla).compile(dialect=dialecto)};")
        # `indexes` es un set: sin ordenar, el orden cambia entre ejecuciones
        # y el diff contra schema.sql falla al azar.
        for indice in sorted(tabla.indexes, key=lambda i: i.name):
            print(f"{CreateIndex(indice).compile(dialect=dialecto)};")
        print()


if __name__ == "__main__":
    main()
