"""Entrar con huella: una credencial del servidor que la huella libera en el teléfono."""

from app.core.config import settings
from tests.conftest import PIN_DE_PRUEBA


async def _activar(client, registrado, pin=PIN_DE_PRUEBA):
    return await client.post(
        "/v1/auth/biometric/enroll", json={"pin": pin}, headers=registrado.auth
    )


async def _entrar(client, dni, credencial, device):
    return await client.post(
        "/v1/auth/sessions/biometric",
        json={"dni": dni, "credential": credencial},
        headers={"X-Device-Id": device},
    )


async def test_activar_y_entrar_con_huella(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    r = await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["result"] == "session"
    assert cuerpo["user"]["dni"] == registrado.dni
    nueva = {"Authorization": f"Bearer {cuerpo['session_token']}"}
    assert (await client.get("/v1/me", headers=nueva)).status_code == 200


async def test_activar_con_pin_errado_descuenta_intentos(client, registrado):
    r = await _activar(client, registrado, pin="111222")
    assert r.status_code == 401
    assert r.json()["attempts_left"] == settings.IDENTIFIER_MAX_ATTEMPTS - 1


async def test_reactivar_invalida_la_credencial_anterior(client, registrado):
    vieja = (await _activar(client, registrado)).json()["credential"]
    nueva = (await _activar(client, registrado)).json()["credential"]

    assert (await _entrar(client, registrado.dni, vieja, f"dev-{registrado.dni}")).status_code == 401
    assert (await _entrar(client, registrado.dni, nueva, f"dev-{registrado.dni}")).status_code == 200


async def test_desactivar_la_revoca(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    r = await client.delete("/v1/auth/biometric/current", headers=registrado.auth)
    assert r.status_code == 204
    assert r.content == b""
    assert (await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")).status_code == 401
    # Idempotente.
    assert (await client.delete("/v1/auth/biometric/current", headers=registrado.auth)).status_code == 204


async def test_todos_los_rechazos_responden_igual(client, registrado, otro_registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]

    casos = [
        await _entrar(client, registrado.dni, "inventada", f"dev-{registrado.dni}"),
        await _entrar(client, registrado.dni, credencial, "otro-telefono"),
        await _entrar(client, otro_registrado.dni, credencial, f"dev-{registrado.dni}"),
        await _entrar(client, "00000000", credencial, f"dev-{registrado.dni}"),
    ]

    assert {c.status_code for c in casos} == {401}
    assert len({c.text for c in casos}) == 1
    assert casos[0].json()["code"] == "BIOMETRIC_REVOKED"


async def test_un_dispositivo_desvinculado_no_entra_con_huella(
    client, registrado, otp_codes
):
    from tests.test_cambio_de_pin import _otra_sesion

    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    credencial = (
        await client.post(
            "/v1/auth/biometric/enroll", json={"pin": PIN_DE_PRUEBA}, headers=otra
        )
    ).json()["credential"]
    lista = (await client.get("/v1/devices", headers=registrado.auth)).json()["dispositivos"]

    await client.delete(f"/v1/devices/{lista[1]['id']}", headers=registrado.auth)

    assert (await _entrar(client, registrado.dni, credencial, "telefono-2")).status_code == 401


async def test_con_el_dni_bloqueado_no_entra_ni_con_huella(client, registrado):
    credencial = (await _activar(client, registrado)).json()["credential"]
    for _ in range(settings.IDENTIFIER_MAX_ATTEMPTS):
        await client.post(
            "/v1/auth/authenticate",
            json={"identifier": registrado.dni, "pin": "111222"},
            headers={"X-Device-Id": "telefono-x"},
        )

    r = await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")
    assert r.status_code == 423


async def test_los_fallos_con_huella_no_suman_intentos(client, registrado):
    for _ in range(10):
        await _entrar(client, registrado.dni, "inventada", f"dev-{registrado.dni}")

    ok = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert ok.json()["result"] == "session"


async def test_restablecer_el_pin_revoca_la_huella(client, registrado, otp_codes):
    from tests.test_otp_y_recuperacion import abrir_reto, verificar

    credencial = (await _activar(client, registrado)).json()["credential"]

    reto = await abrir_reto(client, identifier=f"{registrado.dni}@correo.pe")
    ticket = (
        await verificar(client, reto["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]
    r = await client.post(
        "/v1/auth/pin/reset", json={"otp_ticket": ticket, "new_pin": "314159"}
    )
    assert r.status_code == 200

    # Restablecer el PIN no otorga acceso: tampoco con la huella de antes.
    assert (
        await _entrar(client, registrado.dni, credencial, f"dev-{registrado.dni}")
    ).status_code == 401
