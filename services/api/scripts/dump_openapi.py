
"""
Genera el contrato OpenAPI de CuyCash.
Issue #101 - APF3-C.
"""

import json
import sys
from pathlib import Path

API_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(API_ROOT))

from app.main import app  # noqa: E402


def main():
    contrato = app.openapi()

    destino = API_ROOT / "openapi.json"

    destino.write_text(
        json.dumps(
            contrato,
            indent=2,
            sort_keys=True,
            ensure_ascii=False,
        ) + "\n",
        encoding="utf-8",
    )

    print("Contrato OpenAPI generado correctamente")
    print(f"Version: {contrato['info']['version']}")
    print(f"Archivo: {destino}")


if __name__ == "__main__":
    main()
