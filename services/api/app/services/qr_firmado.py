
"""
Issue #77 - Firma y validacion de codigos QR.

Utiliza HMAC-SHA256 para proteger los datos del pago.
La clave secreta nunca debe enviarse a la aplicacion.
"""

import base64
import hashlib
import hmac
import json
import secrets
import time


class QrVencido(ValueError):
    """El QR es auténtico pero ya venció: la firma se comprueba antes."""


def _clave_segura(secreto: str) -> bytes:
    if not isinstance(secreto, str):
        raise ValueError("La clave de firma no es valida.")

    clave = secreto.encode("utf-8")

    if len(clave) < 32:
        raise ValueError(
            "La clave de firma debe tener al menos 32 bytes."
        )

    return clave


def emitir_qr(
    *,
    secreto: str,
    cuenta_id: str,
    monto_centimos: int,
    concepto: str,
    ttl_segundos: int = 300,
    ahora: int | None = None,
) -> str:
    """
    Emite un QR firmado con cuenta, monto, concepto
    y fecha de vencimiento.
    """

    clave = _clave_segura(secreto)

    if not isinstance(cuenta_id, str) or not cuenta_id:
        raise ValueError("La cuenta no es valida.")

    if type(monto_centimos) is not int or monto_centimos <= 0:
        raise ValueError("El monto debe ser positivo.")

    if type(ttl_segundos) is not int:
        raise ValueError("Caducidad no valida.")

    if not 30 <= ttl_segundos <= 86400:
        raise ValueError(
            "La caducidad debe estar entre 30 y 86400 segundos."
        )

    if not isinstance(concepto, str):
        raise ValueError("Concepto no valido.")

    concepto = concepto.strip()

    if len(concepto) > 40:
        raise ValueError("Concepto demasiado largo.")

    instante = int(time.time()) if ahora is None else ahora

    datos = {
        "v": 1,
        "cuenta_id": cuenta_id,
        "monto_centimos": monto_centimos,
        "concepto": concepto,
        "exp": instante + ttl_segundos,
        "nonce": secrets.token_hex(12),
    }

    contenido = json.dumps(
        datos,
        separators=(",", ":"),
        sort_keys=True,
        ensure_ascii=False,
    ).encode("utf-8")

    mensaje = base64.urlsafe_b64encode(
        contenido
    ).decode("ascii").rstrip("=")

    firma = hmac.new(
        clave,
        mensaje.encode("ascii"),
        hashlib.sha256,
    ).hexdigest()

    return f"{mensaje}.{firma}"


def validar_qr(
    token: str,
    *,
    secreto: str,
    ahora: int | None = None,
) -> dict:
    """
    Comprueba integridad, firma y fecha de vencimiento.

    Devuelve los datos verificados del QR.
    """

    clave = _clave_segura(secreto)

    if not isinstance(token, str) or len(token) > 2048:
        raise ValueError("QR invalido o vencido.")

    try:
        mensaje, firma = token.split(".")

        firma_esperada = hmac.new(
            clave,
            mensaje.encode("ascii"),
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(firma, firma_esperada):
            raise ValueError("Firma incorrecta.")

        relleno = "=" * (-len(mensaje) % 4)

        contenido = base64.urlsafe_b64decode(
            mensaje + relleno
        )

        datos = json.loads(contenido)

        if not isinstance(datos, dict):
            raise ValueError("Contenido incorrecto.")

        if type(datos.get("v")) is not int or datos["v"] != 1:
            raise ValueError("Version incorrecta.")

        if not isinstance(datos.get("cuenta_id"), str):
            raise ValueError("Cuenta incorrecta.")

        if not datos["cuenta_id"]:
            raise ValueError("Cuenta vacia.")

        if (
            type(datos.get("monto_centimos")) is not int
            or datos["monto_centimos"] <= 0
        ):
            raise ValueError("Monto incorrecto.")

        if not isinstance(datos.get("concepto"), str):
            raise ValueError("Concepto incorrecto.")

        if type(datos.get("exp")) is not int:
            raise ValueError("Caducidad incorrecta.")

        if not isinstance(datos.get("nonce"), str):
            raise ValueError("Identificador incorrecto.")

        instante = int(time.time()) if ahora is None else ahora

        if instante >= datos["exp"]:
            raise QrVencido("QR vencido.")

        return datos

    except QrVencido:
        raise

    except (ValueError, TypeError, UnicodeError) as error:
        raise ValueError("QR invalido o vencido.") from error
