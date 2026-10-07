"""
El proxy del KYC: la app nunca lleva la clave, y el backend solo reenvía las
dos rutas del registro.
"""

import httpx
import pytest

from app.core.config import settings


@pytest.fixture
def kyc_configurado(monkeypatch):
    monkeypatch.setattr(settings, "KYC_BASE_URL", "http://kyc.test")
    monkeypatch.setattr(settings, "KYC_API_KEY", "clave-del-servidor")


@pytest.fixture
def upstream(monkeypatch):
    """Sustituye al servicio de KYC: guarda lo que recibió y responde lo pedido."""
    recibido = {}
    respuesta = {"status": 200, "json": {"token": "t", "steps": ["izquierda"], "expires_in": 180}}

    async def manejar(request: httpx.Request) -> httpx.Response:
        recibido["url"] = str(request.url)
        recibido["api_key"] = request.headers.get("X-API-Key")
        return httpx.Response(respuesta["status"], json=respuesta["json"])

    cliente_real = httpx.AsyncClient

    def cliente_falso(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(manejar)
        return cliente_real(*args, **kwargs)

    monkeypatch.setattr(httpx, "AsyncClient", cliente_falso)
    return recibido, respuesta


async def test_sin_configurar_responde_503(client, monkeypatch):
    monkeypatch.setattr(settings, "KYC_BASE_URL", None)
    r = await client.post("/v1/kyc/liveness/challenge")
    assert r.status_code == 503
    assert r.json()["code"] == "SERVICE_UNAVAILABLE"


async def test_reenvia_el_desafio_con_la_clave_del_servidor(client, kyc_configurado, upstream):
    recibido, _ = upstream
    r = await client.post("/v1/kyc/liveness/challenge")
    assert r.status_code == 200
    assert r.json()["token"] == "t"
    assert recibido["url"] == "http://kyc.test/api/v1/liveness/challenge"
    assert recibido["api_key"] == "clave-del-servidor"


async def test_los_4xx_de_negocio_llegan_tal_cual(client, kyc_configurado, upstream):
    _, respuesta = upstream
    respuesta.update(status=400, json={"detail": "Token de desafío inválido o expirado."})
    r = await client.post("/v1/kyc/identity/verify-full", data={"liveness_frames": "{}"})
    assert r.status_code == 400
    assert "expirado" in r.json()["detail"]


async def test_clave_rechazada_por_el_kyc_es_503_no_401(client, kyc_configurado, upstream):
    _, respuesta = upstream
    respuesta.update(status=401, json={"detail": "API Key inválida o ausente"})
    r = await client.post("/v1/kyc/liveness/challenge")
    assert r.status_code == 503


@pytest.mark.parametrize(
    "ruta", ["/v1/kyc/identity/verify", "/v1/kyc/document/validate", "/v1/kyc/liveness/evaluate"]
)
async def test_las_demas_rutas_del_servicio_no_se_exponen(client, kyc_configurado, upstream, ruta):
    recibido, _ = upstream
    r = await client.post(ruta)
    assert r.status_code in (404, 405)
    assert recibido == {}
