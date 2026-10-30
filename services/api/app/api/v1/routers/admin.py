"""Consultas operativas de solo lectura. El rol se valida en cada petición."""

from datetime import date, datetime, time, timedelta, timezone
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, case
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import current_admin
from app.db.base import get_session
from app.db.models import (
    Account,
    KycVerification,
    LedgerEntry,
    Lockout,
    Transaction,
    User,
    utcnow,
)

router = APIRouter(
    prefix="/v1/admin", tags=["Administración"], dependencies=[Depends(current_admin)]
)


def masked(value, visible=4):
    return "••••" + value[-visible:]


def window(day):
    start = datetime.combine(day, time.min, tzinfo=timezone.utc)
    return start, start + timedelta(days=1)


@router.get("/registrations")
async def registrations(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    rows = (
        await session.execute(
            select(User)
            .order_by(User.created_at.desc(), User.id)
            .offset(offset)
            .limit(limit)
        )
    ).scalars()
    # No nombres, correo, hashes, tokens ni DNI completo.
    return {
        "items": [
            {
                "id": u.id,
                "dni": masked(u.dni),
                "kyc_status": u.kyc_status,
                "created_at": u.created_at.isoformat(),
            }
            for u in rows
        ]
    }


@router.get("/kyc")
async def kyc(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    rows = await session.execute(
        select(KycVerification, User.dni)
        .join(User, User.id == KycVerification.user_id)
        .order_by(KycVerification.created_at.desc(), KycVerification.id)
        .offset(offset)
        .limit(limit)
    )
    return {
        "items": [
            {
                "id": k.id,
                "dni": masked(dni),
                "verdict": k.verdict,
                "created_at": k.created_at.isoformat(),
            }
            for k, dni in rows
        ]
    }


@router.get("/operations")
async def operations(
    day: date = Query(default_factory=lambda: utcnow().date(), le=date(9999, 12, 30)),
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    start, end = window(day)
    # Una fila por asiento: evita duplicar importes con joins de cuentas.
    rows = await session.execute(
        select(Transaction, LedgerEntry, Account.numero)
        .join(LedgerEntry, LedgerEntry.transaction_id == Transaction.id)
        .join(Account, Account.id == LedgerEntry.account_id)
        .where(Transaction.created_at >= start, Transaction.created_at < end)
        .order_by(Transaction.created_at.desc(), Transaction.id, LedgerEntry.id)
        .offset(offset)
        .limit(limit)
    )
    return {
        "day": day.isoformat(),
        "timezone": "UTC",
        "items": [
            {
                "transaction_id": t.id,
                "tipo": t.tipo,
                "estado": t.estado,
                "account": masked(numero),
                "direccion": e.direccion,
                "monto_centimos": e.monto,
                "moneda": e.moneda,
                "created_at": t.created_at.isoformat(),
            }
            for t, e, numero in rows
        ],
    }


@router.get("/reconciliation")
async def reconciliation(session: AsyncSession = Depends(get_session)):
    # Cuadre histórico por moneda, más comprobación del saldo de CADA cuenta:
    # dos errores opuestos no pueden cancelarse entre cuentas.
    signed = case(
        (LedgerEntry.direccion == "credito", LedgerEntry.monto),
        else_=-LedgerEntry.monto,
    )
    rows = await session.execute(
        select(
            Account.id,
            Account.numero,
            Account.moneda,
            Account.saldo_disponible,
            Account.saldo_contable,
            func.coalesce(func.sum(signed), 0),
        )
        .outerjoin(LedgerEntry, LedgerEntry.account_id == Account.id)
        .group_by(
            Account.id,
            Account.numero,
            Account.moneda,
            Account.saldo_disponible,
            Account.saldo_contable,
        )
    )
    differences = []
    for _, number, currency, available, book, entries in rows:
        if available != entries or book != entries:
            differences.append(
                {
                    "account": masked(number),
                    "moneda": currency,
                    "saldo_disponible_centimos": available,
                    "saldo_contable_centimos": book,
                    "libro_centimos": entries,
                }
            )
    totals = await session.execute(
        select(
            LedgerEntry.moneda,
            func.sum(
                case((LedgerEntry.direccion == "debito", LedgerEntry.monto), else_=0)
            ),
            func.sum(
                case((LedgerEntry.direccion == "credito", LedgerEntry.monto), else_=0)
            ),
        ).group_by(LedgerEntry.moneda)
    )
    currencies = [
        {
            "moneda": currency,
            "debitos_centimos": debit,
            "creditos_centimos": credit,
            "cuadra": debit == credit,
        }
        for currency, debit, credit in totals
    ]
    broken = await session.execute(
        select(LedgerEntry.transaction_id, LedgerEntry.moneda, func.sum(signed))
        .group_by(LedgerEntry.transaction_id, LedgerEntry.moneda)
        .having(func.sum(signed) != 0)
    )
    transactions = [
        {"transaction_id": tx, "moneda": currency, "diferencia_centimos": delta}
        for tx, currency, delta in broken
    ]
    return {
        "cuadra": not differences
        and not transactions
        and all(c["cuadra"] for c in currencies),
        "monedas": currencies,
        "diferencias": differences,
        "transacciones_descuadradas": transactions,
    }


@router.get("/lockouts")
async def lockouts(
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    session: AsyncSession = Depends(get_session),
):
    rows = (
        await session.execute(
            select(Lockout)
            .where(Lockout.locked_until > utcnow())
            .order_by(Lockout.locked_until.desc(), Lockout.id)
            .offset(offset)
            .limit(limit)
        )
    ).scalars()
    return {
        "items": [
            {
                "id": r.id,
                "subject_type": r.subject_type,
                "subject": masked(r.subject_value, visible=2),
                "level": r.level,
                "locked_until": r.locked_until.isoformat(),
            }
            for r in rows
        ]
    }
