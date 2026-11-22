"""QR estático ("Mi QR"): identifica a quien recibe y el pagador pone el monto.

Es permanente y admite muchos pagos, al contrario del cobro dinámico (monto
fijo, un solo pago, caduca). Vive en `qr_codigos` para poder revocarlo: un QR
impreso que se filtra no se arregla rotando la clave de todos.
"""

import asyncio
import os

import pytest
from sqlalchemy import func, select

from app.db.models import QrCodigo, Transaction, Transfer
from tests.conftest import PIN_DE_PRUEBA

pytestmark = pytest.mark.asyncio

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
            "idempotency_key": f"recarga-qr-est-{titular.dni}",
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


def _pago(qr, origen, clave, monto=1_000, pin=PIN_DE_PRUEBA, mensaje=None):
    cuerpo = {"qr": qr, "cuenta_origen_id": origen, "idempotency_key": clave}
    if monto is not None:
        cuerpo["monto_centimos"] = monto
    if pin is not None:
        cuerpo["pin"] = pin
    if mensaje is not None:
        cuerpo["mensaje"] = mensaje
    return cuerpo


def _validar(qr):
    return {"qr": qr, "acepta_monto_libre": True}


async def test_qr_e01_mi_qr_se_crea_una_vez_y_luego_se_devuelve_el_mismo(
    client, otp_codes, otro_registrado
):
    cuenta = await _cuenta(client, otro_registrado)
    primero = await client.post(
        "/v1/qr/estatico", headers=otro_registrado.auth, json={"cuenta_id": cuenta}
    )
    segundo = await client.post(
        "/v1/qr/estatico", headers=otro_registrado.auth, json={"cuenta_id": cuenta}
    )
    assert primero.status_code == 201, primero.text
    assert segundo.status_code == 200, segundo.text
    assert segundo.json()["qr"] == primero.json()["qr"]
    datos = primero.json()
    assert datos["tipo"] == "libre"
    assert datos["moneda"] == "PEN"
    assert datos["cuenta_id"] == cuenta
    assert len(datos["qr"]) == 45


async def test_qr_e02_no_se_crea_para_una_cuenta_ajena(
    client, otp_codes, registrado, otro_registrado
):
    ajena = await _cuenta(client, otro_registrado)
    r = await client.post(
        "/v1/qr/estatico", headers=registrado.auth, json={"cuenta_id": ajena}
    )
    assert r.status_code == 404, r.text


async def test_qr_e03_una_app_que_no_sabe_de_monto_libre_recibe_un_aviso_claro(
    client, otp_codes, registrado, otro_registrado
):
    # Un APK viejo espera `monto_centimos` y reventaría con null: mejor un
    # código que le diga que se actualice.
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post("/v1/qr/validar", headers=registrado.auth, json={"qr": qr})
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "QR_UPDATE_REQUIRED"


async def test_qr_e04_validar_muestra_a_quien_sin_monto_y_no_mueve_dinero(
    client, otp_codes, registrado, otro_registrado
):
    await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post("/v1/qr/validar", headers=registrado.auth, json=_validar(qr))
    assert r.status_code == 200, r.text
    datos = r.json()
    assert datos["tipo"] == "libre"
    assert datos["monto_centimos"] is None
    assert datos["caduca_en"] is None
    assert datos["moneda"] == "PEN"
    assert "*" in datos["nombre_enmascarado"]
    assert datos["requiere_pin"] is True
    assert await _saldo(client, registrado) == 60_000


async def test_qr_e05_el_pagador_elige_el_monto_y_se_registra_como_pago_qr(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-libre-001", monto=1_234, mensaje="Menú del día"),
    )
    assert r.status_code == 201, r.text
    assert r.json()["monto_centimos"] == 1_234
    assert await _saldo(client, registrado) == 58_766
    assert await _saldo(client, otro_registrado) == 1_234
    tx = (
        await db_de_client.execute(
            select(Transaction).where(Transaction.id == r.json()["transaction_id"])
        )
    ).scalar_one()
    assert tx.tipo == "pago_qr"
    # La referencia ata el pago al QR que lo originó (conciliación, épica 6).
    assert tx.referencia == "qr:" + qr.split(".")[0]
    transfer = (
        await db_de_client.execute(select(Transfer).where(Transfer.transaction_id == tx.id))
    ).scalar_one()
    assert transfer.motivo == "Menú del día"


