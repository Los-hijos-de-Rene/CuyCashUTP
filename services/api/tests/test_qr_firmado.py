"""Token del QR: corto, opaco y firmado (#77).

El token ya no lleva los datos del cobro: solo una referencia aleatoria a la
fila de `qr_codigos` y una firma HMAC truncada. Monto, cuenta y caducidad viven
en el servidor, que es el único que decide.
"""

import base64
import json
import re

import pytest

from app.services.qr_firmado import (
    LARGO_TOKEN,
    huella_de_pago,
    leer_token,
    nuevo_id,
    token_de,
)

SECRETO = "clave-de-pruebas-qr-con-longitud-segura-123456789"
OTRO_SECRETO = "otra-clave-segura-para-pruebas-123456789"


def test_qr_01_el_token_es_corto_y_se_lee_de_vuelta():
    qr_id = nuevo_id()
    token = token_de(qr_id, secreto=SECRETO)

    assert len(token) == LARGO_TOKEN == 45
    assert re.fullmatch(r"[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{22}", token)
    assert leer_token(token, secreto=SECRETO) == qr_id


def test_qr_02_dos_ids_nunca_se_repiten():
    assert len({nuevo_id() for _ in range(1_000)}) == 1_000


def test_qr_03_rechaza_firma_alterada():
    qr_id, firma = token_de(nuevo_id(), secreto=SECRETO).split(".")
    otra = ("A" if firma[0] != "A" else "B") + firma[1:]

    with pytest.raises(ValueError):
        leer_token(f"{qr_id}.{otra}", secreto=SECRETO)


def test_qr_04_rechaza_id_cambiado_con_la_firma_original():
    # Cambiar la referencia para apuntar a otro cobro invalida la firma.
    qr_id, firma = token_de(nuevo_id(), secreto=SECRETO).split(".")
    otro_id = ("A" if qr_id[0] != "A" else "B") + qr_id[1:]

    with pytest.raises(ValueError):
        leer_token(f"{otro_id}.{firma}", secreto=SECRETO)


def test_qr_05_rechaza_clave_diferente():
    token = token_de(nuevo_id(), secreto=SECRETO)

    with pytest.raises(ValueError):
        leer_token(token, secreto=OTRO_SECRETO)


@pytest.mark.parametrize(
    "basura",
    ["", "sin-punto", "a.b", "." * 45, "x" * 2049, " " + "A" * 22 + "." + "A" * 22],
)
def test_qr_06_rechaza_lo_que_no_tiene_la_forma(basura):
    with pytest.raises(ValueError):
        leer_token(basura, secreto=SECRETO)


def test_qr_07_un_token_del_formato_anterior_ya_no_vale():
    # v1 llevaba el cobro en claro (base64 de JSON) + HMAC completo en hex.
    mensaje = base64.urlsafe_b64encode(
        json.dumps({"v": 1, "cuenta_id": "c", "monto_centimos": 1}).encode()
    ).decode().rstrip("=")
    with pytest.raises(ValueError):
        leer_token(f"{mensaje}.{'0' * 64}", secreto=SECRETO)


def test_qr_08_el_token_no_revela_nada_del_cobro():
    token = token_de(nuevo_id(), secreto=SECRETO)
    qr_id, _ = token.split(".")
    relleno = "=" * (-len(qr_id) % 4)
    crudo = base64.urlsafe_b64decode(qr_id + relleno)
    # 16 bytes aleatorios: no hay JSON, ni cuenta, ni monto que leer.
    assert len(crudo) == 16


def test_qr_09_exige_una_clave_de_al_menos_32_bytes():
    with pytest.raises(ValueError):
        token_de(nuevo_id(), secreto="corta")
    with pytest.raises(ValueError):
        leer_token("A" * 22 + "." + "A" * 22, secreto="corta")


def test_qr_10_la_huella_del_pago_cabe_en_la_columna_y_es_estable():
    qr_id = nuevo_id()
    assert huella_de_pago(qr_id) == huella_de_pago(qr_id)
    assert len(huella_de_pago(qr_id)) == 64
    assert huella_de_pago(qr_id) != huella_de_pago(nuevo_id())
