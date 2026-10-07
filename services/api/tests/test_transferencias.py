"""
HU06: envío inmediato entre personas de CuyCash, identificadas por DNI, y
recarga de saldo contra la caja del sistema.
"""

import pytest
from sqlalchemy import func, select

from app.core.config import settings
from app.db.models import Account, LedgerEntry, LoginAttempt, Transfer
from app.services import accounts as accounts_service
from app.services.ledger import Asiento, post
from app.services.rate_limit import CONSULTAS_MAXIMAS
from tests.conftest import PIN_DE_PRUEBA, registrar

PIN = PIN_DE_PRUEBA
PIN_MALO = "000000"


async def _cuenta_id(client, titular) -> str:
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"][0]["id"]


async def _saldo(client, titular) -> int:
    return (await client.get("/v1/accounts", headers=titular.auth)).json()["cuentas"][0][
        "saldo_disponible"
    ]


async def _con_saldo(client, titular, centimos: int) -> str:
    """Devuelve el id de la cuenta del titular, ya recargada."""
    cuenta_id = await _cuenta_id(client, titular)
    r = await client.post(
        "/v1/topups",
        json={
            "cuenta_id": cuenta_id,
            "monto_centimos": centimos,
            "pin": PIN,
            "idempotency_key": f"recarga-{titular.dni}",
        },
        headers=titular.auth,
    )
    assert r.status_code == 201, r.text
    return cuenta_id


INEXISTENTE_ID = "00000000-0000-0000-0000-000000000000"


def _envio(origen, destino, monto, clave, pin=PIN, motivo=None):
    return {
        "cuenta_origen_id": origen,
        "cuenta_destino_id": destino,
        "monto_centimos": monto,
        "motivo": motivo,
        "pin": pin,
        "idempotency_key": clave,
    }


@pytest.mark.asyncio
async def test_un_envio_debita_al_origen_y_acredita_al_destino(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _con_saldo(client, registrado, 100_000)

    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 25_000, "envio-001", motivo="Cena compartida"),
        headers=registrado.auth,
    )
    assert r.status_code == 201, r.text
    assert r.json()["monto_centimos"] == 25_000

    assert await _saldo(client, registrado) == 75_000
    assert await _saldo(client, otro_registrado) == 25_000

    fila = (await db_de_client.execute(select(Transfer))).scalars().one()
    assert fila.transaction_id == r.json()["transaction_id"]
    assert fila.motivo == "Cena compartida"
    assert fila.monto == 25_000


@pytest.mark.asyncio
async def test_reintentar_con_la_misma_clave_responde_200_y_no_cobra_dos_veces(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _con_saldo(client, registrado, 100_000)
    cuerpo = _envio(origen, await _cuenta_id(client, otro_registrado), 25_000, "envio-002")

    primera = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    segunda = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)

    assert primera.status_code == 201
    assert segunda.status_code == 200
    assert segunda.json()["transaction_id"] == primera.json()["transaction_id"]
    assert await _saldo(client, registrado) == 75_000
    # Una sola fila de intención: el reintento no duplica `transfers`.
    n = (await db_de_client.execute(select(func.count()).select_from(Transfer))).scalar_one()
    assert n == 1


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_monto_responde_409(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)

    await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-003"),
        headers=registrado.auth,
    )
    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 50_000, "envio-003"),
        headers=registrado.auth,
    )

    assert r.status_code == 409
    assert r.json()["code"] == "IDEMPOTENCY_KEY_REUSED"
    assert await _saldo(client, registrado) == 90_000


@pytest.mark.asyncio
async def test_la_misma_clave_con_otro_motivo_responde_409(
    client, otp_codes, registrado, otro_registrado
):
    """El motivo es lo único que el motor no ve: lo aporta la huella de la ruta."""
    origen = await _con_saldo(client, registrado, 100_000)

    await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-004", motivo="Cena"),
        headers=registrado.auth,
    )
    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-004", motivo="Alquiler"),
        headers=registrado.auth,
    )

    assert r.status_code == 409
    assert r.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_sin_saldo_suficiente_responde_insufficient_funds(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 5_000)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 50_000, "envio-005"),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "INSUFFICIENT_FUNDS"
    assert await _saldo(client, registrado) == 5_000
    assert await _saldo(client, otro_registrado) == 0