async def test_qr_e06_el_mismo_qr_admite_muchos_pagos(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    for n, monto in enumerate((500, 700, 300)):
        r = await client.post(
            "/v1/qr/pagar",
            headers=registrado.auth,
            json=_pago(qr, origen, f"pago-libre-mult-{n}", monto=monto),
        )
        assert r.status_code == 201, r.text
    assert await _saldo(client, otro_registrado) == 1_500
    assert await _saldo(client, registrado) == 58_500


async def test_qr_e07_reintentar_con_la_misma_clave_no_cobra_dos_veces(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    cuerpo = _pago(qr, origen, "pago-libre-idem-1", monto=2_000)
    primero = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    segundo = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert primero.status_code == 201, primero.text
    assert segundo.status_code == 200, segundo.text
    assert segundo.json()["transaction_id"] == primero.json()["transaction_id"]

    # Misma clave con OTRO monto no es un reintento: devolver el original haría
    # creer que se pagó lo que se acaba de escribir.
    otro = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-libre-idem-1", monto=2_500),
    )
    assert otro.status_code == 409, otro.text
    assert otro.json()["code"] == "IDEMPOTENCY_KEY_REUSED"
    assert await _saldo(client, registrado) == 58_000
    cantidad = (await db_de_client.execute(select(func.count()).select_from(Transfer))).scalar_one()
    assert cantidad == 1


@pytest.mark.parametrize(
    ("monto", "codigo"),
    [(None, "QR_AMOUNT_REQUIRED"), (0, "AMOUNT_OUT_OF_RANGE"), (200_001, "AMOUNT_OUT_OF_RANGE")],
)
async def test_qr_e08_sin_monto_o_fuera_de_rango_no_paga(
    client, otp_codes, registrado, otro_registrado, monto, codigo
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-libre-rango", monto=monto),
    )
    assert r.status_code == 400, r.text
    assert r.json()["code"] == codigo
    assert await _saldo(client, registrado) == 60_000
    assert await _saldo(client, otro_registrado) == 0


async def test_qr_e09_sin_pin_no_paga(client, otp_codes, registrado, otro_registrado):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-libre-sinpin", monto=100, pin=None),
    )
    assert r.status_code == 403, r.text
    assert r.json()["code"] == "QR_AUTH_REQUIRED"
    assert await _saldo(client, registrado) == 60_000


