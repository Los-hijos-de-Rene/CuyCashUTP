"""
Dos aperturas de cuenta sueldo del mismo titular a la vez dejan UNA.

Solo tiene sentido contra Postgres (`TEST_POSTGRES_URL`): SQLite serializa las
escrituras y el choque no ocurre. Como los otros tests `postgres`, NO se ha
ejecutado aún contra una base real.
"""

import asyncio
import os

import pytest
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import async_sessionmaker

from app.db.models import Account, User
from app.services import accounts


@pytest.mark.postgres
@pytest.mark.asyncio
async def test_dos_sueldos_a_la_vez_dejan_uno(db_engine):
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")
    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as s:
        u = User(dni="70000099", nombres="A", apellidos="B", email="a@b.pe",
                 pin_hash="x", alias="@a70000099")
        s.add(u)
        await s.commit()
        user_id = u.id

    async def abrir():
        async with maker() as s:
            try:
                await accounts.abrir_cuenta(s, user_id, tipo="sueldo")
                await s.commit()
                return "ok"
            except IntegrityError:
                await s.rollback()
                return "choque"

    resultados = await asyncio.gather(abrir(), abrir())
    assert sorted(resultados) == ["choque", "ok"]
    async with maker() as s:
        n = (await s.execute(
            select(func.count()).select_from(Account)
            .where(Account.user_id == user_id, Account.tipo == "sueldo")
        )).scalar_one()
    assert n == 1
