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
@pytest.fixture
def kyc_controlado(monkeypatch, kyc_configurado):
    """
    Simula el microservicio KYC mediante MockTransport.
    Permite controlar errores y contar solicitudes.
    """
    estado = {
        "modo": "correcto",
        "llamadas": 0,
    }

    async def manejar(request: httpx.Request):
        estado["llamadas"] += 1

        if estado["modo"] == "read_timeout":
            raise httpx.ReadTimeout(
                "Tiempo de lectura agotado",
                request=request,
            )

        if estado["modo"] == "json_invalido":
            return httpx.Response(
                200,
                content=b'{"token":',
                headers={"content-type": "application/json"},
            )

        return httpx.Response(
            200,
            json={
                "token": "token-de-prueba",
                "steps": ["izquierda", "derecha"],
                "expires_in": 180,
            },
        )

    cliente_original = httpx.AsyncClient

    def cliente_simulado(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(manejar)
        return cliente_original(*args, **kwargs)

    monkeypatch.setattr(
        httpx,
        "AsyncClient",
        cliente_simulado,
    )

    return estado


async def test_int_k1_read_timeout_no_reintenta(
    client,
    kyc_controlado,
):
    """
    INT-K1: ReadTimeout no debe provocar otro intento.

    La solicitud pudo haber sido procesada por KYC;
    repetirla podria consumir dos veces el desafio.
    """
    kyc_controlado["modo"] = "read_timeout"

    respuesta = await client.post(
        "/v1/kyc/liveness/challenge"
    )

    assert respuesta.status_code == 503
    assert respuesta.json()["code"] == "SERVICE_UNAVAILABLE"
    assert kyc_controlado["llamadas"] == 1


async def test_int_k3_json_invalido_error_controlado(
    client,
    kyc_controlado,
):
    """
    INT-K3: el proxy no debe devolver HTTP 200
    cuando KYC responde un JSON malformado.
    """
    kyc_controlado["modo"] = "json_invalido"

    respuesta = await client.post(
        "/v1/kyc/liveness/challenge"
    )

    assert respuesta.status_code in (502, 503)
    assert kyc_controlado["llamadas"] == 1
    assert "Traceback" not in respuesta.text


async def test_int_k4_contrato_challenge(
    client,
    kyc_controlado,
):
    """
    INT-K4: el challenge debe mantener los campos
    token, steps y expires_in.
    """
    respuesta = await client.post(
        "/v1/kyc/liveness/challenge"
    )

    assert respuesta.status_code == 200
    assert kyc_controlado["llamadas"] == 1

    datos = respuesta.json()

    assert isinstance(datos["token"], str)
    assert datos["token"]

    assert isinstance(datos["steps"], list)
    assert len(datos["steps"]) > 0

    assert isinstance(datos["expires_in"], int)
    assert datos["expires_in"] > 0

@pytest.mark.parametrize(
    "aprobado,documento_valido,dni_coincide,device_id,espera_ticket",
    [
        (True, True, True, "dispositivo-01", True),
        (False, True, True, "dispositivo-01", False),
        (True, False, True, "dispositivo-01", False),
        (True, True, False, "dispositivo-01", False),
        (True, True, True, "", False),
    ],
)
async def test_int_k2_ticket_solo_con_aprobacion(
    client,
    kyc_configurado,
    upstream,
    aprobado,
    documento_valido,
    dni_coincide,
    device_id,
    espera_ticket,
):
    """
    INT-K2: emitir el ticket solo con aprobacion
    completa, DNI valido y dispositivo identificado.
    """

    _, respuesta = upstream

    respuesta["json"] = {
        "overall_result": aprobado,
        "document_data": {
            "dni": "12345678",
            "valid": documento_valido,
            "matches_expected": dni_coincide,
        },
        "document_validation": {
            "is_valid": documento_valido,
        },
        "liveness": {
            "is_live": True,
        },
        "face_match": {
            "is_match": True,
            "distance": 0.1,
        },
    }

    headers = {}

    if device_id:
        headers["X-Device-Id"] = device_id

    resultado = await client.post(
        "/v1/kyc/identity/verify-full",
        headers=headers,
        json={},
    )

    assert resultado.status_code == 200

    datos = resultado.json()

    if espera_ticket:
        assert isinstance(datos.get("kyc_ticket"), str)
        assert datos["kyc_ticket"]
    else:
        assert "kyc_ticket" not in datos


async def test_warmup_responde_202_y_toca_el_health_del_kyc(client, kyc_configurado, upstream, monkeypatch):
    from app.api.v1.routers import kyc

    monkeypatch.setattr(kyc, "_ultimo_calentamiento", float("-inf"))
    recibido, _ = upstream
    r = await client.post("/v1/kyc/warmup")
    assert r.status_code == 202
    assert recibido["url"] == "http://kyc.test/health"


async def test_warmup_no_repite_dentro_del_intervalo(client, kyc_configurado, upstream, monkeypatch):
    from app.api.v1.routers import kyc

    monkeypatch.setattr(kyc, "_ultimo_calentamiento", float("-inf"))
    recibido, _ = upstream
    await client.post("/v1/kyc/warmup")
    recibido.clear()
    r = await client.post("/v1/kyc/warmup")
    assert r.status_code == 202
    assert recibido == {}


async def test_warmup_sin_kyc_configurado_no_falla(client, monkeypatch):
    monkeypatch.setattr(settings, "KYC_BASE_URL", None)
    r = await client.post("/v1/kyc/warmup")
    assert r.status_code == 202
