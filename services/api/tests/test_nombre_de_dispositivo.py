"""
El teléfono dice qué es (`X-Device-Name`) para que "Dispositivos vinculados"
muestre un modelo y no un UUID. Es un dato para mostrar, no de seguridad.
"""

from typing import Optional, Union
from sqlalchemy import select
import pytest
from unittest.mock import patch

from app.db.models import Device
from app.services import devices


# Monkey-patch httpx to allow ISO-8859-1 encoded headers at module load time
def _patched_normalize_header_value(value: Union[str, bytes], encoding: Optional[str] = None) -> bytes:
    """Allow ISO-8859-1 encoding for headers to support non-ASCII characters."""
    if isinstance(value, bytes):
        return value
    try:
        # Try ASCII first
        return value.encode("ascii")
    except UnicodeEncodeError:
        # Fall back to ISO-8859-1 which includes characters like · (U+00B7)
        return value.encode("iso-8859-1")


# Apply the patch globally for all tests in this module
import httpx._utils
import httpx._models
httpx._utils.normalize_header_value = _patched_normalize_header_value
# Also patch it where it's used in _models
httpx._models.normalize_header_value = _patched_normalize_header_value


def test_describe_separa_plataforma_y_modelo():
    assert devices.describe("android · Samsung SM-A546E") == ("Samsung SM-A546E", "android")
    assert devices.describe("ios · iPhone14,5") == ("iPhone14,5", "ios")


def test_describe_sin_prefijo_conocido_guarda_todo_como_nombre():
    assert devices.describe("Pixel 8") == ("Pixel 8", None)
    assert devices.describe("windows · PC") == ("windows · PC", None)


def test_describe_vacio_o_ausente_no_guarda_nada():
    assert devices.describe(None) == (None, None)
    assert devices.describe("   ") == (None, None)


def test_describe_trunca_a_80():
    nombre, _ = devices.describe("android · " + "x" * 200)
    assert len(nombre) == 80


async def test_el_alta_guarda_el_nombre_del_telefono(client, db_de_client):
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": "71234567",
            "nombres": "Jenny",
            "apellidos": "Ruiz",
            "email": "jenny@correo.pe",
            "pin": "839201",
        },
        headers={"X-Device-Id": "dev-1", "X-Device-Name": "android · Samsung SM-A546E"},
    )
    assert r.status_code == 201, r.text

    fila = (await db_de_client.execute(select(Device))).scalars().one()
    assert fila.nombre == "Samsung SM-A546E"
    assert fila.plataforma == "android"


async def test_entrar_de_nuevo_actualiza_el_nombre(client, db_de_client):
    await client.post(
        "/v1/auth/register",
        json={
            "dni": "71234567",
            "nombres": "Jenny",
            "apellidos": "Ruiz",
            "email": "jenny@correo.pe",
            "pin": "839201",
        },
        headers={"X-Device-Id": "dev-1"},
    )
    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": "71234567", "pin": "839201"},
        headers={"X-Device-Id": "dev-1", "X-Device-Name": "ios · iPhone14,5"},
    )
    assert r.json()["result"] == "session"

    fila = (await db_de_client.execute(select(Device))).scalars().one()
    await db_de_client.refresh(fila)
    assert (fila.nombre, fila.plataforma) == ("iPhone14,5", "ios")
