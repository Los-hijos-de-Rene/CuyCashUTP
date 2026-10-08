"""
Herramientas de desarrollo local (menú de la app y scripts/dev.py).

Lo que más importa aquí es el cerrojo: estas rutas BORRAN la base, así que
fuera de local no deben existir.
"""

import pytest
from sqlalchemy import select

from app.core.config import settings
from app.core.security import pin_is_valid
from app.db.models import Account, User
from app.services import dev_tools
from app.services.notifier import LogNotifier

CLAVE = "clave-de-prueba"


@pytest.fixture
def dev_habilitado(monkeypatch):
    monkeypatch.setattr(settings, "DEV_TOOLS", True)
    monkeypatch.setattr(settings, "DEV_TOOLS_KEY", CLAVE)


def con_clave(clave=CLAVE):
    return {"X-Dev-Key": clave, "X-Device-Id": "d"}


@pytest.mark.parametrize("ruta", ["/v1/dev/reset-y-seed", "/v1/dev/seed"])
async def test_sin_dev_tools_las_rutas_no_existen(client, ruta):
    r = await client.post(ruta, headers=con_clave())
    assert r.status_code == 404


async def test_dev_tools_sin_clave_configurada_no_existen(client, monkeypatch):
    monkeypatch.setattr(settings, "DEV_TOOLS", True)
    monkeypatch.setattr(settings, "DEV_TOOLS_KEY", "")
    r = await client.post("/v1/dev/reset-y-seed", headers=con_clave(""))
    assert r.status_code == 404


async def test_con_una_base_remota_no_existen(client, dev_habilitado, monkeypatch):
    monkeypatch.setattr(
        settings, "DATABASE_URL", "postgresql+asyncpg://u:p@ep-algo.neon.tech/cuycash"
    )
    r = await client.post("/v1/dev/reset-y-seed", headers=con_clave())
    assert r.status_code == 404


async def test_con_env_production_no_existen(client, dev_habilitado, monkeypatch):
    monkeypatch.setenv("ENV", "production")
    r = await client.post("/v1/dev/reset-y-seed", headers=con_clave())
    assert r.status_code == 404


async def test_clave_equivocada_es_403(client, dev_habilitado):
    r = await client.post("/v1/dev/seed", headers=con_clave("otra"))
    assert r.status_code == 403


async def test_seed_crea_usuarios_con_cuenta_y_saldo(client, db_de_client, dev_habilitado):
    r = await client.post("/v1/dev/seed", headers=con_clave())

    assert r.status_code == 200
    assert sorted(r.json()["creados"]) == ["11111111", "22222222"]
    ana = (await db_de_client.execute(select(User).where(User.dni == "11111111"))).scalar_one()
    assert ana.alias == "@ana"
    cuenta = (
        await db_de_client.execute(select(Account).where(Account.user_id == ana.id))
    ).scalar_one()
    assert cuenta.moneda == "PEN"
    assert cuenta.saldo_disponible == dev_tools.SALDO_INICIAL


async def test_seed_se_puede_repetir(client, dev_habilitado):
    await client.post("/v1/dev/seed", headers=con_clave())
    r = await client.post("/v1/dev/seed", headers=con_clave())

    assert r.json()["creados"] == []


async def test_reset_y_seed_borra_lo_demas(client, db_de_client, dev_habilitado):
    alta = await client.post(
        "/v1/auth/register",
        json={
            "dni": "74882838",
            "nombres": "Jair",
            "apellidos": "Prueba",
            "email": "jair@correo.com",
            "pin": "024689",
        },
        headers={"X-Device-Id": "d"},
    )
    assert alta.status_code == 201

    r = await client.post("/v1/dev/reset-y-seed", headers=con_clave())

    assert r.status_code == 200
    dnis = sorted((await db_de_client.execute(select(User.dni))).scalars())
    assert dnis == ["11111111", "22222222"]


async def test_los_usuarios_de_prueba_pueden_entrar_con_el_pin(client, dev_habilitado):
    await client.post("/v1/dev/seed", headers=con_clave())

    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": "11111111", "pin": dev_tools.PIN_DE_PRUEBA},
        headers={"X-Device-Id": "telefono"},
    )

    assert r.status_code == 200
    assert pin_is_valid(dev_tools.PIN_DE_PRUEBA)


async def test_otp_muestra_el_ultimo_codigo_enviado(client, dev_habilitado):
    await LogNotifier().send("ana@prueba.local", "482167", "device")

    r = await client.get("/v1/dev/otp", headers=con_clave())

    assert r.status_code == 200
    assert r.json()["codigos"][0]["codigo"] == "482167"


async def test_fuera_de_local_no_se_guardan_otps(monkeypatch):
    monkeypatch.setattr(settings, "DEV_TOOLS", False)
    antes = len(dev_tools.ultimos_otps())

    await LogNotifier().send("x@y.com", "111222", "device")

    assert len(dev_tools.ultimos_otps()) == antes


@pytest.mark.parametrize(
    "url, local",
    [
        ("sqlite+aiosqlite:///:memory:", True),
        ("postgresql+asyncpg://cuycash:cuycash@db:5432/cuycash", True),
        ("postgresql+asyncpg://cuycash:cuycash@localhost:5432/cuycash", True),
        ("postgresql://u:p@ep-x.us-east-2.aws.neon.tech/cuycash?sslmode=require", False),
    ],
)
def test_que_se_considera_base_local(url, local):
    assert dev_tools.es_base_local(url) is local
