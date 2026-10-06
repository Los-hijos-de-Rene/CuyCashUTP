"""Ver y desvincular los teléfonos con acceso a la cuenta."""

from sqlalchemy import select

from app.db.models import BiometricCredential, Device
from tests.conftest import PIN_DE_PRUEBA
from tests.test_cambio_de_pin import _otra_sesion


async def _lista(client, auth):
    return (await client.get("/v1/devices", headers=auth)).json()["dispositivos"]


async def test_lista_marca_este_telefono_primero(client, registrado, otp_codes):
    await _otra_sesion(client, otp_codes, registrado.dni)

    lista = await _lista(client, registrado.auth)

    assert len(lista) == 2
    assert lista[0]["es_este"] is True
    assert lista[1]["es_este"] is False
    assert lista[0]["vinculado_el"].endswith("Z")
    assert set(lista[0]) == {
        "id", "nombre", "plataforma", "vinculado_el", "ultimo_uso", "es_este", "con_huella"
    }


async def test_con_huella_refleja_la_credencial_vigente(client, registrado, db_de_client):
    db_de_client.add(
        BiometricCredential(
            user_id=registrado.user_id,
            device_id=f"dev-{registrado.dni}",
            secret_hash="c" * 64,
        )
    )
    await db_de_client.commit()

    assert (await _lista(client, registrado.auth))[0]["con_huella"] is True


async def test_desvincular_otro_lo_saca_y_pide_otp_otra_vez(
    client, registrado, otp_codes, db_de_client
):
    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    otro_id = (await _lista(client, registrado.auth))[1]["id"]

    r = await client.delete(f"/v1/devices/{otro_id}", headers=registrado.auth)

    assert r.status_code == 204
    assert (await client.get("/v1/me", headers=otra)).status_code == 401
    assert len(await _lista(client, registrado.auth)) == 1
    vuelve = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "telefono-2"},
    )
    assert vuelve.json()["result"] == "device_verification_required"


async def test_desvincular_este_telefono_es_409(client, registrado):
    este = (await _lista(client, registrado.auth))[0]["id"]
    r = await client.delete(f"/v1/devices/{este}", headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "CANNOT_UNLINK_CURRENT"


async def test_desvincular_uno_ajeno_o_inexistente_es_404(
    client, registrado, otro_registrado
):
    ajeno = (await _lista(client, otro_registrado.auth))[0]["id"]
    for objetivo in [ajeno, "no-existe"]:
        r = await client.delete(f"/v1/devices/{objetivo}", headers=registrado.auth)
        assert r.status_code == 404
        assert r.json()["code"] == "DEVICE_NOT_FOUND"


async def test_desvincular_revoca_su_huella(client, registrado, otp_codes, db_de_client):
    await _otra_sesion(client, otp_codes, registrado.dni)
    db_de_client.add(
        BiometricCredential(
            user_id=registrado.user_id, device_id="telefono-2", secret_hash="d" * 64
        )
    )
    await db_de_client.commit()
    otro_id = (await _lista(client, registrado.auth))[1]["id"]

    await client.delete(f"/v1/devices/{otro_id}", headers=registrado.auth)

    fila = (await db_de_client.execute(select(BiometricCredential))).scalars().one()
    await db_de_client.refresh(fila)
    assert fila.revoked_at is not None
    assert (
        await db_de_client.execute(select(Device).where(Device.device_id == "telefono-2"))
    ).scalars().first() is None
