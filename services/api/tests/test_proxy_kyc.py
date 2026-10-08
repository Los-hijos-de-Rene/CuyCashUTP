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
    "ruta", ["/v1/kyc/identity/verify", "/v1/kyc/liveness/evaluate", "/v1/kyc/liveness/verify"]
)
async def test_las_demas_rutas_del_servicio_no_se_exponen(client, kyc_configurado, upstream, ruta):
    recibido, _ = upstream
    r = await client.post(ruta)
    assert r.status_code in (404, 405)
    assert recibido == {}


@pytest.mark.parametrize(
    "ruta, destino",
    [
        ("/v1/kyc/document/validate", "http://kyc.test/api/v1/document/validate"),
        ("/v1/kyc/document/mrz", "http://kyc.test/api/v1/document/mrz"),
    ],
)
async def test_el_paso_del_documento_se_reenvia(client, kyc_configurado, upstream, ruta, destino):
    """Validar el DNI al fotografiarlo, no recién al final del registro."""
    recibido, respuesta = upstream
    respuesta.update(json={"is_valid": True})
    r = await client.post(ruta)
    assert r.status_code == 200
    assert recibido["url"] == destino


@pytest.fixture
def kyc_dormido(monkeypatch, kyc_configurado):
    """
    El KYC del plan gratuito despertando: responde 502 las primeras veces.
    Devuelve cuántos 502 dar antes de responder bien, y cuántas llamadas hubo.
    """
    monkeypatch.setattr(settings, "KYC_RETRY_DELAY_SECONDS", 0)
    monkeypatch.setattr(settings, "KYC_WAKE_TIMEOUT_SECONDS", 1)
    estado = {"502": 2, "llamadas": 0, "cuerpos": []}

    async def manejar(request: httpx.Request) -> httpx.Response:
        estado["llamadas"] += 1
        estado["cuerpos"].append(request.content)
        if estado["502"] > 0:
            estado["502"] -= 1
            return httpx.Response(502, text="Bad Gateway")
        return httpx.Response(200, json={"token": "t", "steps": ["izquierda"], "expires_in": 180})

    real = httpx.AsyncClient

    def falso(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(manejar)
        return real(*args, **kwargs)

    monkeypatch.setattr(httpx, "AsyncClient", falso)
    return estado


async def test_si_el_kyc_esta_despertando_se_reintenta(client, kyc_dormido):
    r = await client.post("/v1/kyc/liveness/challenge")

    assert r.status_code == 200
    assert r.json()["token"] == "t"
    assert kyc_dormido["llamadas"] == 3


async def test_el_reintento_reenvia_el_mismo_cuerpo(client, kyc_dormido):
    await client.post("/v1/kyc/document/mrz", content=b"cuerpo-de-prueba")

    assert kyc_dormido["cuerpos"] == [b"cuerpo-de-prueba"] * 3


async def test_si_no_despierta_a_tiempo_responde_503(client, kyc_dormido, monkeypatch):
    kyc_dormido["502"] = 10_000
    monkeypatch.setattr(settings, "KYC_WAKE_TIMEOUT_SECONDS", 0)

    r = await client.post("/v1/kyc/liveness/challenge")

    assert r.status_code == 503
    assert r.json()["code"] == "SERVICE_UNAVAILABLE"
