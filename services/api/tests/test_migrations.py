import pytest
from alembic import command
from alembic.autogenerate import compare_metadata
from alembic.migration import MigrationContext
from sqlalchemy import text
from app.db.base import Base
from app.db.migrations import migration_config, require_current_schema
from scripts.adopt_schema import adopt


def upgrade(connection, revision):
    cfg = migration_config()
    cfg.attributes["connection"] = connection
    command.upgrade(cfg, revision)


async def prepare(engine):
    async with engine.begin() as c:
        await c.run_sync(Base.metadata.drop_all)
        await c.execute(text("DROP TABLE IF EXISTS alembic_version"))
        await c.run_sync(lambda conn: upgrade(conn, "0001"))
        await c.execute(
            text(
                """INSERT INTO users
            (id,dni,nombres,apellidos,email,alias,pin_hash,pin_updated_at,kyc_status,created_at)
            VALUES ('legacy','12345678','Ana','Prueba','ana@example.test','ana','hash',CURRENT_TIMESTAMP,'pending',CURRENT_TIMESTAMP)"""
            )
        )
        await c.execute(
            text(
                """INSERT INTO accounts
            (id,user_id,numero,tipo,moneda,estado,saldo_disponible,saldo_contable,created_at)
            VALUES ('legacy-account','legacy','19112345678901','ahorro','PEN','activa',12345,12345,CURRENT_TIMESTAMP)"""
            )
        )

        await c.execute(
            text(
                """INSERT INTO accounts
            (id,numero,tipo,moneda,estado,saldo_disponible,saldo_contable,created_at)
            VALUES ('legacy-cash','19100000000000','sistema','PEN','activa',-12345,-12345,CURRENT_TIMESTAMP)"""
            )
        )
        await c.execute(
            text(
                """INSERT INTO transactions
            (id,tipo,estado,idempotency_key,request_fingerprint,created_at)
            VALUES ('legacy-tx','recarga','confirmada','legacy-idempotency-key','fingerprint',CURRENT_TIMESTAMP)"""
            )
        )
        for entry_id, account_id, direction, balance in [
            ("legacy-debit", "legacy-cash", "debito", -12345),
            ("legacy-credit", "legacy-account", "credito", 12345),
        ]:
            await c.execute(
                text(
                    """INSERT INTO ledger_entries
                (id,transaction_id,account_id,direccion,monto,moneda,saldo_posterior,created_at)
                VALUES (:id,'legacy-tx',:account,:direction,12345,'PEN',:balance,CURRENT_TIMESTAMP)"""
                ),
                dict(
                    id=entry_id,
                    account=account_id,
                    direction=direction,
                    balance=balance,
                ),
            )


async def cleanup(engine):
    async with engine.begin() as c:
        await c.execute(text("DROP TABLE IF EXISTS alembic_version"))


async def test_upgrade_preserves_existing_user_and_money(db_engine):
    try:
        await prepare(db_engine)
        async with db_engine.begin() as c:
            with pytest.raises(RuntimeError, match="sin migrar"):
                await c.run_sync(require_current_schema)
            await c.run_sync(lambda conn: upgrade(conn, "head"))
            await c.run_sync(require_current_schema)
            assert (
                await c.execute(text("SELECT count(*) FROM ledger_entries"))
            ).scalar_one() == 2
            assert (
                await c.execute(text("SELECT idempotency_key FROM transactions"))
            ).scalar_one() == "legacy-idempotency-key"
            assert (await c.execute(text("SELECT dni,rol FROM users"))).one() == (
                "12345678",
                "titular",
            )
            assert (
                await c.execute(
                    text(
                        "SELECT saldo_disponible,saldo_contable FROM accounts WHERE id='legacy-account'"
                    )
                )
            ).one() == (12345, 12345)
            differences = await c.run_sync(
                lambda conn: compare_metadata(
                    MigrationContext.configure(conn), Base.metadata
                )
            )
            assert differences == []
            await c.run_sync(lambda conn: upgrade(conn, "head"))
    finally:
        await cleanup(db_engine)


async def test_adoption_checks_legacy_schema_before_stamping(db_engine):
    try:
        await prepare(db_engine)
        async with db_engine.begin() as c:
            await c.execute(text("DROP TABLE alembic_version"))
            await c.run_sync(adopt)
            assert (
                await c.execute(text("SELECT version_num FROM alembic_version"))
            ).scalar_one() == "0001"
            await c.run_sync(lambda conn: upgrade(conn, "head"))
            assert (
                await c.execute(
                    text(
                        "SELECT saldo_contable FROM accounts WHERE id='legacy-account'"
                    )
                )
            ).scalar_one() == 12345
    finally:
        await cleanup(db_engine)


async def test_adoption_refuses_unknown_column(db_engine):
    try:
        await prepare(db_engine)
        async with db_engine.begin() as c:
            await c.execute(text("DROP TABLE alembic_version"))
            await c.execute(text("ALTER TABLE users ADD COLUMN unexpected INTEGER"))
            with pytest.raises(RuntimeError, match="difiere"):
                await c.run_sync(adopt)
            assert (
                await c.execute(text("SELECT dni FROM users"))
            ).scalar_one() == "12345678"
    finally:
        await cleanup(db_engine)


@pytest.mark.parametrize("predicate", ["ahorro", "SUELDO", "suel do"])
async def test_adoption_refuses_changed_partial_index(db_engine, predicate):
    try:
        await prepare(db_engine)
        async with db_engine.begin() as c:
            await c.execute(text("DROP TABLE alembic_version"))
            await c.execute(text("DROP INDEX ux_accounts_un_sueldo"))
            await c.execute(
                text(
                    f"CREATE UNIQUE INDEX ux_accounts_un_sueldo ON accounts (user_id) WHERE tipo = '{predicate}'"
                )
            )
            with pytest.raises(RuntimeError, match="difiere"):
                await c.run_sync(adopt)
    finally:
        await cleanup(db_engine)


async def test_reset_recreated_schema_stamps_current_revision(db_engine):
    from app.db.migrations import stamp_recreated_schema

    try:
        async with db_engine.begin() as c:
            await c.run_sync(stamp_recreated_schema)
            await c.run_sync(require_current_schema)
    finally:
        await cleanup(db_engine)


def test_cli_creates_database_and_lifespan_checks_it(tmp_path):
    import os
    import subprocess
    import sys
    from pathlib import Path

    root = Path(__file__).resolve().parents[1]
    env = dict(
        os.environ, DATABASE_URL=f'sqlite+aiosqlite:///{tmp_path / "migration.db"}'
    )
    for args in [["-m", "alembic", "upgrade", "head"], ["-m", "alembic", "check"]]:
        result = subprocess.run(
            [sys.executable, *args], cwd=root, env=env, capture_output=True, text=True
        )
        assert result.returncode == 0, result.stderr
    # Ejecutar el mismo ciclo de vida que Uvicorn.
    script = "import asyncio\nfrom app.main import app\nasync def run():\n async with app.router.lifespan_context(app):\n  pass\nasyncio.run(run())"
    result = subprocess.run(
        [sys.executable, "-c", script],
        cwd=root,
        env=env,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
