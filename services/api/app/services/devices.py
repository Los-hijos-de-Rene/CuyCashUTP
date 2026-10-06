"""
Lo que el teléfono declara de sí mismo en `X-Device-Name`.

Formato que manda la app: `<plataforma>|<modelo>`. Una cabecera ausente o
rara no rompe nada: es un dato para mostrar.
"""

from typing import Optional, Tuple

from app.db.models import Device

_PLATAFORMAS = ("android", "ios")
_SEPARADOR = "|"
_MAXIMO = 80


def describe(header: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
    """`(nombre, plataforma)`; `(None, None)` si no hay nada que guardar."""
    texto = (header or "").strip()
    if not texto:
        return None, None
    plataforma, sep, modelo = texto.partition(_SEPARADOR)
    if sep and plataforma.strip() in _PLATAFORMAS and modelo.strip():
        return modelo.strip()[:_MAXIMO], plataforma.strip()
    return texto[:_MAXIMO], None


def touch(device: Device, header: Optional[str]) -> None:
    """Actualiza el nombre si el teléfono mandó uno; si no, conserva el que había."""
    nombre, plataforma = describe(header)
    if nombre is not None:
        device.nombre = nombre
        device.plataforma = plataforma
