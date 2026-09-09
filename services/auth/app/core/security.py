import hashlib
import re
import secrets

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