@pytest.mark.asyncio
async def test_enviar_a_la_misma_cuenta_es_rechazado(client, otp_codes, registrado):
    origen = await _con_saldo(client, registrado, 50_000)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, origen, 1_000, "envio-006"),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "SAME_ACCOUNT"


@pytest.mark.asyncio
async def test_un_destinatario_inexistente_responde_404(client, otp_codes, registrado):
    origen = await _con_saldo(client, registrado, 50_000)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, INEXISTENTE_ID, 1_000, "envio-007"),
        headers=registrado.auth,
    )
    assert r.status_code == 404
    assert r.json()["code"] == "RECIPIENT_NOT_FOUND"


@pytest.mark.asyncio
async def test_una_cuenta_ajena_se_trata_como_inexistente(
    client, otp_codes, registrado, otro_registrado
):
    ajena = await _cuenta_id(client, otro_registrado)

    r = await client.post(
        "/v1/transfers", json=_envio(ajena, await _cuenta_id(client, registrado), 1_000, "envio-008"),
        headers=registrado.auth,
    )
    assert r.status_code == 404
    assert r.json()["code"] == "ACCOUNT_NOT_FOUND"


@pytest.mark.asyncio
async def test_una_cuenta_origen_bloqueada_responde_account_blocked(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _con_saldo(client, registrado, 50_000)
    cuenta = await db_de_client.get(Account, origen)
    cuenta.estado = "bloqueada"
    await db_de_client.commit()

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-009"),
        headers=registrado.auth,
    )
    assert r.status_code == 409
    assert r.json()["code"] == "ACCOUNT_BLOCKED"


@pytest.mark.asyncio
async def test_un_destinatario_con_cuenta_bloqueada_no_recibe(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _con_saldo(client, registrado, 50_000)
    suya = await db_de_client.get(Account, await _cuenta_id(client, otro_registrado))
    suya.estado = "bloqueada"
    await db_de_client.commit()

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-010"),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "RECIPIENT_NOT_FOUND"
    assert await _saldo(client, registrado) == 50_000


@pytest.mark.asyncio
@pytest.mark.parametrize("monto", [0, -100, 200_001])
async def test_un_monto_fuera_de_rango_es_rechazado(
    client, otp_codes, registrado, otro_registrado, monto
):
    origen = await _con_saldo(client, registrado, 100_000)

    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), monto, f"envio-rango{monto}"),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "AMOUNT_OUT_OF_RANGE"


@pytest.mark.asyncio
async def test_un_monto_fuera_de_rango_no_gasta_intentos_de_pin(
    client, otp_codes, registrado, otro_registrado
):
    """El PIN va el último: una petición que iba a fallar igual no cuesta un intento."""
    origen = await _con_saldo(client, registrado, 100_000)

    for n in range(settings.IDENTIFIER_MAX_ATTEMPTS + 1):
        r = await client.post(
            "/v1/transfers",
            json=_envio(origen, await _cuenta_id(client, otro_registrado), 0, f"envio-sinpin{n}", pin=PIN_MALO),
            headers=registrado.auth,
        )
        assert r.json()["code"] == "AMOUNT_OUT_OF_RANGE"

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-sinpin-ok"),
        headers=registrado.auth,
    )
    assert r.status_code == 201


@pytest.mark.asyncio
async def test_el_monto_maximo_exacto_se_acepta(client, otp_codes, registrado, otro_registrado):
    origen = await _con_saldo(client, registrado, 200_000)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 200_000, "envio-maximo"),
        headers=registrado.auth,
    )
    assert r.status_code == 201


@pytest.mark.asyncio
async def test_un_pin_errado_no_mueve_dinero_y_descuenta_intentos(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)

    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-pin001", pin=PIN_MALO),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "INVALID_CREDENTIALS"
    assert r.json()["intentos_restantes"] == settings.IDENTIFIER_MAX_ATTEMPTS - 1
    assert await _saldo(client, registrado) == 100_000


