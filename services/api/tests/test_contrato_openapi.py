
"""
Pruebas del contrato OpenAPI de CuyCash.
Issue #101 - APF3-C.
"""

import json
from pathlib import Path

from app.main import app


CONTRACT_FILE = (
    Path(__file__).resolve().parents[1] / "openapi.json"
)

EXPECTED_VERSION = "0.2.0"


def test_version_openapi():
    """Comprueba que la version sea la esperada."""
    schema = app.openapi()

    assert schema["info"]["version"] == EXPECTED_VERSION, (
        "La version de OpenAPI cambio sin revision."
    )


def test_contrato_openapi():
    """Detecta cambios inesperados en la API."""
    assert CONTRACT_FILE.exists(), (
        "No existe openapi.json. "
        "Regenera con python scripts/dump_openapi.py"
    )

    contrato_guardado = json.loads(
        CONTRACT_FILE.read_text(encoding="utf-8")
    )

    contrato_actual = app.openapi()

    assert contrato_actual == contrato_guardado, (
        "El contrato OpenAPI ha cambiado. "
        "Regenera con scripts/dump_openapi.py "
        "y revisa si es un cambio de contrato."
    )
