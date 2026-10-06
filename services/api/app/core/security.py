import asyncio
import hashlib
import re
import secrets
from weakref import WeakKeyDictionary

from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError
from starlette.concurrency import run_in_threadpool

from app.core.config import settings

# argon2id con los parámetros por defecto de la librería: pensados para
# resistir GPU. Un PIN de 6 dígitos tiene solo un millón de combinaciones, así
# que el coste del hash es lo único que separa un volcado de la base de tener
# todos los PIN en claro.
_hasher = PasswordHasher()

_PIN_FORMAT = re.compile(r"^\d{6}$")


def hash_pin(pin: str) -> str:
    return _hasher.hash(pin)


def verify_pin(pin: str, pin_hash: str) -> bool:
    try:
        return _hasher.verify(pin_hash, pin)
    except (VerifyMismatchError, VerificationError):
        return False


# argon2id (64 MiB, ~30 ms) es CPU puro y síncrono: llamado directo desde un
# handler `async` PARA el bucle de eventos, y esos 30 ms no se solapan entre
# peticiones (7 movimientos simultáneos = 210 ms solo en hashes, contra un SLA
# de < 200 ms por operación). En un hilo, argon2-cffi suelta el GIL mientras
# calcula, así que las peticiones sí avanzan en paralelo. Los handlers async
# deben usar estas variantes; las síncronas quedan para código sin bucle.
#
# TOPE DE CONCURRENCIA. Cada hash reserva `memory_cost` = 64 MiB (perfil por
# defecto de argon2-cffi). El pool de hilos de AnyIO tiene 40 por defecto: sin
# tope, un pico de 40 peticiones con PIN pediría 40 x 64 MiB = 2.5 GiB. El plan
# gratuito de Render ofrece 512 MiB y el intérprete + FastAPI + el pool de
# conexiones ya ocupan ~150-200 MiB, así que quedan ~300 MiB: con 2 hashes
# simultáneos el pico es 2 x 64 = 128 MiB y sobra margen; con 4 serían 256 MiB,
# demasiado justo. Por eso el valor por defecto es 2 (`PIN_HASH_CONCURRENCY`,
# subir si el plan tiene más memoria: tope = (RAM libre) / 64 MiB). El resto de
# peticiones espera en el semáforo SIN ocupar hilo ni memoria, y el bucle sigue
# libre. NO se baja el coste de argon2 para ganar latencia: es un parámetro de
# seguridad (un PIN de 6 dígitos solo se protege con el coste del hash).
_semaforos: "WeakKeyDictionary" = WeakKeyDictionary()


def _semaforo() -> asyncio.Semaphore:
    # Uno por bucle de eventos: en Python 3.9 un Semaphore se ata al bucle que
    # estaba activo al crearlo, y los tests abren un bucle por prueba.
    loop = asyncio.get_running_loop()
    sem = _semaforos.get(loop)
    if sem is None:
        sem = _semaforos[loop] = asyncio.Semaphore(max(1, settings.PIN_HASH_CONCURRENCY))
    return sem


async def averify_pin(pin: str, pin_hash: str) -> bool:
    async with _semaforo():
        return await run_in_threadpool(verify_pin, pin, pin_hash)


async def ahash_pin(pin: str) -> str:
    async with _semaforo():
        return await run_in_threadpool(hash_pin, pin)


def pin_is_valid(pin: str) -> bool:
    """Mismas reglas que muestra la checklist del registro en la app."""
    if not _PIN_FORMAT.match(pin):
        return False
    if len(set(pin)) == 1:  # 000000, 111111…
        return False
    if pin in "0123456789" or pin in "9876543210":  # secuencias triviales
        return False
    return True


def new_token() -> str:
    """Token opaco. Lo que se guarda es su hash, no él."""
    return secrets.token_urlsafe(32)


def token_digest(token: str) -> str:
    """
    SHA-256 basta para tokens: son aleatorios de 256 bits, así que no hay
    diccionario que probar. El PIN sí necesita argon2 porque es adivinable.
    """
    return hashlib.sha256(token.encode()).hexdigest()
