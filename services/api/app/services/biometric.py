"""
Credenciales biométricas: un secreto por (usuario, dispositivo) que la huella
libera en el teléfono para abrir sesión sin teclear el PIN.

El servidor guarda el hash (SHA-256: el secreto tiene 256 bits, no hay
diccionario que probar). Nunca se reactiva una fila: revocar es definitivo.
"""

from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import new_token, token_digest
from app.db.models import BiometricCredential, Device, utcnow


async def revoke(
    session: AsyncSession,
    user_id: str,
    *,
    device_id: Optional[str] = None,
    except_device: Optional[str] = None,
) -> int:
    """Revoca las vigentes del usuario; solo las de `device_id`, o todas menos `except_device`."""
    condiciones = [
        BiometricCredential.user_id == user_id,
        BiometricCredential.revoked_at.is_(None),
    ]
    if device_id is not None:
        condiciones.append(BiometricCredential.device_id == device_id)
    if except_device is not None:
        condiciones.append(BiometricCredential.device_id != except_device)
    result = await session.execute(
        update(BiometricCredential).where(*condiciones).values(revoked_at=utcnow())
    )
    await session.flush()
    return result.rowcount or 0


async def issue(session: AsyncSession, user_id: str, device_id: str) -> str:
    """Reemplaza la credencial de este dispositivo y devuelve el secreto en claro, una vez."""
    await revoke(session, user_id, device_id=device_id)
    secreto = new_token()
    session.add(
        BiometricCredential(
            user_id=user_id, device_id=device_id, secret_hash=token_digest(secreto)
        )
    )
    await session.flush()
    return secreto


async def valid_for(
    session: AsyncSession, user_id: str, device_id: str, secreto: str
) -> bool:
    """¿El secreto es la credencial VIGENTE de ese usuario en ese dispositivo vinculado?"""
    fila = (
        await session.execute(
            select(BiometricCredential).where(
                BiometricCredential.secret_hash == token_digest(secreto),
                BiometricCredential.revoked_at.is_(None),
            )
        )
    ).scalars().first()
    if fila is None or fila.user_id != user_id or fila.device_id != device_id:
        return False
    vinculado = (
        await session.execute(
            select(Device).where(Device.user_id == user_id, Device.device_id == device_id)
        )
    ).scalars().first()
    return vinculado is not None


async def devices_with_credential(session: AsyncSession, user_id: str) -> set:
    """`device_id` con credencial vigente, para marcar la huella en la lista."""
    filas = await session.execute(
        select(BiometricCredential.device_id).where(
            BiometricCredential.user_id == user_id,
            BiometricCredential.revoked_at.is_(None),
        )
    )
    return set(filas.scalars().all())
