from datetime import timedelta
import pytest
from sqlalchemy import select, update, func
from app.db.models import (
    Account,
    KycVerification,
    LedgerEntry,
    Lockout,
    Transaction,
    User,
    utcnow,
)

PATHS = [
    "/v1/admin/" + part
    for part in ("registrations", "kyc", "operations", "reconciliation", "lockouts")
]


@pytest.mark.parametrize("path", PATHS)
async def test_admin_denies_anonymous_and_normal_holder(client, registrado, path):
    assert (await client.get(path)).status_code == 401
    assert (await client.get(path, headers=registrado.auth)).status_code == 403


async def grant(db, user_id):
    await db.execute(update(User).where(User.id == user_id).values(rol="admin"))
    await db.commit()


async def test_admin_queries_mask_data_and_do_not_write_money(
    client, registrado, db_de_client
):
    db = db_de_client
    await grant(db, registrado.user_id)
    c = (
        (await db.execute(select(Account).where(Account.user_id == registrado.user_id)))
        .scalars()
        .first()
    )
    r = await client.post(
        "/v1/topups",
        headers=registrado.auth,
        json={
            "cuenta_id": c.id,
            "monto_centimos": 12345,
            "idempotency_key": "admin-fixture-001",
        },
    )
    assert r.status_code == 201
    db.add(KycVerification(user_id=registrado.user_id, verdict="approved"))
    db.add(
        Lockout(
            subject_type="dni",
            subject_value=registrado.dni,
            level=1,
            locked_until=utcnow() + timedelta(hours=1),
        )
    )
    db.add(
        Lockout(
            subject_type="device",
            subject_value="expired-device",
            level=1,
            locked_until=utcnow() - timedelta(hours=1),
        )
    )
    await db.commit()
    before = await db.scalar(select(func.count()).select_from(Transaction))
    for path in PATHS:
        response = await client.get(path, headers=registrado.auth)
        assert response.status_code == 200, response.text
        assert registrado.dni not in response.text
        assert c.numero not in response.text
        assert "pin_hash" not in response.text and "face_distance" not in response.text
        assert response.headers["Cache-Control"] == "no-store"
        assert (
            await client.post(path, headers=registrado.auth, json={})
        ).status_code == 405
    operations = (await client.get(PATHS[2], headers=registrado.auth)).json()
    assert len(operations["items"]) == 2
    assert (
        sum(
            i["monto_centimos"]
            for i in operations["items"]
            if i["direccion"] == "credito"
        )
        == 12345
    )
    assert (await client.get(PATHS[3], headers=registrado.auth)).json()[
        "cuadra"
    ] is True
    lockouts = (await client.get(PATHS[4], headers=registrado.auth)).json()["items"]
    assert len(lockouts) == 1 and lockouts[0]["subject_type"] == "dni"
    assert await db.scalar(select(func.count()).select_from(Transaction)) == before
    # La revocación de rol tiene efecto con la misma sesión ya emitida.
    await db.execute(
        update(User).where(User.id == registrado.user_id).values(rol="titular")
    )
    await db.commit()
    assert (await client.get(PATHS[0], headers=registrado.auth)).status_code == 403


async def test_reconciliation_detects_opposite_account_errors(
    client, registrado, otro_registrado, db_de_client
):
    db = db_de_client
    await grant(db, registrado.user_id)
    accounts = (
        (await db.execute(select(Account).where(Account.tipo != "sistema")))
        .scalars()
        .all()
    )
    # Descuadres opuestos conservan suma global: deben señalarse ambos.
    accounts[0].saldo_contable = 100
    accounts[1].saldo_contable = -100
    await db.commit()
    r = await client.get("/v1/admin/reconciliation", headers=registrado.auth)
    assert r.status_code == 200
    assert r.json()["cuadra"] is False and len(r.json()["diferencias"]) == 2


async def test_operation_date_and_page_limits(client, registrado, db_de_client):
    await grant(db_de_client, registrado.user_id)
    assert (
        await client.get("/v1/admin/operations?day=2020-01-01", headers=registrado.auth)
    ).json()["items"] == []
    for params in ("limit=101", "limit=0", "offset=-1", "day=incorrecto"):
        assert (
            await client.get("/v1/admin/operations?" + params, headers=registrado.auth)
        ).status_code == 422


async def test_reconciliation_detects_offsetting_unbalanced_transactions(
    client, registrado, db_de_client
):
    db = db_de_client
    await grant(db, registrado.user_id)
    account = (
        (await db.execute(select(Account).where(Account.user_id == registrado.user_id)))
        .scalars()
        .first()
    )
    # Corrupción deliberada: el total global y el saldo coinciden, pero ninguna
    # operación cuadra por sí sola. Las rutas normales no pueden escribir esto.
    for direction in ("debito", "credito"):
        tx = Transaction(tipo="ajuste", idempotency_key="broken-tx-" + direction)
        db.add(tx)
        await db.flush()
        db.add(
            LedgerEntry(
                transaction_id=tx.id,
                account_id=account.id,
                direccion=direction,
                monto=100,
                moneda="PEN",
                saldo_posterior=0,
            )
        )
    await db.commit()
    response = await client.get("/v1/admin/reconciliation", headers=registrado.auth)
    assert response.status_code == 200
    assert response.json()["cuadra"] is False
    assert response.json()["diferencias"] == []
    assert len(response.json()["transacciones_descuadradas"]) == 2
