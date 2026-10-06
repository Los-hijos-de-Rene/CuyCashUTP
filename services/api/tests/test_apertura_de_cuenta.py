"""
HU05: al registrarse, el titular ya tiene dónde recibir dinero.

La apertura va en el MISMO COMMIT que el alta: una identidad sin cuenta es un
estado que luego nadie sabría reparar.
"""

import pytest
from sqlalchemy import func, select

from app.db.models import Account, User
from app.services import accounts
from app.services.accounts import cuenta_de_sistema, generar_numero

REGISTRO = {
    "dni": "70000001",
    "nombres": "Rosa",
    "apellidos": "Huaman",
    "email": "70000001@correo.pe",
    "pin": "839201",
}


@pytest.mark.asyncio
async def test_registrarse_abre_una_cuenta_de_ahorros_en_cero(client, registrado, otp_codes):
    r = await client.get("/v1/accounts", headers=registrado.auth)
    cuentas = r.json()["cuentas"]

    assert len(cuentas) == 1
    assert cuentas[0]["tipo"] == "ahorro"
    assert cuentas[0]["moneda"] == "PEN"
    assert cuentas[0]["estado"] == "activa"
    assert cuentas[0]["saldo_disponible"] == 0


@pytest.mark.asyncio
async def test_el_numero_de_cuenta_no_contiene_el_dni(client, registrado, otp_codes):
    """Un número de cuenta no debe filtrar el documento de su titular."""
    r = await client.get("/v1/accounts", headers=registrado.auth)
    numero = r.json()["cuentas"][0]["numero"]

    assert len(numero) == 14
    assert numero.startswith("191")
    assert registrado.dni not in numero


@pytest.mark.asyncio
async def test_registrarse_deja_una_cuenta_de_ahorros_en_la_base(
    client, registrado, otp_codes, db_de_client
):
    """Lo mismo que las dos pruebas de arriba, pero contra la base y no contra el router."""
    filas = (
        await db_de_client.execute(
            select(Account).where(Account.user_id == registrado.user_id)
        )
    ).scalars().all()

    assert len(filas) == 1
    assert (filas[0].tipo, filas[0].moneda, filas[0].estado) == ("ahorro", "PEN", "activa")
    assert (filas[0].saldo_disponible, filas[0].saldo_contable) == (0, 0)
    assert len(filas[0].numero) == 14
    assert filas[0].numero.startswith("191")
    assert registrado.dni not in filas[0].numero


@pytest.mark.asyncio
async def test_si_la_apertura_falla_no_queda_un_usuario_sin_cuenta(
    client, db_de_client, monkeypatch
):
    async def falla(session):
        raise RuntimeError("sin números libres")

    monkeypatch.setattr(accounts, "generar_numero", falla)

    # El cliente de pruebas propaga la excepción del servidor en vez de un 500.
    with pytest.raises(RuntimeError):
        await client.post(
            "/v1/auth/register",
            json=REGISTRO,
            headers={"X-Device-Id": "dev-atomicidad"},
        )

    await db_de_client.rollback()  # ver el estado confirmado, no uno cacheado
    usuarios = (await db_de_client.execute(select(func.count()).select_from(User))).scalar_one()
    cuentas = (await db_de_client.execute(select(func.count()).select_from(Account))).scalar_one()
    assert usuarios == 0
    assert cuentas == 0


@pytest.mark.asyncio
async def test_la_caja_del_sistema_se_crea_una_sola_vez(db):
    primera = await cuenta_de_sistema(db)
    segunda = await cuenta_de_sistema(db)

    assert primera.id == segunda.id
    assert primera.tipo == "sistema"
    assert primera.user_id is None


@pytest.mark.asyncio
async def test_dos_numeros_generados_no_colisionan(db):
    numeros = {await generar_numero(db) for _ in range(50)}
    assert len(numeros) == 50
