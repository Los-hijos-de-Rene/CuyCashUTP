import asyncio
from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.pool import NullPool
from app.core.config import settings
from app.db.base import Base, _engine_config, configure_sqlite_transactions
from app.db import models  # noqa: F401

config = context.config

def run(connection):
    context.configure(connection=connection, target_metadata=Base.metadata,
                      compare_type=True, render_as_batch=connection.dialect.name == "sqlite")
    with context.begin_transaction():
        context.run_migrations()

async def online():
    url, args = _engine_config(settings.DATABASE_URL)
    engine = create_async_engine(url, connect_args=args, poolclass=NullPool)
    configure_sqlite_transactions(engine)
    try:
        async with engine.connect() as connection:
            await connection.run_sync(run)
    finally:
        await engine.dispose()

if context.is_offline_mode():
    raise RuntimeError("Use una conexión para comprobar la revisión del esquema.")
elif config.attributes.get("connection") is not None:
    run(config.attributes["connection"])
else:
    asyncio.run(online())
