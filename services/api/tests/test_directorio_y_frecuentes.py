"""
Resolver un DNI es el endpoint más delicado del sprint.

Sin enmascarado y sin tope, la app sería un raspador de identidades: teclear
DNIs consecutivos devolvería el nombre de media población.
"""

import pytest

from app.api.v1.routers.directory import enmascarar
from app.services.rate_limit import CONSULTAS_MAXIMAS, VentanaDeslizante
from tests.conftest import PIN_DE_PRUEBA

INEXISTENTE = "99999999"
INEXISTENTE_ID = "00000000-0000-0000-0000-000000000000"


async def _resolver(client, titular, dni=INEXISTENTE):
    return await client.get(f"/v1/directory/resolve?dni={dni}", headers=titular.auth)


async def _agotar_por_directorio(client, titular):
    for _ in range(CONSULTAS_MAXIMAS):
        r = await _resolver(client, titular)
        assert r.status_code == 404


def _envio(origen, destino, clave="envio-cupo-001"):
    return {
        "cuenta_origen_id": origen,
        "cuenta_destino_id": destino,
        "monto_centimos": 100,
        "pin": PIN_DE_PRUEBA,
        "idempotency_key": clave,
    }


async def _cuenta_id(client, titular) -> str:
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"][0]["id"]


@pytest.mark.asyncio
async def test_resolver_devuelve_el_nombre_enmascarado_y_sus_cuentas(
    client, registrado, otro_registrado
):
    r = await _resolver(client, registrado, otro_registrado.dni)
    cuerpo = r.json()

    assert r.status_code == 200
    assert cuerpo["nombre_enmascarado"] == "L*** A*** Q***"
    assert "Luis" not in str(cuerpo)
    assert "Quispe" not in str(cuerpo)
    [cuenta] = cuerpo["cuentas"]
    assert cuenta["tipo"] == "ahorro"
    assert cuenta["moneda"] == "PEN"
    assert cuenta["numero_masked"].startswith("••••")
    assert len(cuenta["numero_masked"]) == 8
    assert cuenta["nombre"] is None
    assert set(cuenta) == {"cuenta_id", "tipo", "moneda", "numero_masked", "nombre"}


@pytest.mark.asyncio
async def test_resolver_lista_todas_las_cuentas_activas_en_orden(
    client, registrado, otro_registrado
):
    for clave, tipo, moneda in (("r-000001", "corriente", "USD"), ("r-000002", "sueldo", "PEN")):
        r = await client.post(
            "/v1/accounts",
            json={"tipo": tipo, "moneda": moneda, "nombre": "Secreto", "pin": PIN_DE_PRUEBA,
                  "idempotency_key": clave},
            headers=otro_registrado.auth,
        )
        assert r.status_code == 201
    cuentas = (await _resolver(client, registrado, otro_registrado.dni)).json()["cuentas"]
    assert [(c["tipo"], c["moneda"]) for c in cuentas] == [
        ("ahorro", "PEN"), ("corriente", "USD"), ("sueldo", "PEN")
    ]
    # El nombre que el otro le puso a sus cuentas no sale a terceros.
    assert all(c["nombre"] is None for c in cuentas)
    assert "Secreto" not in str(cuentas)


@pytest.mark.asyncio
async def test_resolver_el_propio_dni_lista_mis_cuentas_con_su_nombre(client, registrado):
    await client.post(
        "/v1/accounts",
        json={"tipo": "ahorro", "moneda": "USD", "nombre": "Viaje", "pin": PIN_DE_PRUEBA,
              "idempotency_key": "propia-01"},
        headers=registrado.auth,
    )
    r = await _resolver(client, registrado, registrado.dni)
    assert r.status_code == 200
    assert [c["nombre"] for c in r.json()["cuentas"]] == [None, "Viaje"]


async def _resolver_alias(client, titular, alias):
    return await client.get(
        "/v1/directory/resolve", params={"alias": alias}, headers=titular.auth
    )


