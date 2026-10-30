import asyncio
import pytest
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import async_sessionmaker
from app.db.models import (
    Account,
    LedgerEntry,
    Loan,
    LoanApplication,
    LoanInstallment,
    Transaction,
    User,
    utcnow,
)
from app.services.loan_disbursement import disburse
from conftest import PIN_DE_PRUEBA


async def application(db, user_id, **changes):
    values = dict(
        user_id=user_id,
        estado="aprobado",
        principal=10001,
        moneda="PEN",
        meses=3,
        tea="0.12",
        approved_at=utcnow(),
        contrato_aceptado_at=utcnow(),
    )
    values.update(changes)
    row = LoanApplication(**values)
    db.add(row)
    await db.commit()
    return row


async def account(db, user_id):
    return (
        (await db.execute(select(Account).where(Account.user_id == user_id)))
        .scalars()
        .first()
    )


def body(account_id, key="loan-disburse-001"):
    return dict(account_id=account_id, idempotency_key=key, pin=PIN_DE_PRUEBA)


async def test_disbursement_retry_preserves_money_and_schedule(
    client, registrado, db_de_client
):
    a = await application(db_de_client, registrado.user_id)
    c = await account(db_de_client, registrado.user_id)
    path = f"/v1/loans/applications/{a.id}/disbursement"
    first = await client.post(path, headers=registrado.auth, json=body(c.id))
    assert first.status_code == 201, first.text
    c.estado = "bloqueada"
    await db_de_client.commit()
    again = await client.post(path, headers=registrado.auth, json=body(c.id))
    assert again.status_code == 200
    assert first.json() == again.json()
    cuotas = first.json()["cuotas"]
    assert sum(c["capital_centimos"] for c in cuotas) == 10001
    assert len(cuotas) == 3 and cuotas[-1]["saldo_pendiente_centimos"] == 0
    await db_de_client.refresh(c)
    assert c.saldo_disponible == c.saldo_contable == 10001
    assert await db_de_client.scalar(select(func.count()).select_from(Loan)) == 1
    assert await db_de_client.scalar(select(func.count()).select_from(LedgerEntry)) == 2
    conflict = await client.post(
        path, headers=registrado.auth, json=body(c.id, "loan-another-key")
    )
    assert conflict.status_code == 409


@pytest.mark.parametrize(
    "changes",
    [
        {"estado": "pendiente"},
        {"estado": "rechazado"},
        {"approved_at": None},
        {"contrato_aceptado_at": None},
        {"tea": "NaN"},
    ],
)
async def test_unapproved_or_invalid_terms_do_not_move_money(
    client, registrado, db_de_client, changes
):
    a = await application(db_de_client, registrado.user_id, **changes)
    c = await account(db_de_client, registrado.user_id)
    r = await client.post(
        f"/v1/loans/applications/{a.id}/disbursement",
        headers=registrado.auth,
        json=body(c.id),
    )
    assert r.status_code == 409
    assert await db_de_client.scalar(select(func.count()).select_from(Transaction)) == 0
    assert (
        await db_de_client.scalar(select(func.count()).select_from(LoanInstallment))
        == 0
    )


async def test_ownership_currency_and_pin(
    client, registrado, otro_registrado, db_de_client
):
    a = await application(db_de_client, registrado.user_id)
    mine = await account(db_de_client, registrado.user_id)
    other = await account(db_de_client, otro_registrado.user_id)
    path = f"/v1/loans/applications/{a.id}/disbursement"
    assert (
        await client.post(path, headers=otro_registrado.auth, json=body(other.id))
    ).status_code == 404
    assert (
        await client.post(path, headers=registrado.auth, json=body(other.id))
    ).status_code == 404
    mine.moneda = "USD"
    await db_de_client.commit()
    assert (
        await client.post(path, headers=registrado.auth, json=body(mine.id))
    ).status_code == 400
    mine.moneda = "PEN"
    await db_de_client.commit()
    wrong = body(mine.id)
    wrong["pin"] = "111111"
    assert (
        await client.post(path, headers=registrado.auth, json=wrong)
    ).status_code == 403
    assert await db_de_client.scalar(select(func.count()).select_from(Transaction)) == 0


async def seed(db):
    u = User(
        dni="12345678",
        nombres="Ana",
        apellidos="Test",
        email="ana@example.test",
        alias="ana",
        pin_hash="hash",
    )
    db.add(u)
    await db.flush()
    c = Account(user_id=u.id, numero="19112345678901", tipo="ahorro", moneda="PEN")
    db.add(c)
    await db.flush()
    a = await application(db, u.id)
    return u.id, c.id, a.id


async def test_failure_after_ledger_rolls_back_everything(db_engine, monkeypatch):
    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as db:
        uid, cid, aid = await seed(db)
    import app.services.loan_disbursement as service

    real = service.post

    async def fail(*args, **kwargs):
        await real(*args, **kwargs)
        raise RuntimeError("fallo después del libro")

    monkeypatch.setattr(service, "post", fail)
    async with maker() as db:
        with pytest.raises(RuntimeError):
            await disburse(
                db,
                user_id=uid,
                application_id=aid,
                account_id=cid,
                idempotency_key="rollback-loan-001",
            )
        await db.rollback()
    async with maker() as db:
        assert await db.scalar(select(func.count()).select_from(Transaction)) == 0
        assert await db.scalar(select(func.count()).select_from(LedgerEntry)) == 0
        assert (await db.get(Account, cid)).saldo_disponible == 0


@pytest.mark.postgres
@pytest.mark.parametrize("same_key", [True, False])
async def test_concurrent_disbursement_only_credits_once(db_engine, same_key):
    if db_engine.dialect.name != "postgresql":
        pytest.skip("Requiere bloqueo de filas PostgreSQL")
    maker = async_sessionmaker(db_engine, expire_on_commit=False)
    async with maker() as db:
        uid, cid, aid = await seed(db)

    async def run(key):
        async with maker() as db:
            try:
                result = await disburse(
                    db,
                    user_id=uid,
                    account_id=cid,
                    application_id=aid,
                    idempotency_key=key,
                )
                await db.commit()
                return result[1]
            except Exception as error:
                await db.rollback()
                return error

    results = await asyncio.gather(
        run("concurrent-loan-1"),
        run("concurrent-loan-1" if same_key else "concurrent-loan-2"),
    )
    from app.core.errors import ApiError

    if same_key:
        assert sorted(results) == [False, True]
    else:
        assert (
            sum(isinstance(r, ApiError) and r.status_code == 409 for r in results) == 1
        ), results
        assert results.count(False) == 1
    async with maker() as db:
        assert (await db.get(Account, cid)).saldo_disponible == 10001
        assert await db.scalar(select(func.count()).select_from(Loan)) == 1
        assert await db.scalar(select(func.count()).select_from(LedgerEntry)) == 2
        assert await db.scalar(select(func.count()).select_from(LoanInstallment)) == 3
