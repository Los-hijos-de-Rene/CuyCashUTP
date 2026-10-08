"""
Herramientas de desarrollo LOCAL: reiniciar la base y sembrar usuarios de prueba.

Existen porque en local hay un solo teléfono y un solo DNI real: sin usuarios
ficticios no hay a quién enviar dinero, y volver a probar el registro exige
vaciar la base. Las usan el script `scripts/dev.py` (terminal) y las rutas
`/v1/dev/*` (menú de desarrollo de la app en el flavor `local`).

Son DESTRUCTIVAS. Nunca deben poder correr contra Neon/Render. El cerrojo es una
lista de PERMITIDOS: base local (SQLite o los hosts de abajo) y, para las rutas
HTTP, además `DEV_TOOLS=true` con una `DEV_TOOLS_KEY` no vacía.
"""

import os
from collections import deque
from dataclasses import dataclass
from datetime import datetime
from typing import Deque, List

from sqlalchemy import select
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import ahash_pin
from app.db import models  # noqa: F401  (registra las tablas en Base.metadata)
from app.db.base import Base
from app.db.models import User, utcnow
from app.services import accounts
from app.services.ledger import Asiento, post

# `db` es el nombre del servicio de Postgres en docker-compose.
HOSTS_LOCALES = {"localhost", "127.0.0.1", "db"}

# PIN de TODOS los usuarios de prueba. Pasa las reglas de `pin_is_valid`.
PIN_DE_PRUEBA = "258036"

# Saldo inicial en céntimos (S/ 1,000.00).
SALDO_INICIAL = 100_000


@dataclass(frozen=True)
class UsuarioDePrueba:
    dni: str
    nombres: str
    apellidos: str
    alias: str
    email: str


USUARIOS_DE_PRUEBA = (
    UsuarioDePrueba("11111111", "Ana", "Prueba", "@ana", "ana@prueba.local"),
    UsuarioDePrueba("22222222", "Luis", "Prueba", "@luis", "luis@prueba.local"),
)


def es_base_local(url: str) -> bool:
    destino = make_url(url)
    if destino.get_backend_name().lower() == "sqlite":
        return True
    return (destino.host or "").lower() in HOSTS_LOCALES


def es_produccion() -> bool:
    return os.getenv("ENV", "").lower() == "production"


def puede_correr() -> bool:
    """El cerrojo del script de terminal: base local y no producción."""
    return not es_produccion() and es_base_local(settings.DATABASE_URL)


def rutas_habilitadas() -> bool:
    """El cerrojo de las rutas HTTP: lo de arriba, más DEV_TOOLS y su clave."""
    return settings.DEV_TOOLS and bool(settings.DEV_TOOLS_KEY) and puede_correr()


async def reiniciar(session: AsyncSession) -> None:
    """
    Borra TODAS las tablas y las vuelve a crear vacías.

    Sobre la conexión de [session] (no sobre un motor propio): así la prueba y
    la app usan la misma base que el resto de la petición.
    """
    conn = await session.connection()
    await conn.run_sync(Base.metadata.drop_all)
    await conn.run_sync(Base.metadata.create_all)
    await session.commit()
    _otps.clear()


async def sembrar(session: AsyncSession) -> List[str]:
    """
    Crea los usuarios de prueba que falten, cada uno con su cuenta de ahorros
    en soles y saldo inicial. Devuelve los DNI que creó (los que ya existían
    se dejan como están: se puede llamar más de una vez).

    El saldo entra por el MISMO libro mayor que una recarga (débito a la caja,
    crédito a la cuenta), así que todo cuadra igual que con dinero "real".
    """
    creados = []
    pin_hash = await ahash_pin(PIN_DE_PRUEBA)
    for prueba in USUARIOS_DE_PRUEBA:
        existe = await session.execute(select(User.id).where(User.dni == prueba.dni))
        if existe.first() is not None:
            continue
        user = User(
            dni=prueba.dni,
            nombres=prueba.nombres,
            apellidos=prueba.apellidos,
            email=prueba.email,
            alias=prueba.alias,
            pin_hash=pin_hash,
        )
        session.add(user)
        await session.flush()
        cuenta = await accounts.abrir_cuenta(session, user.id)
        caja = await accounts.cuenta_de_sistema(session, cuenta.moneda)
        await post(
            session,
            tipo="recarga",
            asientos=[
                Asiento(caja.id, "debito", SALDO_INICIAL),
                Asiento(cuenta.id, "credito", SALDO_INICIAL),
            ],
            idempotency_key=f"dev-seed-{prueba.dni}",
            fingerprint="",
        )
        creados.append(prueba.dni)
    await session.commit()
    return creados


# ---- Últimos códigos OTP (solo con las rutas de desarrollo habilitadas) ----


@dataclass(frozen=True)
class OtpVisto:
    destino: str
    codigo: str
    proposito: str
    momento: datetime


_otps: Deque[OtpVisto] = deque(maxlen=10)


def registrar_otp(destino: str, codigo: str, proposito: str) -> None:
    """
    Guarda el código que envió el notificador `log`, para mostrarlo en el menú
    de desarrollo. Solo si las rutas están habilitadas: en cualquier otro
    entorno no se guarda nada.
    """
    if rutas_habilitadas():
        _otps.appendleft(OtpVisto(destino, codigo, proposito, utcnow()))


def ultimos_otps() -> List[OtpVisto]:
    return list(_otps)
