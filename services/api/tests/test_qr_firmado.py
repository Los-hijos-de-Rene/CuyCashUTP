
import base64
import json

import pytest

from app.services.qr_firmado import emitir_qr, validar_qr


SECRETO = "clave-de-pruebas-qr-con-longitud-segura-123456789"


def generar(**cambios):
    datos = {
        "secreto": SECRETO,
        "cuenta_id": "cuenta-123",
        "monto_centimos": 1500,
        "concepto": "Pago de prueba",
        "ttl_segundos": 300,
        "ahora": 1000,
    }

    datos.update(cambios)

    return emitir_qr(**datos)


def test_qr_01_emision_y_validacion():
    token = generar()

    datos = validar_qr(
        token,
        secreto=SECRETO,
        ahora=1100,
    )

    assert datos["cuenta_id"] == "cuenta-123"
    assert datos["monto_centimos"] == 1500
    assert datos["concepto"] == "Pago de prueba"
    assert datos["exp"] == 1300


def test_qr_02_rechaza_qr_vencido():
    token = generar(ttl_segundos=60)

    with pytest.raises(ValueError):
        validar_qr(
            token,
            secreto=SECRETO,
            ahora=1060,
        )


def test_qr_03_rechaza_firma_alterada():
    token = generar()

    mensaje, firma = token.split(".")

    nueva_firma = (
        "0" if firma[0] != "0" else "1"
    ) + firma[1:]

    token_alterado = f"{mensaje}.{nueva_firma}"

    with pytest.raises(ValueError):
        validar_qr(
            token_alterado,
            secreto=SECRETO,
            ahora=1001,
        )


def test_qr_04_rechaza_monto_modificado():
    token = generar()

    mensaje, firma = token.split(".")

    relleno = "=" * (-len(mensaje) % 4)

    datos = json.loads(
        base64.urlsafe_b64decode(mensaje + relleno)
    )

    datos["monto_centimos"] = 50000

    nuevo_mensaje = base64.urlsafe_b64encode(
        json.dumps(
            datos,
            sort_keys=True,
            separators=(",", ":"),
            ensure_ascii=False,
        ).encode("utf-8")
    ).decode("ascii").rstrip("=")

    token_alterado = f"{nuevo_mensaje}.{firma}"

    with pytest.raises(ValueError):
        validar_qr(
            token_alterado,
            secreto=SECRETO,
            ahora=1001,
        )


def test_qr_05_rechaza_clave_diferente():
    token = generar()

    with pytest.raises(ValueError):
        validar_qr(
            token,
            secreto="otra-clave-segura-para-pruebas-123456789",
            ahora=1001,
        )


def test_qr_06_caducidad_configurable():
    token = generar(ttl_segundos=600)

    datos = validar_qr(
        token,
        secreto=SECRETO,
        ahora=1300,
    )

    assert datos["exp"] == 1600
