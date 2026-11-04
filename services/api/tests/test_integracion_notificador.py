
"""
APF3-C - Issue #100
Pruebas de integracion del notificador Telegram.
"""

import json

import httpx
import pytest

from app.core.config import settings
from app.services.notifier import (
    LogNotifier,
    TelegramNotifier,
    build_notifier,
)


@pytest.fixture
def telegram_mock(monkeypatch):
    estado = {
        "peticiones": [],
        "status": 200,
        "error": None,
    }

    async def upstream(request):
        estado["peticiones"].append(request)

        if estado["error"]:
            raise estado["error"](
                f"Error de conexion: {request.url}",
                request=request,
            )

        return httpx.Response(
            estado["status"],
            json={"ok": estado["status"] == 200},
        )

    cliente_original = httpx.AsyncClient

    def cliente_simulado(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(upstream)
        return cliente_original(*args, **kwargs)

    monkeypatch.setattr(
        httpx, "AsyncClient", cliente_simulado
    )

    return estado


async def test_int_t1_telegram_responde_200(telegram_mock):
    notificador = TelegramNotifier(
        "TOKEN_FICTICIO", "CHAT_PRUEBA"
    )

    await notificador.send(
        "usuario@test.com", "123456", "registro"
    )

    assert len(telegram_mock["peticiones"]) == 1

    peticion = telegram_mock["peticiones"][0]

    assert peticion.method == "POST"
    assert str(peticion.url) == (
        "https://api.telegram.org/"
        "botTOKEN_FICTICIO/sendMessage"
    )

    datos = json.loads(peticion.content)

    assert datos["chat_id"] == "CHAT_PRUEBA"
    assert "123456" in datos["text"]


@pytest.mark.parametrize(
    "tipo_error",
    [httpx.ConnectError, httpx.ReadTimeout],
)
async def test_int_t2_error_conexion_no_interrumpe(
    telegram_mock, tipo_error, caplog
):
    telegram_mock["error"] = tipo_error

    notificador = TelegramNotifier(
        "TOKEN_FICTICIO", "CHAT_PRUEBA"
    )

    await notificador.send(
        "usuario@test.com", "123456", "registro"
    )

    assert len(telegram_mock["peticiones"]) == 1
    assert "No se pudo enviar" in caplog.text


async def test_int_t3_telegram_responde_500(telegram_mock):
    telegram_mock["status"] = 500

    notificador = TelegramNotifier(
        "TOKEN_FICTICIO", "CHAT_PRUEBA"
    )

    # El error no debe interrumpir el flujo OTP.
    await notificador.send(
        "usuario@test.com", "123456", "registro"
    )

    assert len(telegram_mock["peticiones"]) == 1


@pytest.mark.parametrize(
    "token,chat_id",
    [
        (None, "CHAT_PRUEBA"),
        ("TOKEN_FICTICIO", None),
    ],
)
def test_int_t4_configuracion_incompleta(
    monkeypatch, token, chat_id
):
    monkeypatch.setattr(
        settings, "OTP_NOTIFIER", "telegram"
    )
    monkeypatch.setattr(
        settings, "TELEGRAM_BOT_TOKEN", token
    )
    monkeypatch.setattr(
        settings, "TELEGRAM_CHAT_ID", chat_id
    )

    notificador = build_notifier()

    assert isinstance(notificador, LogNotifier)


async def test_int_t5_token_no_aparece_en_logs(
    telegram_mock, caplog
):
    token = "TOKEN_SECRETO_DE_PRUEBA"
    telegram_mock["error"] = httpx.ConnectError

    notificador = TelegramNotifier(
        token, "CHAT_PRUEBA"
    )

    await notificador.send(
        "usuario@test.com", "123456", "registro"
    )

    assert token not in caplog.text

@pytest.mark.parametrize(
    "habilitado",
    [False, True],
)
async def test_int_t6_log_notifier_controlado_por_dev(
    monkeypatch, caplog, habilitado
):
    """
    INT-T6: verificar que los codigos OTP
    solo se registren con las herramientas
    de desarrollo habilitadas.
    """

    from collections import deque
    from app.services import dev_tools

    monkeypatch.setattr(
        dev_tools,
        "rutas_habilitadas",
        lambda: habilitado,
    )

    # Aislar el historial para esta prueba.
    monkeypatch.setattr(
        dev_tools,
        "_otps",
        deque(maxlen=10),
    )

    notificador = LogNotifier()

    await notificador.send(
        "usuario@test.com",
        "789456",
        "registro",
    )

    registros = dev_tools.ultimos_otps()

    if habilitado:
        assert len(registros) == 1
        assert registros[0].codigo == "789456"
        assert "789456" in caplog.text

    else:
        assert len(registros) == 0
        assert "789456" not in caplog.text
