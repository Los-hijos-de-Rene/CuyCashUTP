"""Datos personales (solo lectura) y alias."""


async def test_me_devuelve_los_datos_del_titular(client, registrado):
    r = await client.get("/v1/me", headers=registrado.auth)

    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["dni"] == "71234567"
    assert cuerpo["nombres"] == "Jenny Marisol"
    assert cuerpo["apellidos"] == "Ruiz"
    assert cuerpo["alias"] == "@jenny"
    assert cuerpo["kyc_status"] == "pending"
    assert cuerpo["created_at"].endswith("Z")


async def test_me_nunca_devuelve_el_correo_completo(client, registrado):
    cuerpo = (await client.get("/v1/me", headers=registrado.auth)).json()

    assert "email" not in cuerpo
    assert cuerpo["email_masked"].endswith("@correo.pe")
    assert "71234567" not in cuerpo["email_masked"]


async def test_me_sin_sesion_es_401(client):
    r = await client.get("/v1/me")
    assert r.status_code == 401


async def test_alias_se_normaliza_y_persiste(client, registrado):
    r = await client.patch(
        "/v1/me/alias", json={"alias": "  Jenny_01 "}, headers=registrado.auth
    )

    assert r.status_code == 200
    assert r.json() == {"alias": "@jenny_01"}
    me = (await client.get("/v1/me", headers=registrado.auth)).json()
    assert me["alias"] == "@jenny_01"


async def test_alias_con_arroba_se_respeta(client, registrado):
    r = await client.patch("/v1/me/alias", json={"alias": "@j.r"}, headers=registrado.auth)
    assert r.json() == {"alias": "@j.r"}


async def test_alias_fuera_de_formato_se_rechaza(client, registrado):
    for malo in ["ab", "ñandú", "con espacio", "a" * 21, "@", ""]:
        r = await client.patch("/v1/me/alias", json={"alias": malo}, headers=registrado.auth)
        assert r.status_code == 422, malo
        assert r.json()["code"] == "INVALID_ALIAS", malo


async def test_alias_no_es_unico(client, registrado, otro_registrado):
    a = await client.patch("/v1/me/alias", json={"alias": "@igual"}, headers=registrado.auth)
    b = await client.patch(
        "/v1/me/alias", json={"alias": "@igual"}, headers=otro_registrado.auth
    )
    assert a.status_code == b.status_code == 200
