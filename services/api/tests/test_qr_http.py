
import pytest


@pytest.mark.parametrize(
    ("ruta", "datos"),
    [
        (
            "/v1/qr/emitir",
            {
                "cuenta_id": "cuenta-prueba",
                "monto_centimos": 1500,
                "concepto": "Compra",
            },
        ),
        (
            "/v1/qr/validar",
            {"qr": "qr-de-prueba"},
        ),
        (
            "/v1/qr/pagar",
            {
                "qr": "qr-de-prueba",
                "cuenta_origen_id": "cuenta-prueba",
                "idempotency_key": "prueba-qr-001",
            },
        ),
    ],
)
async def test_qr_requiere_autenticacion(client, ruta, datos):
    respuesta = await client.post(ruta, json=datos)

    assert respuesta.status_code == 401
    assert respuesta.json()["code"] == "UNAUTHENTICATED"
