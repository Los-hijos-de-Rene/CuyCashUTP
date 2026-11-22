"""Pruebas HTTP del flujo completo QR (#77).

Solo utiliza la base de pruebas de conftest.py. Nunca apunta a cuentas reales.
"""

import asyncio
import os
from datetime import timedelta

import pytest
from sqlalchemy import func, select, update

from app.db.models import QrCodigo, Transaction, Transfer, utcnow
from tests.conftest import PIN_DE_PRUEBA

pytestmark = pytest.mark.asyncio

# Solo pruebas; nunca reutilizar esta clave como secreto de producción.
SECRETO_QR_PRUEBAS = "secreto-exclusivo-para-tests-qr-2026-abcdefghijk"


@pytest.fixture(autouse=True)
def _configuracion_qr_de_prueba(monkeypatch):
    monkeypatch.setenv("QR_SIGNING_SECRET", SECRETO_QR_PRUEBAS)


async def _cuenta(client, titular):
    r = await client.get("/v1/accounts", headers=titular.auth)
    assert r.status_code == 200, r.text
    return r.json()["cuentas"][0]["id"]


async def _saldo(client, titular):
    r = await client.get("/v1/accounts", headers=titular.auth)
    assert r.status_code == 200, r.text
    return r.json()["cuentas"][0]["saldo_disponible"]


async def _recargar(client, titular, monto=60_000):
    cuenta_id = await _cuenta(client, titular)
    r = await client.post(
        "/v1/topups",
        headers=titular.auth,
        json={
            "cuenta_id": cuenta_id,
            "monto_centimos": monto,
            "idempotency_key": f"recarga-qr-{titular.dni}",
        },
    )
    assert r.status_code == 201, r.text
    return cuenta_id


async def _emitir(client, receptor, monto=1_500, concepto="Compra de prueba"):
    cuenta_receptor = await _cuenta(client, receptor)
    r = await client.post(
        "/v1/qr/emitir",
        headers=receptor.auth,
        json={
            "cuenta_id": cuenta_receptor,
            "monto_centimos": monto,
            "concepto": concepto,
            "caducidad_segundos": 300,
        },
    )
    assert r.status_code == 201, r.text
    assert r.json()["monto_centimos"] == monto
    return r.json()["qr"]


def _pago(qr, cuenta_origen_id, clave, pin=PIN_DE_PRUEBA, monto=None):
    cuerpo = {
        "qr": qr,
        "cuenta_origen_id": cuenta_origen_id,
        "idempotency_key": clave,
    }
    if pin is not None:
        cuerpo["pin"] = pin
    if monto is not None:
        cuerpo["monto_centimos"] = monto
    return cuerpo


async def _vencer(db, qr):
    """Lleva la caducidad al pasado sin esperar ni tocar el reloj."""
    await db.execute(
        update(QrCodigo)
        .where(QrCodigo.id == qr.split(".")[0])
        .values(expires_at=utcnow() - timedelta(seconds=1))
    )
    await db.commit()


async def test_qr_01_emitir_y_consultar_nombre_enmascarado(
    client, otp_codes, registrado, otro_registrado
):
    qr = await _emitir(client, otro_registrado, monto=1_500)
    r = await client.post("/v1/qr/validar", headers=registrado.auth, json={"qr": qr})
    assert r.status_code == 200, r.text
    datos = r.json()
    assert datos["monto_centimos"] == 1_500
    assert datos["moneda"] == "PEN"
    assert datos["concepto"] == "Compra de prueba"
    assert datos["tipo"] == "fijo"
    assert "*" in datos["nombre_enmascarado"]
    # El PIN se pide siempre: el campo queda por compatibilidad con APK viejos.
    assert datos["requiere_pin"] is True
    # Corto y opaco: 45 caracteres en vez de ~260, y sin datos del cobro.
    assert len(qr) == 45
    assert "Compra" not in qr
    assert await _saldo(client, registrado) == 0
    assert await _saldo(client, otro_registrado) == 0