@pytest.mark.asyncio
async def test_resolver_por_alias_encuentra_a_la_persona_sin_revelar_su_dni(
    client, registrado, otro_registrado
):
    por_dni = (await _resolver(client, registrado, otro_registrado.dni)).json()
    r = await _resolver_alias(client, registrado, "  @LUIS ")
    cuerpo = r.json()

    assert r.status_code == 200
    assert cuerpo["dni"] is None
    assert otro_registrado.dni not in str(cuerpo)
    assert cuerpo["alias"] == "@luis"
    assert cuerpo["nombre_enmascarado"] == "L*** A*** Q***"
    assert cuerpo["cuentas"] == por_dni["cuentas"]
    # Por DNI sí se repite: quien pregunta ya lo había escrito.
    assert por_dni["dni"] == otro_registrado.dni
    assert por_dni["alias"] == "@luis"


@pytest.mark.asyncio
async def test_resolver_el_propio_alias_lista_mis_cuentas(client, registrado):
    r = await _resolver_alias(client, registrado, "jenny")
    assert r.status_code == 200
    assert r.json()["dni"] == registrado.dni


@pytest.mark.asyncio
async def test_un_alias_inexistente_responde_igual_que_un_dni_inexistente(
    client, registrado
):
    por_alias = await _resolver_alias(client, registrado, "@nadie")
    por_dni = await _resolver(client, registrado)
    assert por_alias.status_code == por_dni.status_code == 404
    assert por_alias.json() == por_dni.json()


@pytest.mark.asyncio
async def test_buscar_por_alias_gasta_el_mismo_cupo(client, registrado):
    for _ in range(CONSULTAS_MAXIMAS):
        assert (await _resolver_alias(client, registrado, "@nadie")).status_code == 404
    assert (await _resolver(client, registrado)).status_code == 429


@pytest.mark.asyncio
async def test_una_consulta_malformada_se_rechaza_sin_gastar_cupo(client, registrado):
    for params in ({}, {"dni": INEXISTENTE, "alias": "@luis"}, {"alias": "12345678"},
                   {"alias": "ab"}, {"alias": "con espacio"}):
        r = await client.get("/v1/directory/resolve", params=params, headers=registrado.auth)
        assert r.status_code == 422, params
        assert r.json()["code"] == "INVALID_RECIPIENT_QUERY", params
    await _agotar_por_directorio(client, registrado)


@pytest.mark.asyncio
async def test_resolver_exige_sesion(client):
    r = await client.get(f"/v1/directory/resolve?dni={INEXISTENTE}")
    assert r.status_code == 401


@pytest.mark.asyncio
async def test_un_dni_malformado_es_rechazado_sin_gastar_cupo(client, registrado):
    for dni in ("1234", "abcdefgh", "123456789"):
        assert (await _resolver(client, registrado, dni)).status_code == 422
    # Si hubieran gastado cupo, el 21.º intento de abajo ya estaría limitado.
    await _agotar_por_directorio(client, registrado)


@pytest.mark.asyncio
async def test_un_dni_inexistente_responde_recipient_not_found(client, registrado):
    r = await _resolver(client, registrado)
    assert r.status_code == 404
    assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_un_destinatario_con_la_cuenta_bloqueada_no_se_resuelve(
    client, registrado, otro_registrado, db_de_client
):
    """Existe, pero no puede recibir: igual que si no existiera."""
    from sqlalchemy import update

    from app.db.models import Account

    ref = await _resolver(client, registrado)  # respuesta de un DNI inexistente

    await db_de_client.execute(
        update(Account)
        .where(Account.user_id == otro_registrado.user_id)
        .values(estado="bloqueada")
    )
    await db_de_client.commit()

    r = await _resolver(client, registrado, otro_registrado.dni)
    assert r.status_code == 404
    assert r.json() == ref.json()


