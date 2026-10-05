import hashlib
import re
import secrets

from starlette.concurrency import run_in_threadpool
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError, VerificationError

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
async def averify_pin(pin: str, pin_hash: str) -> bool:
    return await run_in_threadpool(verify_pin, pin, pin_hash)


async def ahash_pin(pin: str) -> str:
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