@pytest.mark.asyncio
async def test_agotados_los_intentos_se_bloquea_y_ni_el_pin_correcto_pasa(
    client, otp_codes, registrado, otro_registrado
):
    """Bloqueo automático por intentos fallidos, también al transferir."""
    origen = await _con_saldo(client, registrado, 100_000)
    maximo = settings.IDENTIFIER_MAX_ATTEMPTS

    for n in range(maximo - 1):
        r = await client.post(
            "/v1/transfers",
            json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, f"envio-bloq{n}", pin=PIN_MALO),
            headers=registrado.auth,
        )
        assert r.json()["code"] == "INVALID_CREDENTIALS"

    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-bloq-ultimo", pin=PIN_MALO),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "IDENTIFIER_LOCKED"
    assert r.status_code == 423

    # Bloqueado: el PIN correcto tampoco mueve dinero.
    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-bloq-ok"),
        headers=registrado.auth,
    )
    assert r.json()["code"] == "IDENTIFIER_LOCKED"
    assert await _saldo(client, registrado) == 100_000


@pytest.mark.asyncio
async def test_los_fallos_al_entrar_y_al_enviar_son_el_mismo_contador(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)

    # Un fallo entrando...
    a = await client.post(
        "/v1/auth/authenticate",
        json={"identifier": registrado.dni, "pin": PIN_MALO},
        headers={"X-Device-Id": f"dev-{registrado.dni}"},
    )
    assert a.json()["code"] == "INVALID_CREDENTIALS"

    # ...ya cuenta contra el envío.
    r = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-mismo1", pin=PIN_MALO),
        headers=registrado.auth,
    )
    assert r.json()["intentos_restantes"] == settings.IDENTIFIER_MAX_ATTEMPTS - 2


@pytest.mark.asyncio
async def test_sin_sesion_no_se_mueve_dinero(client, otp_codes, registrado, otro_registrado):
    origen = await _cuenta_id(client, registrado)

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-nosesion")
    )
    assert r.status_code == 401
    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": origen, "monto_centimos": 1_000, "pin": PIN,
              "idempotency_key": "recarga-nosesion"},
    )
    assert r.status_code == 401


# ---------------------------------------------------------------- recargas


@pytest.mark.asyncio
async def test_una_recarga_acredita_y_deja_el_libro_cuadrado(
    client, otp_codes, registrado, db_de_client
):
    await _con_saldo(client, registrado, 30_000)

    assert await _saldo(client, registrado) == 30_000
    caja = (
        await db_de_client.execute(select(Account).where(Account.tipo == "sistema"))
    ).scalar_one()
    assert caja.saldo_disponible == -30_000
    suma = (
        await db_de_client.execute(
            select(func.sum(LedgerEntry.monto)).where(LedgerEntry.direccion == "debito")
        )
    ).scalar_one()
    assert suma == 30_000


