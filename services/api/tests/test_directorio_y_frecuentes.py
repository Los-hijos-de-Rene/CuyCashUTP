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


async def _resolver(client, titular, dni=INEXISTENTE):
    return await client.get(f"/v1/directory/resolve?dni={dni}", headers=titular.auth)


async def _agotar_por_directorio(client, titular):
    for _ in range(CONSULTAS_MAXIMAS):
        r = await _resolver(client, titular)
        assert r.status_code == 404


def _envio(origen, dni, clave="envio-cupo-001"):
    return {
        "cuenta_origen_id": origen,
        "destinatario_dni": dni,
        "monto_centimos": 100,
        "pin": PIN_DE_PRUEBA,
        "idempotency_key": clave,
    }


async def _cuenta_id(client, titular) -> str:
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"][0]["id"]


@pytest.mark.asyncio
async def test_resolver_devuelve_el_nombre_enmascarado(
    client, registrado, otro_registrado
):
    r = await _resolver(client, registrado, otro_registrado.dni)
    cuerpo = r.json()

    assert r.status_code == 200
    assert cuerpo["nombre_enmascarado"] == "L*** A*** Q***"
    assert "Luis" not in str(cuerpo)
    assert "Quispe" not in str(cuerpo)
    assert cuerpo["cuenta_destino_numero_masked"].startswith("••••")


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
async def test_resolver_el_propio_dni_es_rechazado(client, registrado):
    r = await _resolver(client, registrado, registrado.dni)
    assert r.json()["code"] == "SELF_TRANSFER"


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
        "/v1/transfers", json=_envio(origen, INEXISTENTE), headers=registrado.auth
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
            json=_envio(origen, INEXISTENTE, "envio-cupo-%03d" % i),
            headers=registrado.auth,
        )
        assert r.status_code == 404, r.text

    assert (await _resolver(client, registrado)).status_code == 429


@pytest.mark.asyncio
async def test_guardar_un_frecuente_comparte_el_mismo_cupo(client, registrado):
    await _agotar_por_directorio(client, registrado)

    r = await client.post(
        "/v1/beneficiaries",
        json={"dni": INEXISTENTE, "apodo": "X"},
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
        "/v1/transfers", json=_envio(origen, otro_registrado.dni), headers=registrado.auth
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


@pytest.mark.asyncio
async def test_guardar_dos_veces_el_mismo_dni_actualiza_el_apodo(
    client, registrado, otro_registrado
):
    for apodo in ("Luis", "Lucho"):
        r = await client.post(
            "/v1/beneficiaries",
            json={"dni": otro_registrado.dni, "apodo": apodo},
            headers=registrado.auth,
        )
        assert r.status_code == 201

    r = await client.get("/v1/beneficiaries", headers=registrado.auth)
    lista = r.json()["beneficiarios"]
    assert len(lista) == 1
    assert lista[0]["apodo"] == "Lucho"
    assert lista[0]["nombre_enmascarado"] == "L*** A*** Q***"


@pytest.mark.asyncio
async def test_los_beneficiarios_son_de_cada_titular(client, registrado, otro_registrado):
    await client.post(
        "/v1/beneficiaries",
        json={"dni": otro_registrado.dni, "apodo": "Luis"},
        headers=registrado.auth,
    )
    r = await client.get("/v1/beneficiaries", headers=otro_registrado.auth)
    assert r.json()["beneficiarios"] == []


@pytest.mark.asyncio
async def test_no_se_puede_guardar_a_uno_mismo_ni_a_un_inexistente(client, registrado):
    r = await client.post(
        "/v1/beneficiaries", json={"dni": registrado.dni, "apodo": "Yo"}, headers=registrado.auth
    )
    assert r.json()["code"] == "SELF_TRANSFER"
    r = await client.post(
        "/v1/beneficiaries", json={"dni": INEXISTENTE, "apodo": "?"}, headers=registrado.auth
    )
    assert r.status_code == 404
    assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_eliminar_un_frecuente_y_no_poder_borrar_el_ajeno(
    client, registrado, otro_registrado
):
    await client.post(
        "/v1/beneficiaries",
        json={"dni": otro_registrado.dni, "apodo": "Luis"},
        headers=registrado.auth,
    )
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
