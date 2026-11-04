"""Desembolso atómico de una solicitud aprobada; sin commit propio."""

from datetime import datetime, time, timezone
from decimal import Decimal, InvalidOperation
from sqlalchemy import select
from app.core.errors import ApiError, ErrorCode
from app.db.models import (
    Account,
    Loan,
    LoanApplication,
    LoanInstallment,
    Transaction,
    utcnow,
)
from app.services.accounts import cuenta_de_sistema
from app.services.ledger import Asiento, post
from app.services.loan_schedule import calcular_cronograma


async def disburse(
    session, *, user_id, application_id, account_id, idempotency_key, authorize=None
):
    # Una aprobación = un desembolso, incluso con claves diferentes concurrentes.
    application = (
        await session.execute(
            select(LoanApplication)
            .where(
                LoanApplication.id == application_id, LoanApplication.user_id == user_id
            )
            .with_for_update()
            .execution_options(populate_existing=True)
        )
    ).scalar_one_or_none()
    if application is None:
        raise ApiError(
            "LOAN_NOT_FOUND", "No encontramos esa solicitud.", status_code=404
        )
    existing = (
        await session.execute(select(Loan).where(Loan.application_id == application.id))
    ).scalar_one_or_none()
    if existing is not None:
        tx = await session.get(Transaction, existing.transaction_id)
        if tx.idempotency_key != idempotency_key or existing.account_id != account_id:
            raise ApiError(
                ErrorCode.IDEMPOTENCY_KEY_REUSED,
                "La solicitud ya fue desembolsada.",
                status_code=409,
            )
        if authorize is not None:
            await authorize()
        return existing, True
    if (
        application.estado != "aprobado"
        or application.approved_at is None
        or application.contrato_aceptado_at is None
    ):
        raise ApiError(
            "LOAN_NOT_APPROVED",
            "Se requiere aprobación y aceptación del contrato.",
            status_code=409,
        )
    account = (
        await session.execute(
            select(Account).where(Account.id == account_id, Account.user_id == user_id)
        )
    ).scalar_one_or_none()
    if account is None:
        raise ApiError(
            ErrorCode.ACCOUNT_NOT_FOUND, "No encontramos esa cuenta.", status_code=404
        )
    if account.moneda != application.moneda:
        raise ApiError(
            ErrorCode.CURRENCY_MISMATCH, "La cuenta debe tener la moneda del préstamo."
        )
    now = utcnow()
    try:
        schedule = calcular_cronograma(
            principal=application.principal,
            tea=Decimal(application.tea),
            meses=application.meses,
            fecha_desembolso=now.date(),
        )
    except (ValueError, InvalidOperation):
        raise ApiError(
            "INVALID_LOAN_TERMS",
            "Las condiciones aprobadas requieren revisión.",
            status_code=409,
        )
    if authorize is not None:
        await authorize()
    cash = await cuenta_de_sistema(session, application.moneda)
    tx, reused = await post(
        session,
        tipo="desembolso",
        asientos=[
            Asiento(cash.id, "debito", application.principal),
            Asiento(account.id, "credito", application.principal),
        ],
        idempotency_key=idempotency_key,
        fingerprint=f"solicitud={application.id}",
    )
    # Una clave global ajena, aun con importes iguales, no puede crear un préstamo.
    if reused:
        raise ApiError(
            ErrorCode.IDEMPOTENCY_KEY_REUSED,
            "La clave pertenece a otra operación.",
            status_code=409,
        )
    loan = Loan(
        application_id=application.id,
        account_id=account.id,
        transaction_id=tx.id,
        fecha_desembolso=now,
        tcea=str(schedule.tcea),
    )
    session.add(loan)
    await session.flush()
    session.add_all(
        [
            LoanInstallment(
                loan_id=loan.id,
                numero=c.numero,
                vencimiento=datetime.combine(
                    c.vencimiento, time.min, tzinfo=timezone.utc
                ),
                capital=c.capital,
                interes=c.interes,
                saldo_pendiente=c.saldo_pendiente,
            )
            for c in schedule.cuotas
        ]
    )
    await session.flush()
    return loan, False


async def loan_response(session, loan):
    rows = (
        (
            await session.execute(
                select(LoanInstallment)
                .where(LoanInstallment.loan_id == loan.id)
                .order_by(LoanInstallment.numero)
            )
        )
        .scalars()
        .all()
    )
    return {
        "loan_id": loan.id,
        "application_id": loan.application_id,
        "account_id": loan.account_id,
        "transaction_id": loan.transaction_id,
        "fecha_desembolso": loan.fecha_desembolso.date().isoformat(),
        "tcea": loan.tcea,
        "cuotas": [
            {
                "numero": c.numero,
                "vencimiento": c.vencimiento.date().isoformat(),
                "capital_centimos": c.capital,
                "interes_centimos": c.interes,
                "total_centimos": c.capital + c.interes,
                "saldo_pendiente_centimos": c.saldo_pendiente,
            }
            for c in rows
        ],
    }
