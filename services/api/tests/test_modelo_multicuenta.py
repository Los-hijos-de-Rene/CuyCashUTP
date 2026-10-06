"""
Restricciones de la base para la multicuenta.

Se prueban contra el esquema (fixture `db`) y no por HTTP: lo que importa es
que la BASE rechace lo inválido aunque un router futuro se olvide de validar.
"""

import pytest
from sqlalchemy.exc import IntegrityError

from app.db.models import Account, Beneficiary, User
from app.services import accounts


async def _titular(db, dni="70000009") -> User:
    u = User(
        dni=dni,
        nombres="Ana",
        apellidos="Rojas",
        email=f"{dni}@correo.pe",
        pin_hash="x",
        alias=f"@ana{dni}",
    )
    db.add(u)
    await db.flush()
    return u


@pytest.mark.asyncio
async def test_una_cuenta_sueldo_en_dolares_es_rechazada_por_la_base(db):
    u = await _titular(db)
    db.add(Account(user_id=u.id, numero="19111111111111", tipo="sueldo", moneda="USD"))
    with pytest.raises(IntegrityError):
        await db.flush()


@pytest.mark.asyncio
async def test_dos_cuentas_sueldo_del_mismo_titular_son_rechazadas_por_la_base(db):
    u = await _titular(db)
    db.add(Account(user_id=u.id, numero="19111111111111", tipo="sueldo", moneda="PEN"))
    await db.flush()
    db.add(Account(user_id=u.id, numero="19122222222222", tipo="sueldo", moneda="PEN"))
    with pytest.raises(IntegrityError):
        await db.flush()


@pytest.mark.asyncio
async def test_la_misma_clave_de_apertura_en_dos_titulares_se_acepta(db):
    a = await _titular(db, "70000010")
    b = await _titular(db, "70000011")
    db.add(Account(user_id=a.id, numero="19111111111111", idempotency_key="clave-0001"))
    db.add(Account(user_id=b.id, numero="19122222222222", idempotency_key="clave-0001"))
    await db.flush()  # no lanza: la unicidad es por titular


@pytest.mark.asyncio
async def test_abrir_cuenta_guarda_tipo_moneda_y_nombre(db):
    u = await _titular(db)
    c = await accounts.abrir_cuenta(
        db, u.id, tipo="corriente", moneda="USD", nombre="Viaje", idempotency_key="k-000001"
    )
    assert (c.tipo, c.moneda, c.nombre, c.idempotency_key) == (
        "corriente", "USD", "Viaje", "k-000001"
    )
    assert c.saldo_disponible == 0


@pytest.mark.asyncio
async def test_hay_una_caja_por_moneda(db):
    pen = await accounts.cuenta_de_sistema(db, "PEN")
    usd = await accounts.cuenta_de_sistema(db, "USD")
    assert pen.id != usd.id
    assert (pen.numero, pen.moneda) == ("19100000000000", "PEN")
    assert (usd.numero, usd.moneda) == ("19100000000001", "USD")
    assert (await accounts.cuenta_de_sistema(db, "USD")).id == usd.id


@pytest.mark.asyncio
async def test_generar_numero_nunca_da_el_de_una_caja(db, monkeypatch):
    # Forzar que el primer candidato sea el de la caja USD.
    digitos = iter("00000000001" + "12345678901")
    monkeypatch.setattr(accounts.secrets, "randbelow", lambda _: int(next(digitos)))
    assert await accounts.generar_numero(db) == "19112345678901"


@pytest.mark.asyncio
async def test_un_frecuente_apunta_a_una_cuenta_y_no_se_repite(db):
    u = await _titular(db, "70000012")
    otro = await _titular(db, "70000013")
    c1 = await accounts.abrir_cuenta(db, otro.id)
    c2 = await accounts.abrir_cuenta(db, otro.id, tipo="corriente")
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c1.id, apodo="A"))
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c2.id, apodo="B"))
    await db.flush()  # dos cuentas de la misma persona: válido
    db.add(Beneficiary(user_id=u.id, beneficiario_dni=otro.dni, cuenta_destino_id=c1.id, apodo="C"))
    with pytest.raises(IntegrityError):
        await db.flush()
