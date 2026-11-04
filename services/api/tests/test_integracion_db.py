
"""
APF3-C - Issue #100
Pruebas de integracion de base de datos.

INT-D1: disponibilidad de /health/db.
INT-D2: error controlado ante una falla.
INT-D3: recuperacion de conexion con pool_pre_ping.
"""

import importlib
import os
from types import SimpleNamespace

import pytest
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy.pool import NullPool

from app.db.base import _engine_config


@pytest.mark.asyncio
async def test_int_d1_health_db_disponible(client):
    """
    INT-D1: el endpoint informa que la base responde.
    """

    respuesta = await client.get("/health/db")

    assert respuesta.status_code == 200

    datos = respuesta.json()

    assert datos["status"] == "ok"
    assert datos["database"] in ("sqlite", "postgresql")
    assert isinstance(datos["latency_ms"], (int, float))
    assert datos["latency_ms"] >= 0


@pytest.mark.asyncio
async def test_int_d2_health_db_error_controlado(
    client, monkeypatch
):
    """
    INT-D2: simula una falla y comprueba que el
    endpoint no revela informacion interna.
    """

    modulo = importlib.import_module("app.main")

    secreto = "CLAVE_INTERNA_NO_DEBE_APARECER"

    class MotorConFallo:
        dialect = SimpleNamespace(name="postgresql")

        def connect(self):
            raise RuntimeError(
                f"Conexion rechazada: {secreto}"
            )

    monkeypatch.setattr(
        modulo,
        "engine",
        MotorConFallo(),
    )

    respuesta = await client.get("/health/db")

    assert respuesta.status_code == 503

    datos = respuesta.json()

    assert datos["status"] == "unavailable"
    assert datos["database"] == "postgresql"

    assert secreto not in respuesta.text
    assert "Traceback" not in respuesta.text
    assert "RuntimeError" not in respuesta.text


@pytest.mark.asyncio
async def test_int_d3_pool_pre_ping_recupera_conexion():
    """
    INT-D3: usa PostgreSQL real para comprobar
    la recuperacion de una conexion terminada.

    Se ejecuta solo si TEST_POSTGRES_URL esta
    configurada con una base de pruebas.
    """

    url = os.getenv("TEST_POSTGRES_URL")

    if not url:
        pytest.skip(
            "Se necesita TEST_POSTGRES_URL "
            "para verificar PostgreSQL real."
        )

    # Nunca utilizar una base de produccion.
    nombre = make_url(url).database or ""

    if not nombre.endswith("_test"):
        pytest.fail(
            "La base de pruebas debe terminar en _test."
        )

    url_normalizada, connect_args = _engine_config(url)

    motor = create_async_engine(
        url_normalizada,
        connect_args=connect_args,
        pool_pre_ping=True,
        pool_size=1,
        max_overflow=0,
    )

    # Motor independiente para finalizar la conexion.
    control = create_async_engine(
        url_normalizada,
        connect_args=connect_args,
        poolclass=NullPool,
    )

    try:
        # Obtener una conexion que luego quedara en el pool.
        async with motor.connect() as conexion:
            resultado = await conexion.execute(
                text("SELECT pg_backend_pid()")
            )
            primer_pid = resultado.scalar_one()

        # Simular la desconexion de PostgreSQL.
        async with control.connect() as conexion:
            resultado = await conexion.execute(
                text("SELECT pg_terminate_backend(:pid)"),
                {"pid": primer_pid},
            )
            terminada = resultado.scalar_one()

        assert terminada is True

        # Al reutilizar el pool, pre_ping debe detectar
        # la conexion muerta y obtener una nueva.
        async with motor.connect() as conexion:
            resultado = await conexion.execute(
                text("SELECT pg_backend_pid()")
            )
            segundo_pid = resultado.scalar_one()

        assert segundo_pid != primer_pid

    finally:
        await motor.dispose()
        await control.dispose()