@pytest.mark.asyncio
async def test_la_primera_recarga_crea_la_caja_y_las_siguientes_la_reutilizan(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    n = lambda: db_de_client.execute(
        select(func.count()).select_from(Account).where(Account.tipo == "sistema")
    )
    assert (await n()).scalar_one() == 0  # aún no existe: es el camino de la primera recarga

    await _con_saldo(client, registrado, 10_000)
    await _con_saldo(client, otro_registrado, 5_000)

    assert (await n()).scalar_one() == 1
    caja = (
        await db_de_client.execute(select(Account).where(Account.tipo == "sistema"))
    ).scalar_one()
    assert caja.saldo_disponible == -15_000


@pytest.mark.asyncio
async def test_si_otra_peticion_crea_la_caja_a_la_vez_la_sesion_sigue_sirviendo(
    db, monkeypatch
):
    """
    Carrera de la primera recarga: esta petición no ve la caja, otra la crea y
    el INSERT choca contra la UNIQUE. La sesión debe seguir utilizable (el
    savepoint deshace solo el insert) y devolver la caja ganadora.

    LIMITE: el choque se simula dentro de UNA sola sesión (la lectura inicial
    se ciega con monkeypatch); no hay dos transacciones reales compitiendo. Eso
    solo se prueba contra Postgres: pendiente para la suite `TEST_POSTGRES_URL`
    (marca `postgres`), junto a los tests de concurrencia del motor.
    """
    ganadora = Account(
        user_id=None, numero=accounts_service.NUMERO_SISTEMA, tipo="sistema",
        moneda="PEN", estado="activa", saldo_disponible=0, saldo_contable=0,
    )
    db.add(ganadora)
    await db.commit()

    real = accounts_service._buscar_caja
    llamadas = []

    async def ciega_la_primera_vez(session, moneda="PEN"):
        llamadas.append(1)
        return None if len(llamadas) == 1 else await real(session, moneda)

    monkeypatch.setattr(accounts_service, "_buscar_caja", ciega_la_primera_vez)

    caja = await accounts_service.cuenta_de_sistema(db)

    assert caja.id == ganadora.id
    assert len(llamadas) == 2  # hubo choque y relectura, no una lectura trivial
    # Sesión sana: sigue pudiendo leer y escribir en el libro.
    destino = Account(user_id=None, numero="19199999999999", tipo="sistema",
                      moneda="PEN", estado="activa", saldo_disponible=0, saldo_contable=0)
    db.add(destino)
    await db.flush()
    tx, reutilizada = await post(
        db, tipo="ajuste",
        asientos=[Asiento(caja.id, "debito", 100), Asiento(destino.id, "credito", 100)],
        idempotency_key="ajuste-tras-carrera", fingerprint="",
    )
    assert not reutilizada


@pytest.mark.asyncio
async def test_reintentar_una_recarga_con_la_misma_clave_no_acredita_dos_veces(
    client, otp_codes, registrado
):
    cuenta = await _cuenta_id(client, registrado)
    cuerpo = {"cuenta_id": cuenta, "monto_centimos": 10_000, "pin": PIN,
              "idempotency_key": "recarga-reintento"}

    a = await client.post("/v1/topups", json=cuerpo, headers=registrado.auth)
    b = await client.post("/v1/topups", json=cuerpo, headers=registrado.auth)

    assert (a.status_code, b.status_code) == (201, 200)
    assert a.json()["transaction_id"] == b.json()["transaction_id"]
    assert await _saldo(client, registrado) == 10_000


@pytest.mark.asyncio
async def test_la_misma_clave_de_recarga_con_otro_monto_responde_409(
    client, otp_codes, registrado
):
    cuenta = await _cuenta_id(client, registrado)
    base = {"cuenta_id": cuenta, "pin": PIN, "idempotency_key": "recarga-conflicto"}

    await client.post("/v1/topups", json={**base, "monto_centimos": 10_000}, headers=registrado.auth)
    r = await client.post("/v1/topups", json={**base, "monto_centimos": 20_000}, headers=registrado.auth)

    assert r.status_code == 409
    assert r.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
@pytest.mark.parametrize("monto", [0, 200_001])
async def test_una_recarga_fuera_de_rango_es_rechazada(client, otp_codes, registrado, monto):
    cuenta = await _cuenta_id(client, registrado)

    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta, "monto_centimos": monto, "pin": PIN,
              "idempotency_key": f"recarga-rango{monto}"},
        headers=registrado.auth,
    )
    assert r.json()["code"] == "AMOUNT_OUT_OF_RANGE"


@pytest.mark.asyncio
async def test_una_recarga_no_pide_pin_ni_gasta_intentos(client, otp_codes, registrado):
    """El depósito simulado mete dinero a la cuenta propia: no necesita la
    autorización del titular. Un `pin` que llegue se ignora y no cuenta como
    intento fallido."""
    cuenta = await _cuenta_id(client, registrado)

    r = await client.post(
        "/v1/topups",
        json={"cuenta_id": cuenta, "monto_centimos": 10_000, "pin": PIN_MALO,
              "idempotency_key": "recarga-sinpin"},
        headers=registrado.auth,
    )
    assert r.status_code == 201, r.text
    assert await _saldo(client, registrado) == 10_000


# ------------------------------------------------- correcciones de la ronda 1


@pytest.mark.asyncio
async def test_un_pin_errado_persiste_el_intento_fallido(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    """Ancla el commit previo al error: sin él, el fallo se pierde con la sesión."""
    origen = await _con_saldo(client, registrado, 100_000)

    await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 10_000, "envio-persist", pin=PIN_MALO),
        headers=registrado.auth,
    )

    fallos = (
        await db_de_client.execute(
            select(func.count()).select_from(LoginAttempt).where(
                LoginAttempt.dni == registrado.dni, LoginAttempt.succeeded.is_(False)
            )
        )
    ).scalar_one()
    assert fallos == 1


