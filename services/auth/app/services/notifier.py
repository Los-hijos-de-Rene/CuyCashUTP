import logging
from typing import Optional, Protocol

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class OtpNotifier(Protocol):
    """
    Por dónde sale el código.

    Es una interfaz y no un proveedor a propósito (decisión 1 del ADR-0002):
    el canal cambia entre desarrollo, demo y producción, y esa elección debe
    ser configuración, no arquitectura.
    """

    async def send(self, destination: str, code: str, purpose: str) -> None: ...


class LogNotifier:
    """
    Desarrollo: el código va al log del servidor. Sin cuentas, sin dominios y
    sin riesgo de confundirlo con producción.
    """

    async def send(self, destination: str, code: str, purpose: str) -> None:
        logger.warning("[OTP:%s] %s -> %s", purpose, destination, code)


class TelegramNotifier:
    """
    Demostración en vivo: el código llega a un teléfono a la vista de todos,
    sin depender de que el correo no caiga en spam durante la exposición.

    NO es equivalente al correo: cambia el factor de posesión (un chat no es la
    casilla que el titular registró) y, si todos los códigos caen en el mismo
    chat, cualquier asistente ve el de cualquiera. Solo para demo.
    """

    def __init__(self, token: str, chat_id: str):
        self._url = f"https://api.telegram.org/bot{token}/sendMessage"
        self._chat_id = chat_id

    async def send(self, destination: str, code: str, purpose: str) -> None:
        texto = (
            f"CuyCash · código de verificación\n"
            f"{code}\n\n"
            f"Destino real: {destination}\nMotivo: {purpose}"
        )
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                await client.post(
                    self._url, json={"chat_id": self._chat_id, "text": texto}
                )
        except httpx.HTTPError as error:
            # Que falle el aviso no debe tumbar el flujo: el reto ya existe y
            # el usuario puede pedir un reenvío.
            logger.error("No se pudo enviar el OTP por Telegram: %s", error)


def build_notifier() -> OtpNotifier:
    if settings.OTP_NOTIFIER == "telegram":
        token: Optional[str] = settings.TELEGRAM_BOT_TOKEN
        chat_id: Optional[str] = settings.TELEGRAM_CHAT_ID
        if token and chat_id:
            return TelegramNotifier(token, chat_id)
        logger.error("OTP_NOTIFIER=telegram sin token/chat_id; se usa el log")
    return LogNotifier()


notifier: OtpNotifier = build_notifier()
