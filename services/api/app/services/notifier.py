
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

    async def send(
        self, destination: str, code: str, purpose: str
    ) -> None:
        ...


class LogNotifier:
    """
    Notificador utilizado para desarrollo local.

    El codigo OTP solo se registra cuando las
    herramientas de desarrollo estan habilitadas.

    Fuera de ese entorno, no se expone el codigo.
    """

    async def send(
        self, destination: str, code: str, purpose: str
    ) -> None:

        from app.services import dev_tools

        if not dev_tools.rutas_habilitadas():
            logger.warning(
                "OTP generado, pero el registro del codigo "
                "esta deshabilitado fuera del entorno local."
            )
            return

        logger.warning(
            "[OTP:%s] %s -> %s",
            purpose,
            destination,
            code,
        )

        dev_tools.registrar_otp(
            destination,
            code,
            purpose,
        )


class TelegramNotifier:
    """
    Notificador de OTP mediante Telegram.

    Se utiliza únicamente para demostraciones.

    Las fallas de Telegram no deben interrumpir
    el flujo de OTP.

    Los errores se registran sin exponer
    el token del bot.
    """

    def __init__(self, token: str, chat_id: str):
        self._url = (
            f"https://api.telegram.org/"
            f"bot{token}/sendMessage"
        )
        self._chat_id = chat_id

    async def send(
        self, destination: str, code: str, purpose: str
    ) -> None:

        texto = (
            f"CuyCash · código de verificación\n"
            f"{code}\n\n"
            f"Destino real: {destination}\n"
            f"Motivo: {purpose}"
        )

        try:
            async with httpx.AsyncClient(timeout=10) as client:

                respuesta = await client.post(
                    self._url,
                    json={
                        "chat_id": self._chat_id,
                        "text": texto,
                    },
                )

                # Detecta respuestas HTTP 4xx y 5xx.
                respuesta.raise_for_status()

        except httpx.HTTPStatusError as error:
            # No imprimir la URL ni el token del bot.
            logger.error(
                "No se pudo enviar el OTP por Telegram: HTTP %s",
                error.response.status_code,
            )

        except httpx.RequestError as error:
            # No imprimir el mensaje completo de la excepción.
            # Podría contener la URL con el token.
            logger.error(
                "No se pudo enviar el OTP por Telegram: %s",
                type(error).__name__,
            )

        # El flujo OTP continúa aunque Telegram falle.


def build_notifier() -> OtpNotifier:
    """
    Construye el notificador según la configuración.

    Si Telegram no está configurado correctamente,
    se utiliza LogNotifier.
    """

    if settings.OTP_NOTIFIER == "telegram":

        token: Optional[str] = settings.TELEGRAM_BOT_TOKEN
        chat_id: Optional[str] = settings.TELEGRAM_CHAT_ID

        if token and chat_id:
            return TelegramNotifier(
                token,
                chat_id,
            )

        logger.error(
            "OTP_NOTIFIER=telegram sin token/chat_id; "
            "se usa el log"
        )

    return LogNotifier()


notifier: OtpNotifier = build_notifier()
