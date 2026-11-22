"""Límite diario de pagos con QR (`app/services/limite_diario.py`).

El tope por operación no frena a quien tiene el teléfono y el PIN de otro: con
monto libre le basta con pagar varias veces. El límite diario acota el daño a
un día. Aquí se baja a S/ 30.00 para no tener que recargar miles de soles.
"""

import asyncio
import os
from datetime import date, datetime, timezone

import pytest
import pytest_asyncio
from sqlalchemy import select

from app.db.models import QrConsumoDiario
from app.services import limite_diario
from tests.conftest import PIN_DE_PRUEBA, registrar

pytestmark = pytest.mark.asyncio

SECRETO_QR_PRUEBAS = "secreto-exclusivo-para-tests-qr-2026-abcdefghijk"
LIMITE = 3_000


@pytest.fixture(autouse=True)
def _configuracion(monkeypatch):
    monkeypatch.setenv("QR_SIGNING_SECRET", SECRETO_QR_PRUEBAS)
    monkeypatch.setitem(limite_diario.LIMITE_DIARIO_QR, "PEN", LIMITE)


@pytest_asyncio.fixture
async def tercero_registrado(client, otp_codes):
    return await registrar(
        client, otp_codes, dni="40123987", nombres="Rosa Elena", apellidos="Mamani"
    )


async def _cuenta(client, titular):
    r = await client.get("/v1/accounts", headers=titular.auth)
    assert r.status_code == 200, r.text
    return r.json()["cuentas"][0]["id"]


async def _saldo(client, titular):
    r = await client.get("/v1/accounts", headers=titular.auth)
    return r.json()["cuentas"][0]["saldo_disponible"]


async def _recargar(client, titular, monto=60_000):
    cuenta_id = await _cuenta(client, titular)
    r = await client.post(
        "/v1/topups",
        headers=titular.auth,
        json={
            "cuenta_id": cuenta_id,
            "monto_centimos": monto,
            "idempotency_key": f"recarga-limite-{titular.dni}",
        },
    )
    assert r.status_code == 201, r.text
    return cuenta_id


async def _mi_qr(client, titular):
    r = await client.post(
        "/v1/qr/estatico",
        headers=titular.auth,
        json={"cuenta_id": await _cuenta(client, titular)},
    )
    assert r.status_code in (200, 201), r.text
    return r.json()["qr"]


async def _cobro(client, titular, monto):
    r = await client.post(
        "/v1/qr/emitir",
        headers=titular.auth,
        json={"cuenta_id": await _cuenta(client, titular), "monto_centimos": monto},
    )
    assert r.status_code == 201, r.text
    return r.json()["qr"]


async def _pagar(client, titular, qr, origen, clave, monto=None, pin=PIN_DE_PRUEBA):
    cuerpo = {"qr": qr, "cuenta_origen_id": origen, "idempotency_key": clave, "pin": pin}
    if monto is not None:
        cuerpo["monto_centimos"] = monto
    return await client.post("/v1/qr/pagar", headers=titular.auth, json=cuerpo)


async def _disponible(client, titular, qr):
    r = await client.post(
        "/v1/qr/validar", headers=titular.auth, json={"qr": qr, "acepta_monto_libre": True}
    )
    assert r.status_code == 200, r.text
    return r.json()["disponible_hoy_centimos"]


