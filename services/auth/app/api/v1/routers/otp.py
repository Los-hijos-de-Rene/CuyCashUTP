from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import ApiError
from app.db.base import get_session
from app.schemas import ChallengeIn, ChallengeOut, VerifyIn
from app.services import otp

router = APIRouter(prefix="/v1/otp", tags=["OTP"])


@router.post("/challenges", response_model=ChallengeOut)
async def create_challenge(
    payload: ChallengeIn, session: AsyncSession = Depends(get_session)
):
    data = await otp.request_challenge(session, payload.purpose, payload.identifier)
    await session.commit()
    return data


@router.post("/challenges/{challenge_id}/verify")
async def verify_challenge(
    challenge_id: str, payload: VerifyIn, session: AsyncSession = Depends(get_session)
):
    try:
        ticket, meta = await otp.verify(session, challenge_id, payload.code)
    except ApiError:
        # El intento consumido y la cancelación se guardan AUNQUE la petición
        # falle. Si se revirtieran con la transacción, el contador nunca
        # bajaría y el reto admitiría intentos infinitos.
        await session.commit()
        raise
    await session.commit()
    return {"otp_ticket": ticket, **meta}


@router.post("/challenges/{challenge_id}/resend")
async def resend_challenge(
    challenge_id: str, session: AsyncSession = Depends(get_session)
):
    try:
        data = await otp.resend(session, challenge_id)
    except ApiError:
        await session.commit()  # la cancelación por reenvíos también persiste
        raise
    await session.commit()
    return data
