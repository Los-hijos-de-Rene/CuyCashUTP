from fastapi import APIRouter, Depends, Response
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.deps import current_user, current_session_row
from app.db.base import get_session
from app.db.models import User, Session as SessionRow
from app.services.autorizacion import exigir_pin_de_operacion
from app.services.loan_disbursement import disburse, loan_response

router = APIRouter(prefix="/v1/loans", tags=["Préstamos"])


class DisbursementIn(BaseModel):
    account_id: str = Field(min_length=1, max_length=36)
    idempotency_key: str = Field(min_length=8, max_length=64)
    pin: str = Field(min_length=6, max_length=6)


@router.post("/applications/{application_id}/disbursement")
async def disbursement(
    application_id: str,
    payload: DisbursementIn,
    response: Response,
    user: User = Depends(current_user),
    login: SessionRow = Depends(current_session_row),
    session: AsyncSession = Depends(get_session),
):
    async def authorize():
        await exigir_pin_de_operacion(session, user, login.device_id, payload.pin)

    loan, reused = await disburse(
        session,
        user_id=user.id,
        application_id=application_id,
        account_id=payload.account_id,
        idempotency_key=payload.idempotency_key,
        authorize=authorize,
    )
    body = await loan_response(session, loan)
    await session.commit()
    response.status_code = 200 if reused else 201
    return body