async def test_limite_01_el_pago_que_supera_el_dia_se_rechaza_y_no_mueve_dinero(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    assert (await _pagar(client, registrado, qr, origen, "limite-qr-01-a", 2_000)).status_code == 201

    r = await _pagar(client, registrado, qr, origen, "limite-qr-01-b", 1_500)
    assert r.status_code == 400, r.text
    cuerpo = r.json()
    assert cuerpo["code"] == "QR_DAILY_LIMIT"
    assert cuerpo["disponible_centimos"] == 1_000
    assert cuerpo["limite_centimos"] == LIMITE
    assert cuerpo["moneda"] == "PEN"
    assert "S/ 10.00" in cuerpo["detail"]
    assert await _saldo(client, registrado) == 58_000

    # Lo que queda sí se puede pagar, justo hasta el límite.
    assert (await _pagar(client, registrado, qr, origen, "limite-qr-01-c", 1_000)).status_code == 201
    r = await _pagar(client, registrado, qr, origen, "limite-qr-01-d", 1)
    assert r.json()["code"] == "QR_DAILY_LIMIT"
    assert r.json()["disponible_centimos"] == 0


async def test_limite_02_cuentan_juntos_el_qr_estatico_y_el_cobro_dinamico(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    cobro = await _cobro(client, otro_registrado, 2_500)
    assert (await _pagar(client, registrado, cobro, origen, "limite-qr-02-a")).status_code == 201

    qr = await _mi_qr(client, otro_registrado)
    r = await _pagar(client, registrado, qr, origen, "limite-qr-02-b", 600)
    assert r.json()["code"] == "QR_DAILY_LIMIT"
    assert r.json()["disponible_centimos"] == 500


async def test_limite_03_un_reintento_no_suma_ni_choca_con_el_limite(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    primero = await _pagar(client, registrado, qr, origen, "limite-qr-03", LIMITE)
    assert primero.status_code == 201, primero.text

    # El cupo ya está lleno, pero repetir el pago no es un pago nuevo: devuelve
    # el original en vez de un "superaste tu límite" que haría creer que no pagó.
    segundo = await _pagar(client, registrado, qr, origen, "limite-qr-03", LIMITE)
    assert segundo.status_code == 200, segundo.text
    assert segundo.json()["transaction_id"] == primero.json()["transaction_id"]
    consumo = (await db_de_client.execute(select(QrConsumoDiario))).scalar_one()
    assert consumo.consumido == LIMITE


async def test_limite_04_validar_dice_cuanto_queda_hoy(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    assert await _disponible(client, registrado, qr) == LIMITE
    await _pagar(client, registrado, qr, origen, "limite-qr-04", 1_200)
    assert await _disponible(client, registrado, qr) == 1_800
    # Es del pagador: a quien cobra no le resta nada.
    assert await _disponible(client, otro_registrado, await _mi_qr(client, registrado)) == LIMITE


async def test_limite_05_un_pin_incorrecto_no_consume_cupo(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await _pagar(client, registrado, qr, origen, "limite-qr-05", 1_000, pin="999999")
    assert r.json()["code"] == "INVALID_CREDENTIALS", r.text
    assert await _disponible(client, registrado, qr) == LIMITE


async def test_limite_06_un_cobro_ya_pagado_por_otro_no_consume_cupo(
    client, otp_codes, registrado, otro_registrado, tercero_registrado
):
    origen = await _recargar(client, registrado)
    cobro = await _cobro(client, tercero_registrado, 1_000)
    await _recargar(client, otro_registrado)
    assert (
        await _pagar(client, otro_registrado, cobro, await _cuenta(client, otro_registrado), "limite-qr-06-x")
    ).status_code == 201
    r = await _pagar(client, registrado, cobro, origen, "limite-qr-06-y")
    assert r.json()["code"] == "QR_ALREADY_PAID"
    assert await _disponible(client, registrado, await _mi_qr(client, tercero_registrado)) == LIMITE


async def test_limite_07_al_dia_siguiente_el_cupo_vuelve(
    client, otp_codes, registrado, otro_registrado, monkeypatch
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    assert (await _pagar(client, registrado, qr, origen, "limite-qr-07-a", LIMITE)).status_code == 201
    manana = date.fromordinal(limite_diario.hoy_en_lima().toordinal() + 1)
    monkeypatch.setattr(limite_diario, "hoy_en_lima", lambda ahora=None: manana)
    assert (await _pagar(client, registrado, qr, origen, "limite-qr-07-b", LIMITE)).status_code == 201


async def test_limite_08_el_dia_es_el_de_lima_no_el_de_utc():
    # 04:59 UTC del 2 es todavía el 1 en Lima (UTC-5); 05:00 UTC ya es el 2.
    assert limite_diario.hoy_en_lima(datetime(2026, 11, 2, 4, 59, tzinfo=timezone.utc)) == date(
        2026, 11, 1
    )
    assert limite_diario.hoy_en_lima(datetime(2026, 11, 2, 5, 0, tzinfo=timezone.utc)) == date(
        2026, 11, 2
    )


@pytest.mark.postgres
async def test_limite_09_pagos_simultaneos_no_pasan_el_limite_juntos(
    client, otp_codes, registrado, otro_registrado
):
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    # Cuatro pagos de S/ 10 contra un cupo de S/ 30: sin el bloqueo de la fila,
    # los cuatro leerían "me queda cupo" a la vez.
    respuestas = await asyncio.gather(
        *(_pagar(client, registrado, qr, origen, f"limite-qr-09-{n}", 1_000) for n in range(4))
    )
    codigos = sorted(r.status_code for r in respuestas)
    assert codigos == [201, 201, 201, 400], [r.text for r in respuestas]
    assert await _saldo(client, registrado) == 57_000
