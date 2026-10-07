"""Alias único: cómo se genera en el registro y su regla."""

import pytest

from app.services import alias as alias_svc
from tests.conftest import PIN_DE_PRUEBA


async def _alta(client, dni: str, nombres: str):
    r = await client.post(
        "/v1/auth/register",
        json={
            "dni": dni,
            "nombres": nombres,
            "apellidos": "Prueba",
            "email": f"{dni}@correo.pe",
            "pin": PIN_DE_PRUEBA,
        },
        headers={"X-Device-Id": f"dev-{dni}"},
    )
    assert r.status_code == 201, r.text
    return r.json()["alias"]


@pytest.mark.parametrize(
    "nombres, base",
    [
        ("jenny marisol", "jenny"),
        ("josé", "jose"),
        ("ñique", "nique"),
        ("li", "cuyli"),
        ("", "cuy"),
        ("123", "cuy123"),
        ("maximilianoalejandro", "maximilianoaleja"),
    ],
)
def test_la_base_sale_del_primer_nombre_sin_tildes(nombres, base):
    assert alias_svc.base_desde_nombre(nombres) == base
    assert alias_svc.es_valido(f"@{base}")


def test_la_regla_exige_al_menos_una_letra():
    assert not alias_svc.es_valido("@12345678")
    assert not alias_svc.es_valido("@1.2_3")
    assert alias_svc.es_valido("@a1234567")
    assert alias_svc.es_valido("@j.r")


async def test_dos_homonimos_reciben_alias_distintos(client):
    primero = await _alta(client, "70000001", "Juan Carlos")
    segundo = await _alta(client, "70000002", "Juan José")

    assert primero == "@juan"
    assert segundo != primero
    assert segundo.startswith("@juan")
    assert alias_svc.es_valido(segundo)


async def test_un_nombre_con_tilde_da_un_alias_valido(client):
    alias = await _alta(client, "70000003", "José")
    assert alias == "@jose"


async def test_el_alias_generado_nunca_contiene_el_dni(client):
    alias = await _alta(client, "70000004", "Li")
    assert alias_svc.es_valido(alias)
    assert "70000004" not in alias


async def test_si_otro_registro_se_lleva_el_alias_se_pide_otro(client, monkeypatch):
    """Simula la carrera: `libre` sugiere un alias que ya se tomó entre la
    consulta y el INSERT. La UNIQUE salta y el alta reintenta con otro."""
    await _alta(client, "70000005", "Rosa")
    sugerencias = iter(["@rosa", "@rosa77"])

    async def libre_con_carrera(session, nombres):
        return next(sugerencias)

    monkeypatch.setattr(alias_svc, "libre", libre_con_carrera)
    assert await _alta(client, "70000006", "Rosa") == "@rosa77"
