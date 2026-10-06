"""
El envío apunta a una CUENTA, no a una persona: con varias cuentas por DNI, el
dinero debe llegar a la que el usuario eligió, y nunca cruzar monedas.
"""

import pytest
from sqlalchemy import update

from app.db.models import Account
from app.services import accounts as accounts_service
from tests.conftest import PIN_DE_PRUEBA

PIN = PIN_DE_PRUEBA
INEXISTENTE_ID = "00000000-0000-0000-0000-000000000000"


async def _cuentas(client, t):
    return (await client.get("/v1/accounts", headers=t.auth)).json()["cuentas"]


async def _abrir(client, t, tipo, moneda, clave):
    r = await client.post(
        "/v1/accounts",
        json={"tipo": tipo, "moneda": moneda, "pin": PIN, "idempotency_key": clave},
        headers=t.auth,
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _recargar(client, t, cuenta_id, centimos, clave):
    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta_id, "monto_centimos": centimos, "pin": PIN,
              "idempotency_key": clave},
        headers=t.auth,
    )
    assert r.status_code == 201, r.text


def _envio(origen, destino, monto=1_000, clave="envio-cta-0001"):
    return {
        "cuenta_origen_id": origen,
        "cuenta_destino_id": destino,
        "monto_centimos": monto,
        "pin": PIN,
        "idempotency_key": clave,
    }


def _saldo(cuentas, cid):
    return next(c["saldo_disponible"] for c in cuentas if c["id"] == cid)


@pytest.mark.asyncio
async def test_el_dinero_llega_a_la_cuenta_elegida_y_no_a_la_primera(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 10_000, "rec-env-01")
    primera = (await _cuentas(client, otro_registrado))[0]["id"]
    segunda = await _abrir(client, otro_registrado, "corriente", "PEN", "ab-env-01")

    r = await client.post("/v1/transfers", json=_envio(origen, segunda), headers=registrado.auth)
    assert r.status_code == 201, r.text

    cuentas = await _cuentas(client, otro_registrado)
    assert _saldo(cuentas, segunda) == 1_000
    assert _saldo(cuentas, primera) == 0


@pytest.mark.asyncio
async def test_entre_cuentas_propias_se_puede(client, registrado):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-02")
    otra = await _abrir(client, registrado, "corriente", "PEN", "ab-env-02")

    r = await client.post("/v1/transfers", json=_envio(origen, otra), headers=registrado.auth)
    assert r.status_code == 201
    cuentas = await _cuentas(client, registrado)
    assert (_saldo(cuentas, origen), _saldo(cuentas, otra)) == (4_000, 1_000)


@pytest.mark.asyncio
async def test_a_la_misma_cuenta_es_same_account(client, registrado):
    origen = (await _cuentas(client, registrado))[0]["id"]
    r = await client.post("/v1/transfers", json=_envio(origen, origen), headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "SAME_ACCOUNT"


@pytest.mark.asyncio
async def test_entre_monedas_distintas_es_currency_mismatch_y_no_gasta_pin(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-03")
    usd = await _abrir(client, otro_registrado, "ahorro", "USD", "ab-env-03")

    cuerpo = _envio(origen, usd)
    cuerpo["pin"] = "000000"  # errado: si se verificara, descontaría un intento
    r = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert r.status_code == 400
    assert r.json()["code"] == "CURRENCY_MISMATCH"
    assert _saldo(await _cuentas(client, registrado), origen) == 5_000


@pytest.mark.asyncio
async def test_a_una_cuenta_inexistente_o_de_sistema_es_recipient_not_found(
    client, registrado, db_de_client
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-04")
    caja = await accounts_service.cuenta_de_sistema(db_de_client, "PEN")
    await db_de_client.commit()
    for i, destino in enumerate((INEXISTENTE_ID, caja.id)):
        r = await client.post(
            "/v1/transfers", json=_envio(origen, destino, clave=f"env-404-{i:04d}"),
            headers=registrado.auth,
        )
        assert r.status_code == 404
        assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_a_una_cuenta_bloqueada_es_recipient_not_found(
    client, registrado, otro_registrado, db_de_client
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-05")
    destino = (await _cuentas(client, otro_registrado))[0]["id"]
    await db_de_client.execute(update(Account).where(Account.id == destino).values(estado="bloqueada"))
    await db_de_client.commit()
    r = await client.post("/v1/transfers", json=_envio(origen, destino), headers=registrado.auth)
    assert r.status_code == 404


@pytest.mark.asyncio
async def test_reintentar_la_clave_hacia_otra_cuenta_de_la_misma_persona_es_409(
    client, registrado, otro_registrado
):
    origen = (await _cuentas(client, registrado))[0]["id"]
    await _recargar(client, registrado, origen, 5_000, "rec-env-06")
    primera = (await _cuentas(client, otro_registrado))[0]["id"]
    segunda = await _abrir(client, otro_registrado, "corriente", "PEN", "ab-env-06")

    a = await client.post("/v1/transfers", json=_envio(origen, primera), headers=registrado.auth)
    b = await client.post("/v1/transfers", json=_envio(origen, segunda), headers=registrado.auth)
    assert a.status_code == 201
    assert b.status_code == 409
    assert b.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_envio_y_recarga_en_dolares(client, registrado, otro_registrado):
    mi_usd = await _abrir(client, registrado, "ahorro", "USD", "ab-env-07")
    su_usd = await _abrir(client, otro_registrado, "ahorro", "USD", "ab-env-08")
    await _recargar(client, registrado, mi_usd, 3_000, "rec-env-07")

    r = await client.post(
        "/v1/transfers", json=_envio(mi_usd, su_usd, 1_200), headers=registrado.auth
    )
    assert r.status_code == 201
    assert _saldo(await _cuentas(client, otro_registrado), su_usd) == 1_200

    movs = (
        await client.get(f"/v1/accounts/{su_usd}/movements", headers=otro_registrado.auth)
    ).json()["movimientos"]
    assert movs[0]["moneda"] == "USD"


@pytest.mark.asyncio
async def test_una_recarga_en_dolares_sale_de_la_caja_de_dolares(
    client, registrado, db_de_client
):
    mi_usd = await _abrir(client, registrado, "ahorro", "USD", "ab-env-09")
    await _recargar(client, registrado, mi_usd, 2_500, "rec-env-09")
    caja = await accounts_service._buscar_caja(db_de_client, "USD")
    assert caja is not None
    assert caja.saldo_disponible == -2_500
    assert await accounts_service._buscar_caja(db_de_client, "PEN") is None