@pytest.mark.asyncio
async def test_reintentar_con_el_origen_ya_bloqueado_devuelve_la_original(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    """El antifraude bloquea tras el envío cuya respuesta se perdió: el reintento
    debe ver la transacción original, no 'tu cuenta no está activa'."""
    origen = await _con_saldo(client, registrado, 100_000)
    cuerpo = _envio(origen, await _cuenta_id(client, otro_registrado), 25_000, "envio-bloqueado")
    primera = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert primera.status_code == 201

    for titular_id in (origen, await _cuenta_id(client, otro_registrado)):
        cuenta = await db_de_client.get(Account, titular_id)
        cuenta.estado = "bloqueada"
    await db_de_client.commit()

    segunda = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert segunda.status_code == 200, segunda.text
    assert segunda.json()["transaction_id"] == primera.json()["transaction_id"]

    # Con la clave NUEVA, el bloqueo sí se aplica.
    otra = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 25_000, "envio-bloqueado-2"),
        headers=registrado.auth,
    )
    assert otra.json()["code"] == "ACCOUNT_BLOCKED"
    # Y con la clave vieja pero otros datos, 409 (no se disfraza de reintento).
    distinta = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 99, "envio-bloqueado"),
        headers=registrado.auth,
    )
    assert distinta.json()["code"] == "IDEMPOTENCY_KEY_REUSED"


@pytest.mark.asyncio
async def test_una_cuenta_ajena_sigue_siendo_404_aunque_la_clave_exista(
    client, otp_codes, registrado, otro_registrado
):
    origen = await _con_saldo(client, registrado, 100_000)
    await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-ajena"),
        headers=registrado.auth,
    )

    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, registrado), 1_000, "envio-ajena"),
        headers=otro_registrado.auth,
    )
    assert r.status_code == 404
    assert r.json()["code"] == "ACCOUNT_NOT_FOUND"


@pytest.mark.asyncio
async def test_si_se_dispara_el_bloqueo_del_dispositivo_el_codigo_es_device_locked(
    client, otp_codes, registrado, otro_registrado, monkeypatch
):
    origen = await _con_saldo(client, registrado, 100_000)
    monkeypatch.setattr(settings, "IDENTIFIER_MAX_ATTEMPTS", 100)
    monkeypatch.setattr(settings, "DEVICE_MAX_ATTEMPTS", 2)

    primera = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-dev-001", pin=PIN_MALO),
        headers=registrado.auth,
    )
    assert primera.json()["code"] == "INVALID_CREDENTIALS"

    segunda = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-dev-002", pin=PIN_MALO),
        headers=registrado.auth,
    )
    assert segunda.status_code == 423
    assert segunda.json()["code"] == "DEVICE_LOCKED"

    tercera = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-dev-003"),
        headers=registrado.auth,
    )
    assert tercera.json()["code"] == "DEVICE_LOCKED"


# --- El atajo de reintento no puede ser un oráculo del padrón -----------------
#
# Con `reintento` cierto el router concedía dos relajos: saltarse
# `ACCOUNT_BLOCKED` sobre la cuenta propia y buscar al destinatario SIN el
# filtro `estado == "activa"`. Como la detección miraba
# `Transaction.idempotency_key` sin acotar por titular, cualquier clave ya
# existente —incluida la que el propio curioso acababa de gastar en una
# recarga— los compraba. Y entonces 409 (existe, bloqueado) frente a 404 (no
# existe) distinguía lo que `directory._destinatario` se cuida de no revelar,
# sin mover dinero ni gastar intentos de bloqueo.


@pytest.mark.asyncio
async def test_la_clave_de_la_propia_recarga_no_revela_al_destinatario_bloqueado(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    origen = await _con_saldo(client, registrado, 100_000)  # gasta `recarga-<dni>`
    suya = await db_de_client.get(Account, await _cuenta_id(client, otro_registrado))
    suya.estado = "bloqueada"
    await db_de_client.commit()

    gastada = f"recarga-{registrado.dni}"
    bloqueado = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1, gastada),
        headers=registrado.auth,
    )
    inexistente = await client.post(
        "/v1/transfers", json=_envio(origen, INEXISTENTE_ID, 1, gastada),
        headers=registrado.auth,
    )

    assert bloqueado.status_code == inexistente.status_code == 404
    assert bloqueado.json()["code"] == "RECIPIENT_NOT_FOUND"
    assert bloqueado.json() == inexistente.json()


