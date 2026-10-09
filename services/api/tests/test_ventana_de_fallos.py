import asyncio

from app.core.config import settings
from tests.test_registro_y_login import autenticar, registrar


async def test_los_fallos_viejos_del_dni_caducan(client, monkeypatch):
    # Visto en local: un PIN errado de ayer seguía restando, y el usuario
    # quedaba bloqueado al segundo intento de hoy.
    monkeypatch.setattr(settings, "IDENTIFIER_WINDOW_SECONDS", 1)
    await registrar(client)
    await autenticar(client, pin="999999")
    await autenticar(client, pin="999999")

    await asyncio.sleep(1.2)
    respuesta = await autenticar(client, pin="999999")

    # Solo cuenta el de ahora: no bloquea y quedan dos.
    assert respuesta.status_code == 401
    assert respuesta.json()["attempts_left"] == 2


async def test_tres_fallos_dentro_de_la_ventana_si_bloquean(client):
    await registrar(client)
    for _ in range(2):
        await autenticar(client, pin="999999")

    respuesta = await autenticar(client, pin="999999")

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "IDENTIFIER_LOCKED"


async def test_el_fallo_que_bloquea_al_telefono_lo_dice(client):
    # El décimo fallo es el que dispara el bloqueo del teléfono. Antes esa
    # respuesta decía IDENTIFIER_LOCKED, como si el bloqueado fuera el DNI.
    for i in range(9):
        await autenticar(client, dni=f"1000000{i}", pin="999999", device="ladron")

    respuesta = await autenticar(client, dni="20000000", pin="999999", device="ladron")

    assert respuesta.status_code == 423
    assert respuesta.json()["code"] == "DEVICE_LOCKED"