async def test_qr_02_el_pin_se_exige_siempre_y_con_el_mueve_ambos_saldos(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado, monto=60_000)
    qr = await _emitir(client, otro_registrado, monto=1_500, concepto="Café")
    sin_pin = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-peq-001", pin=None),
    )
    assert sin_pin.status_code == 403, sin_pin.text
    assert sin_pin.json()["code"] == "QR_AUTH_REQUIRED"
    assert await _saldo(client, registrado) == 60_000

    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-peq-001"),
    )
    assert r.status_code == 201, r.text
    assert r.json()["monto_centimos"] == 1_500
    assert await _saldo(client, registrado) == 58_500
    assert await _saldo(client, otro_registrado) == 1_500
    tx = (
        await db_de_client.execute(
            select(Transaction).where(Transaction.id == r.json()["transaction_id"])
        )
    ).scalar_one()
    assert tx.tipo == "pago_qr"


async def test_qr_03_qr_alterado_se_rechaza_sin_descontar(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    token = await _emitir(client, otro_registrado)
    mensaje, firma = token.split(".")
    firma_alterada = ("0" if firma[0] != "0" else "1") + firma[1:]
    manipulado = f"{mensaje}.{firma_alterada}"

    consulta = await client.post(
        "/v1/qr/validar", headers=registrado.auth, json={"qr": manipulado}
    )
    pago = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(manipulado, origen, "pago-qr-alt-001"),
    )
    assert consulta.status_code == 400, consulta.text
    assert pago.status_code == 400, pago.text
    assert pago.json()["code"] == "QR_INVALID"
    assert await _saldo(client, registrado) == 60_000
    assert await _saldo(client, otro_registrado) == 0


async def test_qr_04_qr_vencido_se_rechaza_sin_descontar(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    vencido = await _emitir(client, otro_registrado, monto=1_500, concepto="Vencido")
    await _vencer(db_de_client, vencido)
    consulta = await client.post(
        "/v1/qr/validar", headers=registrado.auth, json={"qr": vencido}
    )
    pago = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(vencido, origen, "pago-qr-ven-001"),
    )
    assert consulta.status_code == 400, consulta.text
    assert pago.status_code == 400, pago.text
    assert pago.json()["code"] == "QR_EXPIRED"
    assert await _saldo(client, registrado) == 60_000
    assert await _saldo(client, otro_registrado) == 0


async def test_qr_05_el_monto_de_un_cobro_fijo_no_lo_cambia_el_pagador(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=15_000)

    otro_monto = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-fijo-001", monto=100),
    )
    assert otro_monto.status_code == 400, otro_monto.text
    assert otro_monto.json()["code"] == "QR_AMOUNT_FIXED"
    assert await _saldo(client, registrado) == 60_000

    # Mandar el mismo monto del cobro es válido (la app nueva lo hace).
    mismo = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-fijo-001", monto=15_000),
    )
    assert mismo.status_code == 201, mismo.text
    assert await _saldo(client, registrado) == 45_000
    assert await _saldo(client, otro_registrado) == 15_000


async def test_qr_06_idempotencia_no_cobra_dos_veces(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=3_000)
    cuerpo = _pago(qr, origen, "pago-qr-idem-001")

    primera = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    segunda = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert primera.status_code == 201, primera.text
    assert segunda.status_code == 200, segunda.text
    assert segunda.json()["transaction_id"] == primera.json()["transaction_id"]
    assert await _saldo(client, registrado) == 57_000
    assert await _saldo(client, otro_registrado) == 3_000
    cantidad = (await db_de_client.execute(select(func.count()).select_from(Transfer))).scalar_one()
    assert cantidad == 1


async def test_qr_07_cada_qr_es_su_propia_operacion_aunque_repita_clave(
    client, otp_codes, registrado, otro_registrado
):
    # La unicidad la da el QR, no la clave del cliente: repetirla en otro QR no
    # devuelve el pago anterior como si fuera este.
    origen = await _recargar(client, registrado)
    qr_a = await _emitir(client, otro_registrado, monto=2_000)
    qr_b = await _emitir(client, otro_registrado, monto=2_000)
    assert qr_a != qr_b  # El identificador aleatorio es distinto.

    primero = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr_a, origen, "pago-qr-conf-001"),
    )
    segundo = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr_b, origen, "pago-qr-conf-001"),
    )
    assert primero.status_code == 201, primero.text
    assert segundo.status_code == 201, segundo.text
    assert segundo.json()["transaction_id"] != primero.json()["transaction_id"]
    assert await _saldo(client, registrado) == 56_000
    assert await _saldo(client, otro_registrado) == 4_000


