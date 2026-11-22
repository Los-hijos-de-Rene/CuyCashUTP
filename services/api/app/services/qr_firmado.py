"""
Token de los QR de CuyCash (issue #77): corto, opaco y firmado.

Formato: `<id>.<firma>`, 45 caracteres base64url.
- `id`: 16 bytes aleatorios (128 bits), la clave de la fila de `qr_codigos`.
- `firma`: HMAC-SHA256 del id, truncado a 16 bytes.

Por qué así y no con los datos dentro del token (formato v1):
- El v1 llevaba cuenta, monto, concepto, caducidad y nonce en JSON + 64
  caracteres de firma: ~260 caracteres, un QR denso que cuesta leer con una
  cámara mediocre o desde una pantalla con brillo bajo. Este mide 45.
- Base64 no cifra: el v1 dejaba leer el id interno de la cuenta a cualquiera
  que escaneara el QR. Este no dice nada.
- Un QR estático vive años impreso en un mostrador. Sin una fila en el
  servidor no se puede revocar; solo rotando la clave, que invalida los QR de
  todos los usuarios.

La firma no es lo que protege el dinero (eso lo hacen la fila y sus reglas):
deja rechazar basura y tokens inventados sin consultar la base, y evita que un
id filtrado por otra vía (un log, por ejemplo) sirva sin la clave. 128 bits de
HMAC truncado bastan para eso (NIST SP 800-107 admite truncar a >= 64 bits).

La clave secreta nunca debe enviarse a la aplicación.
"""

import base64
import hashlib
import hmac
import re
import secrets

LARGO_ID = 22  # 16 bytes en base64url sin relleno
LARGO_TOKEN = 2 * LARGO_ID + 1
_FORMA = re.compile(r"[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{22}")
# Separa el uso de esta clave de cualquier otro HMAC que se firme con ella.
_DOMINIO = b"cuycash-qr-v2|"


def _clave_segura(secreto: str) -> bytes:
    if not isinstance(secreto, str):
        raise ValueError("La clave de firma no es valida.")
    clave = secreto.encode("utf-8")
    if len(clave) < 32:
        raise ValueError("La clave de firma debe tener al menos 32 bytes.")
    return clave


def _b64(datos: bytes) -> str:
    return base64.urlsafe_b64encode(datos).decode("ascii").rstrip("=")


def _firma(qr_id: str, clave: bytes) -> str:
    digest = hmac.new(clave, _DOMINIO + qr_id.encode("ascii"), hashlib.sha256).digest()
    return _b64(digest[:16])


def nuevo_id() -> str:
    """Referencia aleatoria e impredecible de un QR (128 bits)."""
    return secrets.token_urlsafe(16)


def token_de(qr_id: str, *, secreto: str) -> str:
    """El contenido que se dibuja en el QR."""
    return f"{qr_id}.{_firma(qr_id, _clave_segura(secreto))}"


def leer_token(token: str, *, secreto: str) -> str:
    """
    Comprueba forma y firma y devuelve el id. NO dice si el QR existe, venció o
    fue revocado: eso lo decide la fila en la base.
    """
    clave = _clave_segura(secreto)
    if not isinstance(token, str) or not _FORMA.fullmatch(token):
        raise ValueError("QR invalido.")
    qr_id, firma = token.split(".")
    if not hmac.compare_digest(firma, _firma(qr_id, clave)):
        raise ValueError("QR invalido.")
    return qr_id


def huella_de_pago(qr_id: str) -> str:
    """
    Clave del libro mayor para el pago de un cobro DINÁMICO: su UNIQUE deja un
    solo pago por QR, incluso con dos a la vez. 64 caracteres: cabe en
    `transactions.idempotency_key`.
    """
    return hashlib.sha256(b"qr-dinamico|" + qr_id.encode("ascii")).hexdigest()


def clave_de_pago_libre(user_id: str, clave_cliente: str) -> str:
    """
    Clave del libro mayor para un pago a un QR ESTÁTICO. Lo hace único la clave
    del cliente, acotada a su titular: `idempotency_key` es única en todo el
    sistema, y sin acotarla la clave de un desconocido chocaría con la propia.
    """
    return hashlib.sha256(
        f"qr-libre|{user_id}|{clave_cliente}".encode("utf-8")
    ).hexdigest()