async def test_qr_e10_regenerar_revoca_el_anterior(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    viejo = await _mi_qr(client, otro_registrado)
    r = await client.post(
        "/v1/qr/estatico/regenerar",
        headers=otro_registrado.auth,
        json={"cuenta_id": await _cuenta(client, otro_registrado)},
    )
    assert r.status_code == 201, r.text
    nuevo = r.json()["qr"]
    assert nuevo != viejo
    assert await _mi_qr(client, otro_registrado) == nuevo

    consulta = await client.post(
        "/v1/qr/validar", headers=registrado.auth, json=_validar(viejo)
    )
    pago = await client.post(
        "/v1/qr/pagar", headers=registrado.auth, json=_pago(viejo, origen, "pago-revocado")
    )
    assert consulta.status_code == 400, consulta.text
    assert consulta.json()["code"] == "QR_REVOKED"
    assert pago.status_code == 400, pago.text
    assert pago.json()["code"] == "QR_REVOKED"
    assert await _saldo(client, registrado) == 60_000

    vale = await client.post(
        "/v1/qr/pagar", headers=registrado.auth, json=_pago(nuevo, origen, "pago-al-nuevo")
    )
    assert vale.status_code == 201, vale.text


async def test_qr_e11_un_pago_hecho_se_puede_reintentar_aunque_se_haya_revocado(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    cuerpo = _pago(qr, origen, "pago-antes-revocar", monto=900)
    primero = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert primero.status_code == 201, primero.text
    await client.post(
        "/v1/qr/estatico/regenerar",
        headers=otro_registrado.auth,
        json={"cuenta_id": await _cuenta(client, otro_registrado)},
    )
    reintento = await client.post("/v1/qr/pagar", headers=registrado.auth, json=cuerpo)
    assert reintento.status_code == 200, reintento.text
    assert reintento.json()["transaction_id"] == primero.json()["transaction_id"]
    assert await _saldo(client, otro_registrado) == 900


async def test_qr_e12_la_misma_clave_en_dos_titulares_no_choca(
    client, otp_codes, registrado, otro_registrado
):
    # La clave del cliente se acota a su titular: la de otro no debe devolverle
    # un pago ajeno ni bloquearle el suyo.
    origen_a = await _recargar(client, registrado)
    origen_b = await _recargar(client, otro_registrado)
    qr_a = await _mi_qr(client, registrado)
    qr_b = await _mi_qr(client, otro_registrado)
    r1 = await client.post(
        "/v1/qr/pagar", headers=registrado.auth, json=_pago(qr_b, origen_a, "clave-comun-01")
    )
    r2 = await client.post(
        "/v1/qr/pagar", headers=otro_registrado.auth, json=_pago(qr_a, origen_b, "clave-comun-01")
    )
    assert r1.status_code == 201, r1.text
    assert r2.status_code == 201, r2.text
    assert r1.json()["transaction_id"] != r2.json()["transaction_id"]


async def test_qr_e13_no_se_paga_a_si_mismo_con_la_misma_cuenta(
    client, otp_codes, registrado
):
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, registrado)
    r = await client.post(
        "/v1/qr/pagar", headers=registrado.auth, json=_pago(qr, origen, "pago-a-mi-mismo")
    )
    assert r.status_code == 400, r.text
    assert r.json()["code"] == "SAME_ACCOUNT"


async def test_qr_e14_mensaje_largo_se_rechaza_en_la_entrada(
    client, otp_codes, registrado, otro_registrado
):
    # `transfers.motivo` es VARCHAR(40); SQLite no lo haría cumplir.
    origen = await _recargar(client, registrado)
    qr = await _mi_qr(client, otro_registrado)
    r = await client.post(
        "/v1/qr/pagar",
        headers=registrado.auth,
        json=_pago(qr, origen, "pago-msj-largo", mensaje="x" * 41),
    )
    assert r.status_code == 422, r.text


async def test_qr_e15_un_cobro_fijo_no_se_puede_pagar_como_libre_ni_al_reves(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    # Un QR estático no guarda monto ni caducidad; un dinámico, ambos. Lo hace
    # cumplir la base con un CHECK, no solo el código.
    qr = await _mi_qr(client, otro_registrado)
    fila = (
        await db_de_client.execute(select(QrCodigo).where(QrCodigo.id == qr.split(".")[0]))
    ).scalar_one()
    assert fila.tipo == "estatico"
    assert fila.monto is None
    assert fila.expires_at is None
    assert fila.estado == "activo"


@pytest.mark.postgres
async def test_qr_e16_dos_pedidos_simultaneos_de_mi_qr_dan_el_mismo(
    client, otp_codes, otro_registrado
):
    if not os.environ.get("TEST_POSTGRES_URL"):
        pytest.skip("Define TEST_POSTGRES_URL (Postgres desechable) para correr este test.")
    cuenta = await _cuenta(client, otro_registrado)
    respuestas = await asyncio.gather(
        *(
            client.post(
                "/v1/qr/estatico", headers=otro_registrado.auth, json={"cuenta_id": cuenta}
            )
            for _ in range(3)
        )
    )
    assert all(r.status_code in (200, 201) for r in respuestas), [r.text for r in respuestas]
    assert len({r.json()["qr"] for r in respuestas}) == 1