async def test_qr_08_no_se_puede_emitir_para_cuenta_ajena(
    client, otp_codes, registrado, otro_registrado
):
    cuenta_ajena = await _cuenta(client, otro_registrado)
    r = await client.post(
        "/v1/qr/emitir",
        headers=registrado.auth,
        json={
            "cuenta_id": cuenta_ajena,
            "monto_centimos": 1_000,
            "concepto": "No autorizada",
        },
    )
    assert r.status_code == 404, r.text


async def test_qr_09_saldo_insuficiente_no_genera_movimiento(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _cuenta(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=5_000)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-fondos-001"),
    )
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "INSUFFICIENT_FUNDS"
    assert await _saldo(client, registrado) == 0
    assert await _saldo(client, otro_registrado) == 0
    cantidad = (await db_de_client.execute(select(func.count()).select_from(Transfer))).scalar_one()
    assert cantidad == 0


async def test_qr_10_mismo_qr_con_otra_clave_no_cobra_dos_veces(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=2_000)
    primero = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-unico-01"),
    )
    segundo = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-unico-02"),
    )
    assert primero.status_code == 201, primero.text
    assert segundo.status_code == 409, segundo.text
    assert segundo.json()["code"] == "QR_ALREADY_PAID"
    assert await _saldo(client, registrado) == 58_000
    assert await _saldo(client, otro_registrado) == 2_000


async def test_qr_11_la_consulta_avisa_que_ya_fue_pagado(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=2_000)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-unico-03"),
    )
    assert r.status_code == 201, r.text

    # Avisa antes de pedir el PIN, no al confirmar.
    consulta = await client.post(
        "/v1/qr/validar", headers=registrado.auth, json={"qr": qr}
    )
    assert consulta.status_code == 409, consulta.text
    assert consulta.json()["code"] == "QR_ALREADY_PAID"


async def test_qr_12_vencido_y_alterado_se_distinguen(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    vencido = await _emitir(client, otro_registrado, monto=500, concepto="Vencido")
    await _vencer(db_de_client, vencido)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(vencido, origen, "pago-qr-vencido-1"),
    )
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "QR_EXPIRED"

    vigente = await _emitir(client, otro_registrado, monto=500)
    alterado = vigente[:-4] + ("0000" if vigente[-4:] != "0000" else "1111")
    r = await client.post(
        "/v1/qr/validar", headers=registrado.auth, json={"qr": alterado}
    )
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "QR_INVALID"


async def test_qr_14_un_pin_errado_no_paga(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=500)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-qr-pin-errado", pin="000000"),
    )
    assert r.status_code == 403, r.text
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert await _saldo(client, registrado) == 60_000
    assert await _saldo(client, otro_registrado) == 0


@pytest.mark.postgres
async def test_qr_13_dos_pagos_a_la_vez_del_mismo_qr_cobran_una_vez(
    client, otp_codes, registrado, otro_registrado
):
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=2_000)
    respuestas = await asyncio.gather(
        *(
            client.post(
                "/v1/qr/pagar",
                headers=registrado.auth,
                json=_pago(qr, origen, f"pago-qr-paralelo-{n}"),
            )
            for n in range(2)
        )
    )
    assert sorted(r.status_code for r in respuestas) == [201, 409]
    assert await _saldo(client, registrado) == 58_000
    assert await _saldo(client, otro_registrado) == 2_000


async def test_qr_15_reintentar_un_pago_hecho_devuelve_el_original_aunque_ya_vencio(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    # Quien no supo si su pago entró debe poder preguntarlo: un QR_EXPIRED
    # le haría creer que no pagó.
    origen = await _recargar(client, registrado)
    qr = await _emitir(client, otro_registrado, monto=2_000)
    cuerpo = _pago(qr, origen, "pago-qr-reint-001")
    primero = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert primero.status_code == 201, primero.text

    await _vencer(db_de_client, qr)
    reintento = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert reintento.status_code == 200, reintento.text
    assert reintento.json()["transaction_id"] == primero.json()["transaction_id"]
    assert await _saldo(client, registrado) == 58_000


async def test_qr_16_un_token_inexistente_firmado_no_revela_nada(
    client, otp_codes, registrado
):
    from app.services.qr_firmado import nuevo_id, token_de

    fantasma = token_de(nuevo_id(), secreto=SECRETO_QR_PRUEBAS)
    r = await client.post("/v1/qr/validar", headers=registrado.auth, json={"qr": fantasma})
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "QR_INVALID"