@pytest.mark.asyncio
async def test_un_destinatario_con_la_cuenta_cerrada_no_se_resuelve(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import update

    from app.db.models import Account

    await db_de_client.execute(
        update(Account)
        .where(Account.user_id == otro_registrado.user_id)
        .values(estado="cerrada")
    )
    await db_de_client.commit()

    r = await _resolver(client, registrado, otro_registrado.dni)
    assert r.status_code == 404
    assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_una_cuenta_bloqueada_no_aparece_pero_las_demas_si(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import select, update
    from app.db.models import Account

    await client.post(
        "/v1/accounts",
        json={"tipo": "corriente", "moneda": "PEN", "pin": PIN_DE_PRUEBA,
              "idempotency_key": "bloq-0001"},
        headers=otro_registrado.auth,
    )
    await db_de_client.execute(
        update(Account)
        .where(Account.user_id == otro_registrado.user_id, Account.tipo == "ahorro")
        .values(estado="bloqueada")
    )
    await db_de_client.commit()
    cuentas = (await _resolver(client, registrado, otro_registrado.dni)).json()["cuentas"]
    assert [c["tipo"] for c in cuentas] == ["corriente"]


# --- Tope de consultas -------------------------------------------------------


@pytest.mark.asyncio
async def test_pasado_el_tope_de_consultas_responde_rate_limited(client, registrado):
    await _agotar_por_directorio(client, registrado)

    r = await _resolver(client, registrado)
    assert r.status_code == 429
    assert r.json()["code"] == "RATE_LIMITED"
    assert r.json()["retry_after_seconds"] > 0


@pytest.mark.asyncio
async def test_el_tope_cuenta_tambien_los_aciertos(client, registrado, otro_registrado):
    """Si solo contaran los 404, el atacante sondearía gratis a los que SÍ son clientes."""
    for _ in range(CONSULTAS_MAXIMAS):
        assert (await _resolver(client, registrado, otro_registrado.dni)).status_code == 200
    assert (await _resolver(client, registrado, otro_registrado.dni)).status_code == 429


@pytest.mark.asyncio
async def test_el_tope_es_por_usuario(client, registrado, otro_registrado):
    await _agotar_por_directorio(client, registrado)
    assert (await _resolver(client, otro_registrado)).status_code == 404


@pytest.mark.asyncio
async def test_agotar_el_cupo_por_directorio_lo_agota_para_transferir(
    client, registrado, otro_registrado
):
    origen = await _cuenta_id(client, registrado)
    await _agotar_por_directorio(client, registrado)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, INEXISTENTE_ID), headers=registrado.auth
    )
    assert r.status_code == 429
    assert r.json()["code"] == "RATE_LIMITED"


@pytest.mark.asyncio
async def test_agotar_el_cupo_por_transferir_lo_agota_para_el_directorio(
    client, registrado
):
    origen = await _cuenta_id(client, registrado)
    for i in range(CONSULTAS_MAXIMAS):
        r = await client.post(
            "/v1/transfers",
            json=_envio(origen, INEXISTENTE_ID, "envio-cupo-%03d" % i),
            headers=registrado.auth,
        )
        assert r.status_code == 404, r.text

    assert (await _resolver(client, registrado)).status_code == 429


@pytest.mark.asyncio
async def test_guardar_un_frecuente_comparte_el_mismo_cupo(client, registrado):
    await _agotar_por_directorio(client, registrado)

    r = await client.post(
        "/v1/beneficiaries",
        json={"cuenta_destino_id": INEXISTENTE_ID, "apodo": "X"},
        headers=registrado.auth,
    )
    assert r.status_code == 429


@pytest.mark.asyncio
async def test_transferir_sin_agotar_el_cupo_no_se_ve_afectado(
    client, registrado, otro_registrado
):
    """El tope no debe estorbar al uso normal."""
    origen = await _cuenta_id(client, registrado)
    r = await client.post(
        "/v1/topups",
        json={
            "cuenta_id": origen,
            "monto_centimos": 10_000,
            "pin": PIN_DE_PRUEBA,
            "idempotency_key": "recarga-cupo-1",
        },
        headers=registrado.auth,
    )
    assert r.status_code == 201
    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado)), headers=registrado.auth
    )
    assert r.status_code == 201, r.text


