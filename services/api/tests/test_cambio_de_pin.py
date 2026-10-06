"""
Cambiar el PIN con la sesión abierta: exige el actual, cuenta para el bloqueo,
y cierra las sesiones y huellas de los OTROS teléfonos, no la de este.
"""

from sqlalchemy import select

from app.core.config import settings
from app.db.models import BiometricCredential
from tests.conftest import PIN_DE_PRUEBA

NUEVO = "502718"


async def _otra_sesion(client, otp_codes, dni):
    """Entra desde un segundo teléfono por el camino real (PIN + OTP)."""
    a = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "telefono-2"},
    )
    pending = a.json()["pending_token"]
    ch = await client.post(
        "/v1/otp/challenges",
        json={"purpose": "device", "identifier": dni},
        headers={"X-Device-Id": "telefono-2"},
    )
    cid = ch.json()["challenge_id"]
    v = await client.post(
        f"/v1/otp/challenges/{cid}/verify",
        json={"code": otp_codes[-1]["code"]},
        headers={"X-Device-Id": "telefono-2"},
    )
    s = await client.post(
        "/v1/auth/sessions",
        json={"pending_token": pending, "otp_ticket": v.json()["otp_ticket"]},
        headers={"X-Device-Id": "telefono-2"},
    )
    return {"Authorization": f"Bearer {s.json()['session_token']}"}


async def _cambiar(client, auth, actual=PIN_DE_PRUEBA, nuevo=NUEVO):
    return await client.post(
        "/v1/auth/pin/change",
        json={"current_pin": actual, "new_pin": nuevo},
        headers=auth,
    )


async def test_cambia_el_pin_y_este_telefono_sigue_dentro(client, registrado):
    r = await _cambiar(client, registrado.auth)

    assert r.status_code == 200
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 200
    viejo = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert viejo.status_code == 401
    nuevo = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": NUEVO},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert nuevo.json()["result"] == "session"


async def test_cierra_las_sesiones_y_huellas_de_los_otros(
    client, registrado, otp_codes, db_de_client
):
    otra = await _otra_sesion(client, otp_codes, registrado.dni)
    db_de_client.add_all(
        [
            BiometricCredential(
                user_id=registrado.user_id, device_id="telefono-2", secret_hash="a" * 64
            ),
            BiometricCredential(
                user_id=registrado.user_id,
                device_id=f"dev-{registrado.dni}",
                secret_hash="b" * 64,
            ),
        ]
    )
    await db_de_client.commit()

    r = await _cambiar(client, registrado.auth)

    assert r.json()["revoked_sessions"] == 1
    assert (await client.get("/v1/me", headers=otra)).status_code == 401
    filas = (await db_de_client.execute(select(BiometricCredential))).scalars().all()
    for fila in filas:
        await db_de_client.refresh(fila)
    estado = {f.device_id: f.revoked_at is not None for f in filas}
    assert estado == {"telefono-2": True, f"dev-{registrado.dni}": False}


async def test_pin_actual_errado_descuenta_intentos(client, registrado):
    r = await _cambiar(client, registrado.auth, actual="111222")

    assert r.status_code == 401
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert r.json()["attempts_left"] == settings.IDENTIFIER_MAX_ATTEMPTS - 1
    # Un 401 de negocio NO cierra la sesión.
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 200


async def test_al_agotar_los_intentos_bloquea_y_cierra_esta_sesion(client, registrado):
    for _ in range(settings.IDENTIFIER_MAX_ATTEMPTS - 1):
        previo = await _cambiar(client, registrado.auth, actual="111222")
        assert previo.status_code == 401
    r = await _cambiar(client, registrado.auth, actual="111222")

    assert r.status_code == 423
    assert "locked_until" in r.json()
    assert (await client.get("/v1/me", headers=registrado.auth)).status_code == 401


async def test_pin_nuevo_previsible_se_rechaza(client, registrado):
    r = await _cambiar(client, registrado.auth, nuevo="123456")
    assert r.json()["code"] == "WEAK_PIN"


async def test_pin_nuevo_igual_al_actual_se_rechaza(client, registrado):
    r = await _cambiar(client, registrado.auth, nuevo=PIN_DE_PRUEBA)
    assert r.json()["code"] == "PIN_UNCHANGED"


async def test_sin_sesion_es_401(client):
    r = await _cambiar(client, {})
    assert r.status_code == 401
