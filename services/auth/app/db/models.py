import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _uuid() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    dni: Mapped[str] = mapped_column(String(8), unique=True, index=True)
    nombres: Mapped[str] = mapped_column(String(120))
    apellidos: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), index=True)
    alias: Mapped[str] = mapped_column(String(60))
    # El PIN nunca se guarda en claro ni aparece en logs.
    pin_hash: Mapped[str] = mapped_column(String(255))
    pin_updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    kyc_status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Device(Base):
    """Teléfono vinculado a una cuenta. Sin vínculo, entrar exige OTP."""

    __tablename__ = "devices"
    __table_args__ = (UniqueConstraint("user_id", "device_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    trusted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Session(Base):
    """
    Sesión abierta. Se guarda el HASH del token, no el token: un volcado de la
    base no debe permitir entrar como nadie.
    """

    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128))
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class Lockout(Base):
    """
    Bloqueo vigente. `subject_type` separa los dos alcances que la app no puede
    llevar por sí sola: `dni` protege una cuenta en cualquier teléfono,
    `device` protege contra barrer muchas cuentas desde uno.
    """

    __tablename__ = "lockouts"
    __table_args__ = (UniqueConstraint("subject_type", "subject_value"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    subject_type: Mapped[str] = mapped_column(String(10), index=True)
    subject_value: Mapped[str] = mapped_column(String(128), index=True)
    level: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class LoginAttempt(Base):
    """
    Un registro por intento. Es lo que permite la ventana deslizante del
    contador por dispositivo: contar los fallos de los últimos N minutos en
    lugar de llevar un acumulado que un login correcto pondría a cero.
    """

    __tablename__ = "login_attempts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    dni: Mapped[str] = mapped_column(String(8), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    succeeded: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class OtpChallenge(Base):
    __tablename__ = "otp_challenges"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    purpose: Mapped[str] = mapped_column(String(20))  # recovery | device
    identifier: Mapped[str] = mapped_column(String(255), index=True)
    user_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    # El código es una credencial de un solo uso: se guarda hasheado.
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    cooldown_until: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts_left: Mapped[int] = mapped_column(Integer)
    resends_left: Mapped[int] = mapped_column(Integer)
    consumed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_reason: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class OtpTicket(Base):
    """
    Prueba de que un OTP se verificó. Lo exige `pin/reset` para que nadie
    cambie un PIN sin haber pasado por el código.
    """

    __tablename__ = "otp_tickets"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    purpose: Mapped[str] = mapped_column(String(20))
    identifier: Mapped[str] = mapped_column(String(255))
    user_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    # Limita `pin/check-current`, que sin tope sería un oráculo del PIN.
    checks_left: Mapped[int] = mapped_column(Integer, default=5)


class KycVerification(Base):
    """Veredicto y distancias. NUNCA las imágenes (decisión 4 del ADR-0002)."""

    __tablename__ = "kyc_verifications"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    verdict: Mapped[str] = mapped_column(String(20))
    document_valid: Mapped[bool] = mapped_column(Boolean, default=False)
    is_live: Mapped[bool] = mapped_column(Boolean, default=False)
    face_match: Mapped[bool] = mapped_column(Boolean, default=False)
    face_distance: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