def test_la_ventana_libera_el_cupo_con_el_tiempo():
    ahora = [0.0]
    v = VentanaDeslizante(2, 10, reloj=lambda: ahora[0])
    assert v.consumir("u") == 0
    assert v.consumir("u") == 0
    assert v.consumir("u") > 0
    ahora[0] = 10.0
    assert v.consumir("u") == 0


def test_un_intento_rechazado_no_extiende_el_bloqueo():
    ahora = [0.0]
    v = VentanaDeslizante(1, 10, reloj=lambda: ahora[0])
    v.consumir("u")
    for t in (3.0, 6.0, 9.0):
        ahora[0] = t
        assert v.consumir("u") > 0  # insistir no debe anotarse
    ahora[0] = 10.0
    assert v.consumir("u") == 0


# --- Enmascarado -------------------------------------------------------------


@pytest.mark.parametrize(
    "nombres, apellidos, esperado",
    [
        ("Carlos Alberto", "Nina", "C*** A*** N***"),
        ("Madonna", "", "M***"),  # un solo nombre
        ("", "Nina", "N***"),
        ("", "", ""),  # cadena vacía: no es un IndexError
        ("   ", "  ", ""),  # solo espacios
        ("Carlos  Alberto", "Nina   Paz", "C*** A*** N*** P***"),  # espacios dobles
        ("  Carlos ", " Nina ", "C*** N***"),  # bordes
        ("Ángel", "Núñez", "Á*** N***"),  # tilde
        ("María", "ñahui", "M*** Ñ***"),  # minúscula inicial, se normaliza
        ("Juan", "D'Angelo", "J*** D***"),  # apóstrofo: no se parte
        ("Ana\tMaría", "Pérez\n", "A*** M*** P***"),  # otros blancos
    ],
)
def test_enmascarar_aguanta_nombres_raros(nombres, apellidos, esperado):
    assert enmascarar(nombres, apellidos) == esperado


def test_enmascarar_no_revela_mas_que_la_inicial():
    salida = enmascarar("Carlos Alberto", "Nina")
    assert "arlos" not in salida and "ina" not in salida


