"""
APF2 · criterio 2.3: pruebas de seguridad web (SQLi, XSS, CORS y cabeceras).

Cada prueba ataca la API por HTTP, como lo haría alguien desde fuera, y
comprueba dos cosas: que el ataque no tiene efecto y que la respuesta es un
error controlado (4xx con `code`), nunca un 500 que filtre detalles internos.
"""

import pytest

from tests.conftest import PIN_DE_PRUEBA

# Cargas clásicas de inyección SQL.
SQLI = [
    "' OR '1'='1",
    "1' OR 1=1 --",
    "'; DROP TABLE users; --",
    "\" OR \"\"=\"",
    "1; SELECT pg_sleep(5)",
]

XSS = "<script>alert(1)</script>"


async def _cuenta_id(client, titular) -> str:
    r = await client.get("/v1/accounts", headers=titular.auth)
    return r.json()["cuentas"][0]["id"]


# --------------------------------------------------------------- inyección SQL


@pytest.mark.parametrize("carga", SQLI)
async def test_sqli_en_el_login_no_abre_sesion(client, registrado, carga):
    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": carga, "pin": carga},
        headers={"X-Device-Id": "dev-atacante"},
    )
    assert r.status_code in (401, 422), r.text
    assert "session_token" not in r.text


@pytest.mark.parametrize("carga", SQLI)
async def test_sqli_en_la_busqueda_de_destinatario_se_rechaza(client, registrado, carga):
    for params in ({"dni": carga}, {"alias": carga}):
        r = await client.get("/v1/directory/resolve", params=params, headers=registrado.auth)
        assert r.status_code in (404, 422), (params, r.text)
        assert "nombre_enmascarado" not in r.text


@pytest.mark.parametrize("carga", SQLI)
async def test_sqli_en_ids_de_la_ruta_responde_404(client, registrado, carga):
    for ruta in (f"/v1/movements/{carga}", f"/v1/accounts/{carga}/movements"):
        r = await client.get(ruta, headers=registrado.auth)
        assert r.status_code == 404, (ruta, r.text)


@pytest.mark.parametrize("carga", SQLI)
async def test_sqli_en_el_cursor_cae_a_la_primera_pagina(client, registrado, carga):
    r = await client.get("/v1/movements", params={"cursor": carga}, headers=registrado.auth)
    assert r.status_code == 200
    assert r.json()["movimientos"] == []


async def test_sqli_guardado_como_dato_se_queda_como_dato(client, registrado):
    """El nombre de una cuenta viaja a la base como parámetro, no como SQL:
    se guarda literal y la tabla de usuarios sigue ahí."""
    cuenta = await _cuenta_id(client, registrado)
    carga = "'); DROP TABLE users;--"
    r = await client.patch(
        f"/v1/accounts/{cuenta}/nombre", json={"nombre": carga}, headers=registrado.auth
    )
    assert r.status_code == 200
    assert r.json()["nombre"] == carga

    me = await client.get("/v1/me", headers=registrado.auth)
    assert me.status_code == 200
    cuentas = (await client.get("/v1/accounts", headers=registrado.auth)).json()["cuentas"]
    assert cuentas[0]["nombre"] == carga


# ---------------------------------------------------------------------- XSS


async def test_xss_en_el_alias_se_rechaza_por_formato(client, registrado):
    r = await client.patch("/v1/me/alias", json={"alias": XSS}, headers=registrado.auth)
    assert r.status_code == 422
    assert r.json()["code"] == "INVALID_ALIAS"


async def test_xss_guardado_sale_como_json_y_nunca_como_html(client, registrado):
    """Un texto libre con HTML se devuelve como DATO dentro de JSON, con
    `nosniff`: ningún navegador lo interpreta como página ni ejecuta el script."""
    cuenta = await _cuenta_id(client, registrado)
    r = await client.patch(
        f"/v1/accounts/{cuenta}/nombre", json={"nombre": XSS}, headers=registrado.auth
    )
    assert r.status_code == 200

    r = await client.get("/v1/accounts", headers=registrado.auth)
    assert r.headers["content-type"].startswith("application/json")
    assert r.headers["x-content-type-options"] == "nosniff"
    assert r.json()["cuentas"][0]["nombre"] == XSS


