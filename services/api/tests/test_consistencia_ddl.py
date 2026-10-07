"""
APF2 · criterio 1.4: el script SQL (DDL) es consistente con el modelo.

`schema.sql` es lo que se entrega como DDL; los modelos de SQLAlchemy son lo
que el servicio crea de verdad. Si alguien cambia un modelo y no regenera el
script (o edita el script a mano), este test falla y lo dice.
"""

import contextlib
import io
import re
import subprocess
import sys
from pathlib import Path

from app.db import models  # noqa: F401  (importar registra las tablas)
from app.db.base import Base

RAIZ = Path(__file__).resolve().parents[1]


def _ddl_generado() -> str:
    sys.path.insert(0, str(RAIZ / "scripts"))
    import dump_schema  # noqa: E402

    salida = io.StringIO()
    with contextlib.redirect_stdout(salida):
        dump_schema.main()
    return salida.getvalue()


def test_schema_sql_es_exactamente_lo_que_generan_los_modelos():
    versionado = (RAIZ / "schema.sql").read_text()
    assert versionado.strip() == _ddl_generado().strip(), (
        "schema.sql no coincide con app/db/models.py. Regenera con: "
        ".venv/bin/python scripts/dump_schema.py > schema.sql"
    )


def test_cada_tabla_del_modelo_esta_en_el_ddl_y_ninguna_sobra():
    ddl = (RAIZ / "schema.sql").read_text()
    en_ddl = set(re.findall(r"CREATE TABLE (\w+)", ddl))
    assert en_ddl == set(Base.metadata.tables)


def test_las_reglas_de_dinero_del_modelo_llegan_al_ddl():
    """Las garantías que el diseño promete viven en el motor, no solo en Python."""
    ddl = (RAIZ / "schema.sql").read_text()
    # Dinero en céntimos enteros (BIGINT), nunca flotantes.
    columnas_de_dinero = re.findall(r"\t(monto|saldo_\w+) (\w+)", ddl)
    assert columnas_de_dinero
    assert {tipo for _, tipo in columnas_de_dinero} == {"BIGINT"}
    # El saldo no queda negativo salvo en la caja del sistema, y un asiento
    # nunca es cero ni negativo: lo hace cumplir el motor, no solo Python.
    assert "CHECK (tipo = 'sistema' OR saldo_disponible >= 0)" in ddl
    assert "CHECK (monto > 0)" in ddl
    # Idempotencia por restricción única; alias y DNI únicos.
    assert "CREATE UNIQUE INDEX ix_transactions_idempotency_key" in ddl
    assert "CREATE UNIQUE INDEX ix_users_alias ON users (alias)" in ddl
    assert "CREATE UNIQUE INDEX ix_users_dni ON users (dni)" in ddl


def test_el_script_de_volcado_se_ejecuta_solo():
    """El comando documentado funciona tal cual (sin depender de pytest)."""
    r = subprocess.run(
        [sys.executable, "scripts/dump_schema.py"],
        cwd=RAIZ,
        capture_output=True,
        text=True,
        check=False,
    )
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == (RAIZ / "schema.sql").read_text().strip()
