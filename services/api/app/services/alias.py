"""
El alias: el nombre público con el que a un titular lo encuentran para
enviarle dinero (`GET /v1/directory/resolve?alias=`).

Por eso es ÚNICO (UNIQUE en `users.alias`) y lleva al menos una letra: un alias
de puros dígitos podría confundirse con un DNI en el mismo campo de búsqueda.
La regla vive aquí y en `AliasRules` de la app; deben coincidir.
"""

import random
import re
import unicodedata

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import User

# `@` + 3 a 20 de [a-z0-9_.], con al menos una letra.
REGLA = re.compile(r"^@(?=[a-z0-9_.]*[a-z])[a-z0-9_.]{3,20}$")

# La base deja sitio para un sufijo de hasta 4 dígitos dentro de los 20.
_BASE_MAX = 16
_INTENTOS = 20


def normalizar(texto: str) -> str:
    """Minúsculas, sin espacios en los bordes y con `@` delante."""
    limpio = texto.strip().lower()
    return limpio if limpio.startswith("@") else f"@{limpio}"


def es_valido(alias: str) -> bool:
    return REGLA.match(alias) is not None


def base_desde_nombre(nombres: str) -> str:
    """
    `José Ñique` -> `jose`. El primer nombre, sin tildes ni símbolos.

    Nunca usa el DNI: el alias es público, y derivarlo del DNI lo filtraría.
    Un nombre que no da para 3 caracteres con una letra se completa con `cuy`.
    """
    partes = nombres.split()
    primero = partes[0] if partes else ""
    plano = unicodedata.normalize("NFKD", primero).encode("ascii", "ignore").decode()
    slug = "".join(c for c in plano.lower() if c.isalnum())[:_BASE_MAX]
    if len(slug) < 3 or not any(c.isalpha() for c in slug):
        slug = f"cuy{slug}"[:_BASE_MAX]
    return slug


async def esta_tomado(session: AsyncSession, alias: str) -> bool:
    return (
        await session.execute(select(User.id).where(User.alias == alias))
    ).first() is not None


async def libre(session: AsyncSession, nombres: str) -> str:
    """
    Un alias libre para un registro nuevo: `@jenny` y, si está tomado,
    `@jenny` + 2 a 4 dígitos al azar.

    Es una sugerencia, no una reserva: otro registro simultáneo puede llevarse
    el mismo. Quien inserta debe atrapar la UNIQUE y volver a pedir uno.
    """
    base = base_desde_nombre(nombres)
    candidato = f"@{base}"
    if not await esta_tomado(session, candidato):
        return candidato
    for intento in range(_INTENTOS):
        digitos = 2 if intento < 5 else 3 if intento < 12 else 4
        candidato = f"@{base}{random.randint(10 ** (digitos - 1), 10 ** digitos - 1)}"
        if not await esta_tomado(session, candidato):
            return candidato
    # Con 4 dígitos al azar quedan ~9 000 opciones por base: llegar aquí
    # significa una base saturadísima. Se sale por un prefijo distinto.
    return f"@cuy{random.randint(10 ** 15, 10 ** 16 - 1)}"
