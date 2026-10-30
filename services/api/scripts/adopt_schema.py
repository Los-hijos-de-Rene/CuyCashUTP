"""Adopta SOLO el esquema previo exacto; no altera filas ni tablas existentes.

Ejecutar tras comprobar respaldo/restauración y antes de upgrade head.
"""

import asyncio
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory
import sqlalchemy as sa
from sqlalchemy.ext.asyncio import create_async_engine
from app.core.config import settings
from app.db.base import _engine_config, configure_sqlite_transactions
from app.db.migrations import migration_config


class Baseline:
    """Captura el DDL inmutable de 0001 sin reflejarlo en otro dialecto."""

    def __init__(self):
        self.metadata = sa.MetaData()

    def create_table(self, name, *columns, **kwargs):
        return sa.Table(name, self.metadata, *columns, **kwargs)

    def create_index(self, name, table_name, columns, **kwargs):
        table = self.metadata.tables[table_name]
        return sa.Index(name, *(table.c[c] for c in columns), **kwargs)

    def f(self, name):
        return name


def baseline_metadata(cfg):
    module = ScriptDirectory.from_config(cfg).get_revision("0001").module
    recorder = Baseline()
    original = module.op
    try:
        module.op = recorder
        module.upgrade()
    finally:
        module.op = original
    return recorder.metadata


def normalized(sql):
    # PostgreSQL deparsea IN como = ANY(ARRAY[...]) y añade casts/paréntesis.
    sql = re.sub(
        r"::(?:character varying|text|bigint|integer|boolean)(?:\[\])?",
        "",
        str(sql),
        flags=re.I,
    )
    sql = re.sub(r"=\s*ANY\s*\(\s*ARRAY\[", " IN (", sql, flags=re.I).replace("]", ")")
    return re.sub(r"[\s()]", "", sql).lower()


def adopt(connection):
    cfg = migration_config()
    ctx = MigrationContext.configure(
        connection, opts={"compare_type": True, "compare_server_default": True}
    )
    if ctx.get_current_heads():
        raise RuntimeError("La base ya está versionada; no se vuelve a adoptar.")
    metadata = baseline_metadata(cfg)
    differences = compare_metadata(ctx, metadata)
    actual = sa.inspect(connection)
    names = set(actual.get_table_names())
    for table in metadata.tables.values():
        if table.name not in names:
            continue
        expected_checks = {
            (c.name, normalized(c.sqltext))
            for c in table.constraints
            if isinstance(c, sa.CheckConstraint)
        }
        actual_checks = {
            (c["name"], normalized(c["sqltext"]))
            for c in actual.get_check_constraints(table.name)
        }
        if actual_checks != expected_checks:
            differences.append(("checks", table.name))
        if actual.get_pk_constraint(table.name)["constrained_columns"] != [
            c.name for c in table.primary_key
        ]:
            differences.append(("primary_key", table.name))
        indexes = {i["name"]: i for i in actual.get_indexes(table.name)}
        dialect = connection.dialect.name
        for index in table.indexes:
            expected_where = index.dialect_options[dialect].get("where")
            actual_where = (
                indexes.get(index.name, {})
                .get("dialect_options", {})
                .get(dialect + "_where")
            )
            if normalized(expected_where) != normalized(actual_where):
                differences.append(("index_predicate", index.name))
    if differences:
        raise RuntimeError(
            "El esquema difiere de 0001. No se ha adoptado; requiere revisión específica."
        )
    cfg.attributes["connection"] = connection
    command.stamp(cfg, "0001")


async def main():
    url, args = _engine_config(settings.DATABASE_URL)
    engine = create_async_engine(url, connect_args=args)
    configure_sqlite_transactions(engine)
    try:
        async with engine.begin() as connection:
            await connection.run_sync(adopt)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
