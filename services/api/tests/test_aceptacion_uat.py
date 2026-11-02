"""
Escenarios de aceptación (UAT) del plan de V&V (`docs/vyv.md`, sesión 20).

Cada prueba es un escenario del guion en forma Given/When/Then, recorrido por
HTTP como lo haría la app. Cubren el lado del servidor; las pantallas siguen en
`docs/verificacion-manual.md`.
"""

import pytest

from app.core.config import settings
from tests.conftest import PIN_DE_PRUEBA as PIN

PIN_MALO = "135790"


async def _cuentas(client, titular):
    r = await client.get("/v1/accounts", headers=titular.auth)
    assert r.status_code == 200, r.text
    return r.json()["cuentas"]


async def _saldo(client, titular):
    return (await _cuentas(client, titular))[0]["saldo_disponible"]


async def _depositar(client, titular, centimos, clave):
    cuenta = (await _cuentas(client, titular))[0]["id"]
    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta, "monto_centimos": centimos, "pin": PIN,
              "idempotency_key": clave},
        headers=titular.auth,
    )
    assert r.status_code == 201, r.text
    return cuenta


async def _enviar(client, titular, origen, destino, centimos, clave, pin=PIN):
    return await client.post(
        "/v1/transfers",
        json={"cuenta_origen_id": origen, "cuenta_destino_id": destino,
              "monto_centimos": centimos, "pin": pin, "idempotency_key": clave},
        headers=titular.auth,
    )


@pytest.mark.asyncio
async def test_uat1_enviar_dinero_a_otro_titular_y_que_ambos_lados_cuadren(
    client, registrado, otro_registrado
):
    """
    UAT-1 · Precondición: A con S/ 500.00, B existe con una cuenta en soles.
    Pasos: A busca a B por DNI, elige su cuenta y envía S/ 125.50 con PIN.
    Esperado: A ve el nombre enmascarado; A queda con S/ 374.50, B con
    S/ 125.50; cada uno ve UN movimiento y el libro cuadra.
    """
    # Given
    origen = await _depositar(client, registrado, 50_000, "uat1-deposito")

    # When: A busca a B (solo ve datos enmascarados)
    r = await client.get(
        f"/v1/directory/resolve?dni={otro_registrado.dni}", headers=registrado.auth
    )
    assert r.status_code == 200, r.text
    busqueda = r.json()
    assert busqueda["nombre_enmascarado"] == "L*** A*** Q***"
    assert "Quispe" not in str(busqueda)
    destino = busqueda["cuentas"][0]["cuenta_id"]

    r = await _enviar(client, registrado, origen, destino, 12_550, "uat1-envio")

    # Then
    assert r.status_code == 201, r.text
    assert await _saldo(client, registrado) == 37_450
    assert await _saldo(client, otro_registrado) == 12_550

    envio = (await client.get("/v1/movements", headers=registrado.auth)).json()["movimientos"][0]
    assert (envio["direccion"], envio["monto"]) == ("debito", 12_550)
    assert "Quispe" not in str(envio)  # quien envía no obtiene más que la búsqueda

    recibo = (await client.get("/v1/movements", headers=otro_registrado.auth)).json()["movimientos"]
    assert [(m["direccion"], m["monto"]) for m in recibo] == [("credito", 12_550)]
    assert "ruiz" in recibo[0]["contraparte"].lower()  # quien recibe sí ve a quién le pagó


@pytest.mark.asyncio
async def test_uat2_sin_saldo_el_envio_se_rechaza_con_un_error_claro_y_sin_mover_dinero(
    client, registrado, otro_registrado
):
    """
    UAT-2 · Precondición: A con S/ 50.00. Pasos: A intenta enviar S/ 500.00.
    Esperado: error INSUFFICIENT_FUNDS legible, saldos intactos, sin movimiento
    nuevo y reintentar con la misma clave no cambia nada.
    """
    origen = await _depositar(client, registrado, 5_000, "uat2-deposito")
    destino = (await _cuentas(client, otro_registrado))[0]["id"]

    for _ in range(2):  # el segundo intento es el reintento con la misma clave
        r = await _enviar(client, registrado, origen, destino, 50_000, "uat2-envio")
        cuerpo = r.json()
        assert r.status_code >= 400
        assert cuerpo["code"] == "INSUFFICIENT_FUNDS"
        assert "Traceback" not in str(cuerpo) and "sqlalchemy" not in str(cuerpo).lower()

    assert await _saldo(client, registrado) == 5_000
    assert await _saldo(client, otro_registrado) == 0
    movimientos = (await client.get("/v1/movements", headers=registrado.auth)).json()["movimientos"]
    assert len(movimientos) == 1  # solo el depósito


@pytest.mark.asyncio
async def test_uat3_el_acceso_se_protege_sin_sesion_con_pin_errado_y_con_bloqueo(
    client, registrado, otro_registrado
):
    """
    UAT-3 · Pasos: pedir datos sin sesión; mover dinero con un PIN errado hasta
    agotar los intentos; probar luego el PIN correcto.
    Esperado: 401 sin sesión; INVALID_CREDENTIALS por intento; al agotarlos
    IDENTIFIER_LOCKED (423) y ni el PIN correcto pasa; el dinero no se movió.
    """
    assert (await client.get("/v1/accounts")).status_code == 401

    origen = await _depositar(client, registrado, 100_000, "uat3-deposito")
    destino = (await _cuentas(client, otro_registrado))[0]["id"]

    for n in range(settings.IDENTIFIER_MAX_ATTEMPTS - 1):
        r = await _enviar(client, registrado, origen, destino, 1_000, f"uat3-malo-{n}", PIN_MALO)
        assert r.json()["code"] == "INVALID_CREDENTIALS"

    r = await _enviar(client, registrado, origen, destino, 1_000, "uat3-malo-ultimo", PIN_MALO)
    assert (r.status_code, r.json()["code"]) == (423, "IDENTIFIER_LOCKED")

    r = await _enviar(client, registrado, origen, destino, 1_000, "uat3-bueno")
    assert r.json()["code"] == "IDENTIFIER_LOCKED"

    assert await _saldo(client, registrado) == 100_000
    assert await _saldo(client, otro_registrado) == 0
