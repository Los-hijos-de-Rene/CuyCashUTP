from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "CuyCash Auth Service"

    # postgresql+asyncpg://usuario:clave@host:5432/base
    #
    # Acepta también sqlite+aiosqlite:///./cuycash.db, que levanta el servicio
    # sin Postgres ni Docker. El esquema es el mismo; Postgres es lo que va a
    # producción.
    DATABASE_URL: str = "postgresql+asyncpg://cuycash:cuycash@localhost:5432/cuycash"

    # ---- Sesiones ----
    # Token opaco con expiración deslizante: se renueva mientras haya
    # actividad. No hay refresh token (ver ADR-0002).
    SESSION_TTL_SECONDS: int = 60 * 60 * 24 * 30

    # ---- Bloqueo por identificador (el DNI) ----
    # Protege UNA cuenta contra intentos desde muchos teléfonos.
    IDENTIFIER_MAX_ATTEMPTS: int = 3
    IDENTIFIER_LOCKOUT_LEVELS_SECONDS: str = "900,3600,86400"  # 15 min, 1 h, 24 h

    # ---- Bloqueo por dispositivo ----
    # Protege contra barrer MUCHAS cuentas desde un teléfono. Umbral más alto
    # porque un teléfono compartido acumula fallos legítimos, y ventana
    # deslizante para que un login correcto no lo reinicie.
    DEVICE_MAX_ATTEMPTS: int = 10
    DEVICE_WINDOW_SECONDS: int = 900
    DEVICE_LOCKOUT_SECONDS: int = 900

    # ---- OTP ----
    OTP_TTL_SECONDS: int = 600
    OTP_COOLDOWN_SECONDS: int = 60
    OTP_MAX_ATTEMPTS: int = 3
    OTP_MAX_RESENDS: int = 3
    OTP_LOCKOUT_SECONDS: int = 900
    OTP_TICKET_TTL_SECONDS: int = 600

    # log | telegram — ver app/services/notifier.py
    OTP_NOTIFIER: str = "log"
    TELEGRAM_BOT_TOKEN: Optional[str] = None
    TELEGRAM_CHAT_ID: Optional[str] = None

    # ---- Proxy del KYC ----
    # La API key vive AQUÍ y no en la app: lo compilado en el binario es
    # extraíble (R1 del ADR-0001).
    KYC_BASE_URL: Optional[str] = None
    KYC_API_KEY: Optional[str] = None

    # Respuestas de duración uniforme: sin esto, que un DNI inexistente
    # responda más rápido reabre la enumeración de cuentas que la app cerró
    # con el mensaje genérico.
    UNIFORM_RESPONSE_SECONDS: float = 0.35

    @property
    def identifier_lockout_levels(self) -> list:
        return [int(v) for v in self.IDENTIFIER_LOCKOUT_LEVELS_SECONDS.split(",")]

    class Config:
        env_file = ".env"


settings = Settings()