@pytest.mark.asyncio
async def test_un_nombre_raro_no_rompe_la_resolucion(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import update

    from app.db.models import User

    await db_de_client.execute(
        update(User).where(User.id == otro_registrado.user_id).values(nombres="", apellidos="")
    )
    await db_de_client.commit()

    r = await _resolver(client, registrado, otro_registrado.dni)
    assert r.status_code == 200
    assert r.json()["nombre_enmascarado"] == ""


# --- Frecuentes --------------------------------------------------------------


async def _guardar(client, titular, cuenta_id, apodo="Luis"):
    return await client.post(
        "/v1/beneficiaries",
        json={"cuenta_destino_id": cuenta_id, "apodo": apodo},
        headers=titular.auth,
    )


@pytest.mark.asyncio
async def test_guardar_dos_veces_la_misma_cuenta_actualiza_el_apodo(
    client, registrado, otro_registrado
):
    cid = await _cuenta_id(client, otro_registrado)
    for apodo in ("Luis", "Lucho"):
        assert (await _guardar(client, registrado, cid, apodo)).status_code == 201

    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()[
        "beneficiarios"
    ]
    assert len(lista) == 1
    b = lista[0]
    assert b["apodo"] == "Lucho"
    assert b["dni"] == otro_registrado.dni
    assert b["nombre_enmascarado"] == "L*** A*** Q***"
    assert b["cuenta"]["cuenta_id"] == cid
    assert b["cuenta"]["moneda"] == "PEN"
    assert b["cuenta"]["numero_masked"].startswith("••••")
    assert b["cuenta"]["nombre"] is None


@pytest.mark.asyncio
async def test_dos_cuentas_de_la_misma_persona_son_dos_frecuentes(
    client, registrado, otro_registrado
):
    primera = await _cuenta_id(client, otro_registrado)
    r = await client.post(
        "/v1/accounts",
        json={"tipo": "ahorro", "moneda": "USD", "pin": PIN_DE_PRUEBA, "idempotency_key": "fr-000001"},
        headers=otro_registrado.auth,
    )
    segunda = r.json()["id"]
    await _guardar(client, registrado, primera, "Luis soles")
    await _guardar(client, registrado, segunda, "Luis dólares")
    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()["beneficiarios"]
    assert [b["cuenta"]["moneda"] for b in lista] == ["USD", "PEN"]  # más reciente primero


@pytest.mark.asyncio
async def test_un_frecuente_cuya_cuenta_se_bloquea_queda_sin_cuenta(
    client, registrado, otro_registrado, db_de_client
):
    from sqlalchemy import update

    from app.db.models import Account

    cid = await _cuenta_id(client, otro_registrado)
    await _guardar(client, registrado, cid)
    await db_de_client.execute(update(Account).where(Account.id == cid).values(estado="cerrada"))
    await db_de_client.commit()
    [b] = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()["beneficiarios"]
    assert b["cuenta"] is None
    assert b["dni"] == otro_registrado.dni


@pytest.mark.asyncio
async def test_se_puede_guardar_una_cuenta_propia_pero_no_una_inexistente_ni_una_caja(
    client, registrado, db_de_client
):
    from app.services import accounts as accounts_service

    propia = await _cuenta_id(client, registrado)
    assert (await _guardar(client, registrado, propia, "Mi ahorro")).status_code == 201
    caja = await accounts_service.cuenta_de_sistema(db_de_client, "PEN")
    await db_de_client.commit()
    for cid in (INEXISTENTE_ID, caja.id):
        r = await _guardar(client, registrado, cid, "?")
        assert r.status_code == 404
        assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_los_beneficiarios_son_de_cada_titular(client, registrado, otro_registrado):
    await _guardar(client, registrado, await _cuenta_id(client, otro_registrado))
    r = await client.get("/v1/beneficiaries", headers=otro_registrado.auth)
    assert r.json()["beneficiarios"] == []


@pytest.mark.asyncio
async def test_eliminar_un_frecuente_y_no_poder_borrar_el_ajeno(
    client, registrado, otro_registrado
):
    await _guardar(client, registrado, await _cuenta_id(client, otro_registrado))
    bid = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()[
        "beneficiarios"
    ][0]["id"]

    # Otro titular intenta borrarlo: 204 (indistinguible de inexistente) y sigue ahí.
    r = await client.delete(f"/v1/beneficiaries/{bid}", headers=otro_registrado.auth)
    assert r.status_code == 204
    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()
    assert len(lista["beneficiarios"]) == 1

    r = await client.delete(f"/v1/beneficiaries/{bid}", headers=registrado.auth)
    assert r.status_code == 204
    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()
    assert lista["beneficiarios"] == []


@pytest.mark.asyncio
async def test_los_frecuentes_exigen_sesion(client):
    assert (await client.get("/v1/beneficiaries")).status_code == 401
    assert (await client.delete("/v1/beneficiaries/x")).status_code == 401


@pytest.mark.asyncio
async def test_guardar_el_mismo_frecuente_a_la_vez_no_da_500(
    client, registrado, otro_registrado
):
    """El doble toque en "guardar" es normal en móvil: todas deben acabar en 201."""
    import asyncio

    cid = await _cuenta_id(client, otro_registrado)
    respuestas = await asyncio.gather(
        *[
            client.post(
                "/v1/beneficiaries",
                json={"cuenta_destino_id": cid, "apodo": "Luis%d" % i},
                headers=registrado.auth,
            )
            for i in range(6)
        ]
    )
    assert [r.status_code for r in respuestas] == [201] * 6
    lista = (await client.get("/v1/beneficiaries", headers=registrado.auth)).json()
    assert len(lista["beneficiarios"]) == 1
