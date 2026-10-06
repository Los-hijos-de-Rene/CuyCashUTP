from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class RegisterIn(BaseModel):
    dni: str = Field(min_length=8, max_length=8, pattern=r"^\d{8}$")
    nombres: str = Field(min_length=1, max_length=120)
    apellidos: str = Field(min_length=1, max_length=120)
    email: EmailStr
    pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class AuthenticateIn(BaseModel):
    identifier: str
    pin: str


class SessionIn(BaseModel):
    """Abre sesión. `otp_ticket` solo hace falta si el teléfono no es de confianza."""

    pending_token: str
    otp_ticket: Optional[str] = None


class ResetPinIn(BaseModel):
    otp_ticket: str
    new_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class CheckPinIn(BaseModel):
    otp_ticket: str
    pin: str


class ChallengeIn(BaseModel):
    purpose: str = Field(pattern=r"^(recovery|device)$")
    identifier: str


class VerifyIn(BaseModel):
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class UserOut(BaseModel):
    id: str
    dni: str
    alias: str
    full_name: str


class ChallengeOut(BaseModel):
    challenge_id: str
    masked_email: str
    expires_at: datetime
    cooldown_until: datetime
    attempts_left: int
    resends_left: int


class AliasIn(BaseModel):
    # Holgado a propósito: la regla real (`@` + 3–20 de [a-z0-9_.]) la aplica
    # el router tras normalizar, para responder INVALID_ALIAS y no un 422 genérico.
    alias: str = Field(max_length=60)


class ChangePinIn(BaseModel):
    current_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class EnrollBiometricIn(BaseModel):
    pin: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class BiometricSessionIn(BaseModel):
    dni: str = Field(min_length=8, max_length=8, pattern=r"^\d{8}$")
    credential: str = Field(min_length=1, max_length=200)
