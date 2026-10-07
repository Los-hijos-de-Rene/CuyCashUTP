"""
`GET /v1/movements`: el historial de TODAS las cuentas del titular, el que
muestra el inicio. Cada fila dice de qué cuenta es y una transferencia entre
cuentas propias sale una sola vez.
"""

from tests.conftest import PIN_DE_PRUEBA


async def _cuentas(client, titular) -> list:
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"]


async def _depositar(client, titular, cuenta_id, centimos, clave):
    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta_id, "monto_centimos": centimos, "idempotency_key": clave},
        headers=titular.auth,
    )
    assert r.status_code == 201, r.text


async def _enviar(client, titular, origen, destino, centimos, clave):
    r = await client.post(
        "/v1/transfers",
        json={
            "cuenta_origen_id": origen,
            "cuenta_destino_id": destino,
            "monto_centimos": centimos,
            "pin": PIN_DE_PRUEBA,
            "idempotency_key": clave,
        },
        headers=titular.auth,
    )
    assert r.status_code == 201, r.text


async def _abrir_corriente(client, titular) -> str:
    r = await client.post(
        "/v1/accounts",
        json={"tipo": "corriente", "moneda": "PEN", "nombre": "Gastos",
              "pin": PIN_DE_PRUEBA, "idempotency_key": "abrir-corriente-1"},
        headers=titular.auth,
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def _todos(client, titular, **params):
    r = await client.get("/v1/movements", params=params, headers=titular.auth)
    assert r.status_code == 200, r.text
    return r.json()


async def test_mezcla_las_cuentas_y_cada_fila_dice_de_cual_es(client, registrado):
    ahorro = (await _cuentas(client, registrado))[0]["id"]
    corriente = await _abrir_corriente(client, registrado)
    await _depositar(client, registrado, ahorro, 10_000, "dep-ahorro-01")
    await _depositar(client, registrado, corriente, 5_000, "dep-corr-0001")

    cuerpo = await _todos(client, registrado)
    filas = cuerpo["movimientos"]

    assert [f["cuenta"]["id"] for f in filas] == [corriente, ahorro]
    assert filas[0]["cuenta"] == {
        "id": corriente,
        "tipo": "corriente",
        "moneda": "PEN",
        "numero_masked": filas[0]["cuenta"]["numero_masked"],
        "nombre": "Gastos",
    }
    assert filas[0]["cuenta"]["numero_masked"].startswith("••••")
    assert all(f["contraparte"] == "Depósito simulado" for f in filas)
    assert all(f["entre_propias"] is False and f["cuenta_destino"] is None for f in filas)
    assert cuerpo["next_cursor"] is None


async def test_una_transferencia_entre_propias_sale_una_sola_vez(client, registrado):
    ahorro = (await _cuentas(client, registrado))[0]["id"]
    corriente = await _abrir_corriente(client, registrado)
    await _depositar(client, registrado, ahorro, 10_000, "dep-ahorro-01")
    await _enviar(client, registrado, ahorro, corriente, 3_000, "propias-0001")

    filas = (await _todos(client, registrado))["movimientos"]

    assert len(filas) == 2  # el depósito y UNA fila de la transferencia
    propia = filas[0]
    assert propia["entre_propias"] is True
    assert propia["direccion"] == "debito"
    assert propia["monto"] == 3_000
    assert propia["cuenta"]["id"] == ahorro
    assert propia["cuenta_destino"]["id"] == corriente
    assert propia["cuenta_destino"]["nombre"] == "Gastos"

    # El historial de cada cuenta sigue mostrando su lado.
    r = await client.get(f"/v1/accounts/{corriente}/movements", headers=registrado.auth)
    [credito] = r.json()["movimientos"]
    assert credito["direccion"] == "credito"


async def test_con_terceros_cada_uno_ve_su_lado(client, registrado, otro_registrado):
    origen = (await _cuentas(client, registrado))[0]["id"]
    destino = (await _cuentas(client, otro_registrado))[0]["id"]
    await _depositar(client, registrado, origen, 10_000, "dep-ahorro-01")
    await _enviar(client, registrado, origen, destino, 2_500, "terceros-001")

    mias = (await _todos(client, registrado))["movimientos"]
    suyas = (await _todos(client, otro_registrado))["movimientos"]

    assert mias[0]["direccion"] == "debito"
    assert mias[0]["entre_propias"] is False
    assert mias[0]["contraparte"] == "L*** A*** Q***"
    assert [f["direccion"] for f in suyas] == ["credito"]
    assert suyas[0]["cuenta"]["id"] == destino
    # Ninguna fila de uno aparece en el historial del otro titular.
    assert {f["cuenta"]["id"] for f in suyas} == {destino}


async def test_pagina_con_cursor_sin_repetir_ni_saltar(client, registrado):
    ahorro = (await _cuentas(client, registrado))[0]["id"]
    corriente = await _abrir_corriente(client, registrado)
    for i in range(7):
        cuenta = ahorro if i % 2 == 0 else corriente
        await _depositar(client, registrado, cuenta, 100 + i, f"dep-pag-{i:04d}")

    vistos, cursor = [], None
    while True:
        params = {"limit": 3}
        if cursor:
            params["cursor"] = cursor
        cuerpo = await _todos(client, registrado, **params)
        vistos += [f["monto"] for f in cuerpo["movimientos"]]
        cursor = cuerpo["next_cursor"]
        if cursor is None:
            break

    assert vistos == [106, 105, 104, 103, 102, 101, 100]


async def test_limit_corto_para_el_inicio(client, registrado):
    ahorro = (await _cuentas(client, registrado))[0]["id"]
    for i in range(6):
        await _depositar(client, registrado, ahorro, 100 + i, f"dep-ini-{i:04d}")

    cuerpo = await _todos(client, registrado, limit=5)

    assert len(cuerpo["movimientos"]) == 5
    assert cuerpo["next_cursor"] is not None


async def test_exige_sesion(client):
    assert (await client.get("/v1/movements")).status_code == 401