@pytest.mark.asyncio
async def test_la_clave_de_un_envio_a_otra_persona_tampoco_lo_revela(
    client, otp_codes, registrado, otro_registrado, db_de_client
):
    """La clave de un envío REAL desde la cuenta propia tampoco sirve de sonda:
    el reintento resuelve su destino desde la operación original, así que la
    respuesta no depende de la cuenta destino que traiga el payload."""
    tercero = await registrar(
        client, otp_codes, dni="33445566", nombres="Rosa Elena", apellidos="Paredes"
    )
    origen = await _con_saldo(client, registrado, 100_000)
    primera = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, tercero), 1_000, "envio-oraculo"),
        headers=registrado.auth,
    )
    assert primera.status_code == 201

    suya = await db_de_client.get(Account, await _cuenta_id(client, otro_registrado))
    suya.estado = "bloqueada"
    await db_de_client.commit()

    bloqueado = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-oraculo"),
        headers=registrado.auth,
    )
    inexistente = await client.post(
        "/v1/transfers", json=_envio(origen, INEXISTENTE_ID, 1_000, "envio-oraculo"),
        headers=registrado.auth,
    )

    assert bloqueado.status_code == inexistente.status_code == 409
    assert bloqueado.json()["code"] == "IDEMPOTENCY_KEY_REUSED"
    assert bloqueado.json() == inexistente.json()
    # Y el dinero no se movió otra vez.
    assert await _saldo(client, registrado) == 99_000


@pytest.mark.asyncio
async def test_un_reintento_no_gasta_presupuesto_de_consultas(
    client, otp_codes, registrado, otro_registrado
):
    """Quien tiene un envío con resultado desconocido debe poder preguntar "¿se
    cobró?" hasta saberlo. Si el reintento descontara presupuesto, un 429 lo
    dejaría sin respuesta para siempre y la app sellaría la clave."""
    origen = await _con_saldo(client, registrado, 100_000)
    cuerpo = _envio(origen, await _cuenta_id(client, otro_registrado), 25_000, "envio-presupuesto")
    primera = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert primera.status_code == 201

    for _ in range(CONSULTAS_MAXIMAS):
        await client.get(
            f"/v1/directory/resolve?dni={otro_registrado.dni}", headers=registrado.auth
        )

    nuevo = await client.post(
        "/v1/transfers",
        json=_envio(origen, await _cuenta_id(client, otro_registrado), 1_000, "envio-presupuesto-2"),
        headers=registrado.auth,
    )
    assert nuevo.status_code == 429, nuevo.text

    segunda = await client.post("/v1/transfers", json=cuerpo, headers=registrado.auth)
    assert segunda.status_code == 200, segunda.text
    assert segunda.json()["transaction_id"] == primera.json()["transaction_id"]
    assert await _saldo(client, registrado) == 75_000


@pytest.mark.asyncio
async def test_un_envio_de_un_centimo_no_destapa_el_nombre_completo(
    client, otp_codes, registrado, otro_registrado
):
    """`MONTO_MINIMO` es 1: si el historial del emisor diera el nombre completo,
    un céntimo al DNI de un desconocido valdría lo que `/directory/resolve`
    nunca da, y `/movements` no descuenta presupuesto."""
    origen = await _con_saldo(client, registrado, 100_000)
    r = await client.post(
        "/v1/transfers", json=_envio(origen, await _cuenta_id(client, otro_registrado), 1, "envio-centimo"),
        headers=registrado.auth,
    )
    assert r.status_code == 201, r.text

    mio = await client.get(f"/v1/accounts/{origen}/movements", headers=registrado.auth)
    assert mio.json()["movimientos"][0]["contraparte"] == "L*** A*** Q***"
    ficha = await client.get(
        f"/v1/movements/{r.json()['transaction_id']}", headers=registrado.auth
    )
    assert ficha.json()["contraparte"] == "L*** A*** Q***"

    # Quien RECIBIÓ sí ve el nombre completo: no eligió la operación.
    suya = await _cuenta_id(client, otro_registrado)
    recibido = await client.get(
        f"/v1/accounts/{suya}/movements", headers=otro_registrado.auth
    )
    assert recibido.json()["movimientos"][0]["contraparte"] == "jenny marisol ruiz"
