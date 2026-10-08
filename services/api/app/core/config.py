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

    # ---- Hash del PIN ----
    # Máximo de hashes argon2 simultáneos. Ver el cálculo en `core/security.py`.
    PIN_HASH_CONCURRENCY: int = 2

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
    # Si `/register` EXIGE un ticket de KYC aprobado. Apagado por defecto
    # porque en Render el microservicio aún no está desplegado y la app de
    # producción simula el KYC: encenderlo ahí dejaría a todos sin poder
    # registrarse. Se enciende en local (docker compose) y en producción el
    # día que el KYC esté arriba. Un ticket que SÍ se envía se valida siempre.
    KYC_REQUIRED: bool = False
    KYC_TICKET_TTL_SECONDS: int = 900
    # El KYC del plan gratuito se duerme y tarda ~30 s en despertar; mientras,
    # Render responde 502. El proxy reintenta durante este tiempo antes de
    # rendirse. Debe quedar por debajo del timeout de la app (70 s).
    KYC_WAKE_TIMEOUT_SECONDS: float = 60
    KYC_RETRY_DELAY_SECONDS: float = 5

    # ---- Herramientas de desarrollo (SOLO local) ----
    # Rutas /v1/dev/* para reiniciar la base y sembrar usuarios de prueba
    # desde el menú de desarrollo de la app. Solo existen con DEV_TOOLS=true,
    # una DEV_TOOLS_KEY no vacía y una base local (ver app/services/dev_tools.py).
    # Nunca se encienden en render.yaml.
    DEV_TOOLS: bool = False
    DEV_TOOLS_KEY: str = ""

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
