"""
Abrir otra cuenta desde la app y ponerle nombre.

Abrir cuenta pide PIN e idempotencia como mover dinero: un doble toque o un
reintento tras perder la respuesta no debe dejar al titular con dos cuentas.
"""

import asyncio

import pytest

from tests.conftest import PIN_DE_PRUEBA, registrar

PIN = PIN_DE_PRUEBA


def _abrir(tipo="ahorro", moneda="PEN", nombre=None, clave="abrir-0001", pin=PIN):
    return {
        "tipo": tipo,
        "moneda": moneda,
        "nombre": nombre,
        "pin": pin,
        "idempotency_key": clave,
    }


async def _cuentas(client, titular):
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"]


@pytest.mark.asyncio
async def test_abrir_una_cuenta_en_dolares_con_nombre(client, registrado):
    r = await client.post(
        "/v1/accounts", json=_abrir("corriente", "USD", "  Viaje  "), headers=registrado.auth
    )
    assert r.status_code == 201, r.text
    c = r.json()
    assert (c["tipo"], c["moneda"], c["nombre"], c["estado"]) == (
        "corriente", "USD", "Viaje", "activa"
    )
    assert c["saldo_disponible"] == 0
    assert len(await _cuentas(client, registrado)) == 2


@pytest.mark.asyncio
async def test_get_accounts_trae_el_nombre(client, registrado):
    cuentas = await _cuentas(client, registrado)
    assert cuentas[0]["nombre"] is None


@pytest.mark.asyncio
async def test_reintentar_con_la_misma_clave_devuelve_la_misma_cuenta(client, registrado):
    a = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    assert (a.status_code, b.status_code) == (201, 200)
    assert a.json()["id"] == b.json()["id"]
    assert len(await _cuentas(client, registrado)) == 2


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_tipo_es_409(client, registrado):
    await client.post("/v1/accounts", json=_abrir("ahorro"), headers=registrado.auth)
    r = await client.post("/v1/accounts", json=_abrir("corriente"), headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_la_misma_clave_en_otro_titular_abre_su_propia_cuenta(
    client, registrado, otro_registrado
):
    a = await client.post("/v1/accounts", json=_abrir(), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir(), headers=otro_registrado.auth)
    assert (a.status_code, b.status_code) == (201, 201)
    assert a.json()["id"] != b.json()["id"]


@pytest.mark.asyncio
async def test_el_tope_es_de_cinco_cuentas(client, registrado):
    for i in range(4):  # ya tiene 1 por el registro
        r = await client.post(
            "/v1/accounts", json=_abrir(clave=f"abrir-tope-{i}"), headers=registrado.auth
        )
        assert r.status_code == 201
    r = await client.post("/v1/accounts", json=_abrir(clave="abrir-tope-x"), headers=registrado.auth)
    assert r.status_code == 409
    assert r.json()["code"] == "ACCOUNT_LIMIT_REACHED"


@pytest.mark.asyncio
async def test_solo_una_cuenta_sueldo(client, registrado):
    a = await client.post("/v1/accounts", json=_abrir("sueldo", clave="s-0000001"), headers=registrado.auth)
    b = await client.post("/v1/accounts", json=_abrir("sueldo", clave="s-0000002"), headers=registrado.auth)
    assert a.status_code == 201
    assert b.status_code == 409
    assert b.json()["code"] == "SALARY_ACCOUNT_EXISTS"


@pytest.mark.asyncio
async def test_sueldo_en_dolares_se_rechaza(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir("sueldo", "USD"), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "INVALID_ACCOUNT_CURRENCY"


@pytest.mark.asyncio
@pytest.mark.parametrize("nombre", ["x" * 31, "a\nb"])
async def test_un_nombre_invalido_se_rechaza(client, registrado, nombre):
    r = await client.post("/v1/accounts", json=_abrir(nombre=nombre), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "INVALID_ACCOUNT_NAME"


@pytest.mark.asyncio
async def test_un_tipo_o_moneda_desconocidos_son_422(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir("cts"), headers=registrado.auth)
    assert r.status_code == 422
    r = await client.post("/v1/accounts", json=_abrir(moneda="EUR"), headers=registrado.auth)
    assert r.status_code == 422


@pytest.mark.asyncio
async def test_pin_errado_no_abre_y_descuenta_intentos(client, registrado):
    r = await client.post("/v1/accounts", json=_abrir(pin="000000"), headers=registrado.auth)
    assert r.status_code == 403
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert "intentos_restantes" in r.json()
    assert len(await _cuentas(client, registrado)) == 1


@pytest.mark.asyncio
async def test_abrir_exige_sesion(client):
    assert (await client.post("/v1/accounts", json=_abrir())).status_code == 401


@pytest.mark.asyncio
async def test_renombrar_una_cuenta_propia(client, registrado):
    cid = (await _cuentas(client, registrado))[0]["id"]
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": " Casa "}, headers=registrado.auth
    )
    assert r.status_code == 200
    assert r.json()["nombre"] == "Casa"
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": "   "}, headers=registrado.auth
    )
    assert r.json()["nombre"] is None


@pytest.mark.asyncio
async def test_renombrar_una_cuenta_ajena_es_404(client, registrado, otro_registrado):
    cid = (await _cuentas(client, otro_registrado))[0]["id"]
    r = await client.patch(
        f"/v1/accounts/{cid}/nombre", json={"nombre": "Mía"}, headers=registrado.auth
    )
    assert r.status_code == 404
    assert r.json()["code"] == "ACCOUNT_NOT_FOUND"


@pytest.mark.asyncio
async def test_dos_aperturas_de_sueldo_a_la_vez_dejan_una(client, registrado):
    """En SQLite las peticiones se serializan; la garantía real la da el índice
    parcial y se prueba contra Postgres en `test_concurrencia_multicuenta.py`."""
    respuestas = await asyncio.gather(
        *[
            client.post(
                "/v1/accounts", json=_abrir("sueldo", clave=f"sueldo-par-{i}"), headers=registrado.auth
            )
            for i in range(2)
        ]
    )
    assert sorted(r.status_code for r in respuestas) == [201, 409]
