"""Comprobación de esquema al arrancar; jamás modifica una base existente."""

from pathlib import Path
from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory


def migration_config():
    return Config(str(Path(__file__).resolve().parents[2] / "alembic.ini"))


def require_current_schema(connection):
    expected = set(ScriptDirectory.from_config(migration_config()).get_heads())
    actual = set(MigrationContext.configure(connection).get_current_heads())
    if actual != expected:
        raise RuntimeError(
            "Esquema sin migrar. Consulte docs/migraciones.md antes de ejecutar alembic upgrade head."
        )


def stamp_recreated_schema(connection):
    """Solo tras reset autorizado que acaba de crear TODOS los modelos."""
    from alembic import command

    cfg = migration_config()
    cfg.attributes["connection"] = connection
    command.stamp(cfg, "head", purge=True)
