"""
El alta exige un KYC aprobado POR EL SERVIDOR.

Antes, el veredicto del KYC llegaba a la app y era la app la que decidía
seguir: cualquiera podía llamar a `/register` directo, con cualquier DNI, sin
pasar por la cámara. Ahora el proxy de `verify-full` emite un ticket de un
solo uso, atado al DNI LEÍDO del documento y al teléfono, y `/register` lo
exige y lo consume.
"""

from datetime import timedelta

import httpx
import pytest
from sqlalchemy import select

from app.core.config import settings
from app.db.models import KycTicket, KycVerification, User, utcnow

DNI = "12345678"
DEVICE = "device-del-alta"

APROBADO = {
    "overall_result": True,
    "overall_reason": "Verificación de identidad exitosa",
    "document_validation": {"is_valid": True},
    "liveness": {"is_live": True},
    "face_match": {"is_match": True, "distance": 0.41},
    "document_data": {"found": True, "valid": True, "dni": DNI, "matches_expected": True},
}


@pytest.fixture
def kyc_obligatorio(monkeypatch):
    monkeypatch.setattr(settings, "KYC_REQUIRED", True)


@pytest.fixture
def kyc_responde(monkeypatch):
    """El servicio de KYC devuelve lo que diga la prueba."""
    monkeypatch.setattr(settings, "KYC_BASE_URL", "http://kyc.test")
    monkeypatch.setattr(settings, "KYC_API_KEY", "clave")
    respuesta = {"json": dict(APROBADO)}

    async def manejar(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=respuesta["json"])

    real = httpx.AsyncClient

    def falso(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(manejar)
        return real(*args, **kwargs)

    monkeypatch.setattr(httpx, "AsyncClient", falso)
    return respuesta


async def verificar(client, device=DEVICE):
    return await client.post(
        "/v1/kyc/identity/verify-full",
        data={"liveness_frames": "{}"},
        headers={"X-Device-Id": device},
    )


async def registrar(client, ticket=None, dni=DNI, device=DEVICE):
    cuerpo = {
        "dni": dni,
        "nombres": "Juan Carlos",
        "apellidos": "Pérez",
        "email": "juan@correo.com",
        "pin": "024689",
    }
    if ticket is not None:
        cuerpo["kyc_ticket"] = ticket
    return await client.post(
        "/v1/auth/register", json=cuerpo, headers={"X-Device-Id": device}
    )


async def test_sin_ticket_no_hay_alta(client, kyc_obligatorio):
    r = await registrar(client)

    assert r.status_code == 403
    assert r.json()["code"] == "KYC_REQUIRED"


async def test_la_aprobacion_trae_un_ticket(client, kyc_responde):
    r = await verificar(client)

    assert r.status_code == 200
    assert r.json()["overall_result"] is True
    assert r.json()["kyc_ticket"]


@pytest.mark.parametrize(
    "cambio",
    [
        {"overall_result": False},
        {"document_data": None},
        {"document_data": {"valid": True, "dni": DNI, "matches_expected": False}},
        {"document_data": {"valid": False, "dni": DNI, "matches_expected": None}},
    ],
    ids=["rechazado", "sin-reverso", "dni-ajeno", "reverso-ilegible"],
)
async def test_sin_aprobacion_completa_no_hay_ticket(client, kyc_responde, cambio):
    kyc_responde["json"] = {**APROBADO, **cambio}

    r = await verificar(client)

    assert r.status_code == 200
    assert "kyc_ticket" not in r.json()


async def test_con_ticket_el_alta_queda_verificada(client, db_de_client, kyc_obligatorio, kyc_responde):
    ticket = (await verificar(client)).json()["kyc_ticket"]

    r = await registrar(client, ticket)

    assert r.status_code == 201
    user = (await db_de_client.execute(select(User).where(User.dni == DNI))).scalar_one()
    assert user.kyc_status == "verified"
    registro = (await db_de_client.execute(select(KycVerification))).scalar_one()
    assert registro.user_id == user.id
    assert registro.verdict == "approved"
    assert registro.face_distance == pytest.approx(0.41)
    usado = (await db_de_client.execute(select(KycTicket))).scalar_one()
    assert usado.used_at is not None


async def test_el_ticket_es_del_dni_del_documento(client, kyc_obligatorio, kyc_responde):
    ticket = (await verificar(client)).json()["kyc_ticket"]

    r = await registrar(client, ticket, dni="87654321")

    assert r.status_code == 403
    assert r.json()["code"] == "KYC_INVALID"


async def test_el_ticket_es_del_telefono_que_se_verifico(client, kyc_obligatorio, kyc_responde):
    ticket = (await verificar(client, device="otro-telefono")).json()["kyc_ticket"]

    r = await registrar(client, ticket)

    assert r.json()["code"] == "KYC_INVALID"


async def test_el_ticket_vence(client, db_de_client, kyc_obligatorio, kyc_responde):
    ticket = (await verificar(client)).json()["kyc_ticket"]
    fila = (await db_de_client.execute(select(KycTicket))).scalar_one()
    fila.expires_at = utcnow() - timedelta(seconds=1)
    await db_de_client.commit()

    r = await registrar(client, ticket)

    assert r.json()["code"] == "KYC_INVALID"


async def test_un_ticket_inventado_se_rechaza_aunque_no_sea_obligatorio(client):
    # Apagado el requisito, un ticket que SÍ llega igual se valida: si no,
    # mandar uno falso marcaría la cuenta como verificada.
    r = await registrar(client, "inventado")

    assert r.json()["code"] == "KYC_INVALID"


async def test_sin_requisito_y_sin_ticket_el_alta_sigue_pendiente(client, db_de_client):
    # Producción hoy: el KYC no está desplegado y la app lo simula.
    r = await registrar(client)

    assert r.status_code == 201
    user = (await db_de_client.execute(select(User).where(User.dni == DNI))).scalar_one()
    assert user.kyc_status == "pending"
