"""
El nombre del titular: se guarda en minúsculas y viaja en TODA respuesta que
abre sesión, no solo en el alta.

Antes solo el registro devolvía `full_name`. Tras cerrar sesión el teléfono
olvida al usuario, y el login no tenía de dónde sacar el nombre: el inicio
saludaba con el DNI.
"""

from sqlalchemy import select

from app.db.models import User
from tests.conftest import PIN_DE_PRUEBA
from tests.test_otp_y_recuperacion import abrir_reto, verificar
from tests.test_registro_y_login import DEVICE, DNI, autenticar, registrar


async def test_el_alta_guarda_el_nombre_en_minusculas_y_sin_espacios_de_mas(
    client, db_de_client
):
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": "70000077",
            "nombres": "  JAIR   Alberto ",
            "apellidos": "CONISLLA  Pérez",
            "email": "jair@correo.pe",
            "pin": PIN_DE_PRUEBA,
        },
        headers={"X-Device-Id": "telefono-de-jair"},
    )
    assert r.status_code == 201, r.text
    assert r.json()["full_name"] == "jair alberto conislla pérez"
    assert r.json()["alias"] == "@jair"

    user = (
        await db_de_client.execute(select(User).where(User.dni == "70000077"))
    ).scalar_one()
    assert (user.nombres, user.apellidos) == ("jair alberto", "conislla pérez")


async def test_entrar_desde_un_telefono_vinculado_trae_el_nombre(client):
    await registrar(client, device=DEVICE)

    r = await autenticar(client)

    assert r.json()["result"] == "session", r.text
    assert r.json()["user"]["full_name"] == "juan carlos pérez"


async def test_entrar_verificando_el_dispositivo_trae_el_nombre(
    client, otp_codes
):
    await registrar(client)
    pendiente = (await autenticar(client)).json()["pending_token"]
    reto = await abrir_reto(client, purpose="device", identifier=DNI)
    ticket = (
        await verificar(client, reto["challenge_id"], otp_codes[-1]["code"])
    ).json()["otp_ticket"]

    r = await client.post(
        "/v1/auth/sessions",
        json={"pending_token": pendiente, "otp_ticket": ticket},
        headers={"X-Device-Id": DEVICE},
    )

    assert r.status_code == 200, r.text
    assert r.json()["user"] == {
        "id": r.json()["user"]["id"],
        "dni": DNI,
        "alias": "@juan",
        "full_name": "juan carlos pérez",
    }


async def test_el_telefono_desconocido_no_recibe_el_nombre_antes_del_otp(client):
    """Con el PIN correcto pero sin OTP aún no se dice a quién pertenece."""
    await registrar(client)

    r = await autenticar(client)

    assert r.json()["result"] == "device_verification_required"
    assert "user" not in r.json()
    assert "pérez" not in r.text.lower()


async def test_entrar_con_huella_trae_el_nombre(client, registrado):
    credencial = (
        await client.post(
            "/v1/auth/biometric/enroll",
            json={"pin": PIN_DE_PRUEBA},
            headers=registrado.auth,
        )
    ).json()["credential"]

    r = await client.post(
        "/v1/auth/sessions/biometric",
        json={"dni": registrado.dni, "credential": credencial},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )

    assert r.status_code == 200, r.text
    assert r.json()["user"]["full_name"] == "jenny marisol ruiz"