async def test_xss_en_el_apodo_de_un_frecuente_sale_como_json(
    client, registrado, otro_registrado
):
    destino = await _cuenta_id(client, otro_registrado)
    r = await client.post(
        "/v1/beneficiaries",
        json={"cuenta_destino_id": destino, "apodo": XSS},
        headers=registrado.auth,
    )
    assert r.status_code == 201
    r = await client.get("/v1/beneficiaries", headers=registrado.auth)
    assert r.headers["content-type"].startswith("application/json")
    assert r.json()["beneficiarios"][0]["apodo"] == XSS


# --------------------------------------------------------------------- CORS


async def test_cors_un_origen_ajeno_no_recibe_permiso(client, registrado):
    """Sin Access-Control-Allow-Origin, el navegador bloquea que otra web lea
    las respuestas, aunque la víctima tenga sesión."""
    preflight = await client.options(
        "/v1/accounts",
        headers={
            "Origin": "https://atacante.example",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "authorization",
        },
    )
    assert "access-control-allow-origin" not in preflight.headers

    r = await client.get(
        "/v1/accounts",
        headers={**registrado.auth, "Origin": "https://atacante.example"},
    )
    assert "access-control-allow-origin" not in r.headers
    assert "access-control-allow-credentials" not in r.headers


# --------------------------------------------------------------- cabeceras


async def test_cabeceras_de_seguridad_en_toda_respuesta(client, registrado):
    for ruta, auth in (("/health", {}), ("/v1/me", registrado.auth), ("/v1/me", {})):
        r = await client.get(ruta, headers=auth)
        assert r.headers["strict-transport-security"].startswith("max-age=")
        assert r.headers["x-content-type-options"] == "nosniff"
        assert r.headers["x-frame-options"] == "DENY"
        assert r.headers["referrer-policy"] == "no-referrer"


async def test_los_datos_de_la_api_no_se_cachean(client, registrado):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    assert r.headers["cache-control"] == "no-store"


async def test_un_error_no_filtra_detalles_internos(client, registrado):
    r = await client.get("/v1/movements/no-existe", headers=registrado.auth)
    cuerpo = r.text.lower()
    for fuga in ("traceback", "sqlalchemy", "select ", "postgresql", "sqlite"):
        assert fuga not in cuerpo


# ----------------------------------------------------------------- monitoreo


async def test_health_db_mide_la_base(client):
    r = await client.get("/health/db")
    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["status"] == "ok"
    assert cuerpo["latency_ms"] >= 0
    assert "://" not in r.text  # nunca la cadena de conexión


async def test_health_dice_que_version_corre(client, monkeypatch):
    assert (await client.get("/health")).json() == {"status": "ok", "version": "local"}
    monkeypatch.setenv("RENDER_GIT_COMMIT", "abc1234")
    assert (await client.get("/health")).json()["version"] == "abc1234"


# ------------------------------------------------- entradas más largas que la columna
#
# SQLite ignora el largo de VARCHAR; Postgres lo hace cumplir. Un valor más
# largo que la columna llegaba a la base y daba 500 (lo encontró el CI al correr
# la suite contra Postgres). Ahora se rechaza en la entrada con 422.


async def test_un_dni_largo_en_el_login_es_422_y_no_500(client, registrado):
    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": "1" * 50, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "dev-1"},
    )
    assert r.status_code == 422


async def test_un_device_id_larguisimo_es_422_y_no_500(client, registrado):
    r = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_DE_PRUEBA},
        headers={"X-Device-Id": "d" * 500},
    )
    assert r.status_code == 422


async def test_un_identificador_de_otp_larguisimo_es_422_y_no_500(client):
    r = await client.post(
        "/v1/otp/challenges", json={"purpose": "recovery", "identifier": "a" * 1000}
    )
    assert r.status_code == 422
