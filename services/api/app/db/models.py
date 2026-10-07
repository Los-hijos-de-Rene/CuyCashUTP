import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


def _uuid() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    dni: Mapped[str] = mapped_column(String(8), unique=True, index=True)
    nombres: Mapped[str] = mapped_column(String(120))
    apellidos: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), index=True)
    # Único: es como se busca a alguien para enviarle dinero (`app.services.alias`).
    alias: Mapped[str] = mapped_column(String(60), unique=True, index=True)
    # El PIN nunca se guarda en claro ni aparece en logs.
    pin_hash: Mapped[str] = mapped_column(String(255))
    pin_updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    kyc_status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Device(Base):
    """Teléfono vinculado a una cuenta. Sin vínculo, entrar exige OTP."""

    __tablename__ = "devices"
    __table_args__ = (UniqueConstraint("user_id", "device_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    trusted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    # Lo que el teléfono declara de sí mismo (`X-Device-Name`). Solo para
    # mostrar en "Dispositivos vinculados": nada de seguridad se decide con él.
    nombre: Mapped[Optional[str]] = mapped_column(String(80), nullable=True)
    plataforma: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)


class Session(Base):
    """
    Sesión abierta. Se guarda el HASH del token, no el token: un volcado de la
    base no debe permitir entrar como nadie.
    """

    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128))
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class BiometricCredential(Base):
    """
    Secreto que la huella libera para abrir sesión sin teclear el PIN.

    Ligado a (usuario, dispositivo): de otro teléfono no sirve. Se guarda el
    hash, como los tokens de sesión. Revocarlo es poner `revoked_at`; una
    fila revocada nunca vuelve a valer.
    """

    __tablename__ = "biometric_credentials"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    secret_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    revoked_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class Lockout(Base):
    """
    Bloqueo vigente. `subject_type` separa los dos alcances que la app no puede
    llevar por sí sola: `dni` protege una cuenta en cualquier teléfono,
    `device` protege contra barrer muchas cuentas desde uno.
    """

    __tablename__ = "lockouts"
    __table_args__ = (UniqueConstraint("subject_type", "subject_value"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    subject_type: Mapped[str] = mapped_column(String(10), index=True)
    subject_value: Mapped[str] = mapped_column(String(128), index=True)
    level: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class LoginAttempt(Base):
    """
    Un registro por intento. Es lo que permite la ventana deslizante del
    contador por dispositivo: contar los fallos de los últimos N minutos en
    lugar de llevar un acumulado que un login correcto pondría a cero.
    """

    __tablename__ = "login_attempts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    dni: Mapped[str] = mapped_column(String(8), index=True)
    device_id: Mapped[str] = mapped_column(String(128), index=True)
    succeeded: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)


class OtpChallenge(Base):
    __tablename__ = "otp_challenges"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    purpose: Mapped[str] = mapped_column(String(20))  # recovery | device
    identifier: Mapped[str] = mapped_column(String(255), index=True)
    user_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    # El código es una credencial de un solo uso: se guarda hasheado.
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    cooldown_until: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts_left: Mapped[int] = mapped_column(Integer)
    resends_left: Mapped[int] = mapped_column(Integer)
    consumed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    cancelled_reason: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class OtpTicket(Base):
    """
    Prueba de que un OTP se verificó. Lo exige `pin/reset` para que nadie
    cambie un PIN sin haber pasado por el código.
    """

    __tablename__ = "otp_tickets"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    purpose: Mapped[str] = mapped_column(String(20))
    identifier: Mapped[str] = mapped_column(String(255))
    user_id: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    # Limita `pin/check-current`, que sin tope sería un oráculo del PIN.
    checks_left: Mapped[int] = mapped_column(Integer, default=5)


class KycVerification(Base):
    """Veredicto y distancias. NUNCA las imágenes (decisión 4 del ADR-0002)."""

    __tablename__ = "kyc_verifications"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    verdict: Mapped[str] = mapped_column(String(20))
    document_valid: Mapped[bool] = mapped_column(Boolean, default=False)
    is_live: Mapped[bool] = mapped_column(Boolean, default=False)
    face_match: Mapped[bool] = mapped_column(Boolean, default=False)
    face_distance: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


# ---------------------------------------------------------------------------
# Épica 2 · Cuentas y libro mayor (HU05, HU17, HU18)
#
# Diseño y justificación: docs/modelo-datos.md.
# Regla que gobierna todo lo de abajo: el dinero se guarda en CÉNTIMOS como
# entero. Punto flotante en un libro mayor produce residuos que descuadran
# partidas.
# ---------------------------------------------------------------------------


class Account(Base):
    """
    Cuenta de un titular.

    `saldo_disponible` es una columna y no la suma de los asientos. Sumar el
    historial completo es correcto, pero no sostiene el SLA de 200 ms de la
    HU17 cuando la cuenta acumula miles de movimientos. Se actualiza en el
    mismo COMMIT que los asientos, así que no puede divergir, y el historial
    sigue siendo la fuente auditable para reconstruirla.
    """

    __tablename__ = "accounts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[Optional[str]] = mapped_column(
        ForeignKey("users.id"), index=True, nullable=True
    )
    numero: Mapped[str] = mapped_column(String(14), unique=True, index=True)
    tipo: Mapped[str] = mapped_column(String(10), default="ahorro")
    moneda: Mapped[str] = mapped_column(String(3), default="PEN")
    estado: Mapped[str] = mapped_column(String(10), default="activa")
    # Lo pone el titular ("Viaje"); solo lo ve él. Quien le envía dinero ve el
    # tipo y la moneda, nunca esto.
    nombre: Mapped[Optional[str]] = mapped_column(String(30), nullable=True)
    # Clave de la petición que abrió la cuenta: un reintento con la misma clave
    # devuelve esta cuenta en vez de abrir otra. `None` en la de registro y en
    # las cajas.
    idempotency_key: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    # Céntimos. El disponible descuenta lo retenido; el contable no.
    saldo_disponible: Mapped[int] = mapped_column(BigInteger, default=0)
    saldo_contable: Mapped[int] = mapped_column(BigInteger, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    __table_args__ = (
        CheckConstraint(
            "tipo IN ('ahorro','corriente','sueldo','sistema')", name="ck_accounts_tipo"
        ),
        # La cuenta sueldo existe para recibir la planilla, que en Perú se paga
        # en soles.
        CheckConstraint(
            "tipo <> 'sueldo' OR moneda = 'PEN'", name="ck_accounts_sueldo_en_soles"
        ),
        # Una sueldo por titular. Índice parcial y no regla del servicio: dos
        # aperturas simultáneas verían "no hay" y abrirían dos.
        Index(
            "ux_accounts_un_sueldo",
            "user_id",
            unique=True,
            sqlite_where=text("tipo = 'sueldo'"),
            postgresql_where=text("tipo = 'sueldo'"),
        ),
        # La clave de apertura es única POR TITULAR: la de otro no debe chocar.
        UniqueConstraint("user_id", "idempotency_key", name="uq_accounts_clave_apertura"),
        CheckConstraint("moneda IN ('PEN','USD')", name="ck_accounts_moneda"),
        CheckConstraint(
            "estado IN ('activa','bloqueada','cerrada')", name="ck_accounts_estado"
        ),
        # La cuenta de sistema y la ausencia de titular van juntas, en los dos
        # sentidos: una `sistema` con titular podría irse a negativo (ver el
        # CHECK de abajo) y una cuenta normal sin titular no pertenece a nadie.
        CheckConstraint(
            "(tipo = 'sistema') = (user_id IS NULL)",
            name="ck_accounts_sistema_sin_titular",
        ),
        # La caja de CuyCash es la contraparte de cada recarga: su saldo es, por
        # definición, el dinero inyectado en la demo, y por eso va en negativo.
        # Para cualquier cuenta de un titular, el tope sigue siendo la última
        # defensa contra el doble gasto.
        CheckConstraint(
            "tipo = 'sistema' OR saldo_disponible >= 0",
            name="ck_accounts_saldo_no_negativo",
        ),
    )


class Transaction(Base):
    """
    Agrupador de los asientos de UNA operación.

    `idempotency_key` tiene índice único y es lo que cumple el "una sola
    autorización por pago" de la HU16: el cliente repite la clave al
    reintentar, el segundo intento choca contra la restricción y se devuelve la
    transacción original en lugar de cobrar dos veces. Se delega en la base
    porque es la única capa que ve todos los intentos simultáneos.
    """

    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    tipo: Mapped[str] = mapped_column(String(20))
    estado: Mapped[str] = mapped_column(String(12), default="confirmada")
    idempotency_key: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    referencia: Mapped[Optional[str]] = mapped_column(String(60), nullable=True)
    # Huella de los parámetros de la petición. Repetir una clave de
    # idempotencia con OTROS datos no es un reintento, es una operación
    # distinta: devolver la original haría creer al usuario que envió lo que
    # acaba de escribir. Ver Review Focus 1.
    request_fingerprint: Mapped[str] = mapped_column(String(64), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )

    __table_args__ = (
        CheckConstraint(
            "tipo IN ('transferencia','recarga','pago_qr','desembolso','cuota','ajuste')",
            name="ck_transactions_tipo",
        ),
        CheckConstraint(
            "estado IN ('pendiente','confirmada','revertida')",
            name="ck_transactions_estado",
        ),
    )


class LedgerEntry(Base):
    """
    Asiento del libro mayor. Partida doble: por cada transacción, la suma de
    los débitos iguala la de los créditos, y los asientos se insertan dentro de
    la misma transacción de base de datos (HU18: débito y crédito, o ninguno).

    El monto es SIEMPRE positivo; el signo lo dice `direccion`. Guardar montos
    negativos obliga a recordar la convención en cada consulta y es de donde
    salen los errores de signo.

    No hay borrado: una operación equivocada se corrige con un asiento inverso
    que deja su propio rastro.
    """

    __tablename__ = "ledger_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    transaction_id: Mapped[str] = mapped_column(
        ForeignKey("transactions.id"), index=True
    )
    account_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    direccion: Mapped[str] = mapped_column(String(8))
    monto: Mapped[int] = mapped_column(BigInteger)
    moneda: Mapped[str] = mapped_column(String(3), default="PEN")
    # Saldo de la cuenta DESPUÉS de este asiento: permite auditar la cadena sin
    # recalcular toda la historia.
    saldo_posterior: Mapped[int] = mapped_column(BigInteger)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, index=True
    )

    __table_args__ = (
        # El historial pagina por (cuenta, fecha desc, id desc): este índice es
        # exactamente ese recorrido, así que cada página es una lectura de
        # rango y no un ordenamiento de todos los asientos de la cuenta.
        Index("ix_ledger_cuenta_fecha_id", "account_id", "created_at", "id"),
        CheckConstraint(
            "direccion IN ('debito','credito')", name="ck_ledger_direccion"
        ),
        CheckConstraint("monto > 0", name="ck_ledger_monto_positivo"),
    )


class Beneficiary(Base):
    """
    Una CUENTA guardada por un titular, con un apodo.

    Se guarda la cuenta y no solo el DNI porque una persona puede tener varias:
    el frecuente es "la de ahorros en soles de Luis", no "Luis". El DNI se
    conserva para pintar y para volver a buscar si esa cuenta deja de recibir.
    El nombre y el número enmascarado se calculan al leer.
    """

    __tablename__ = "beneficiaries"
    __table_args__ = (
        UniqueConstraint("user_id", "cuenta_destino_id", name="uq_beneficiaries_user_cuenta"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    beneficiario_dni: Mapped[str] = mapped_column(String(8), index=True)
    cuenta_destino_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    apodo: Mapped[str] = mapped_column(String(40))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Transfer(Base):
    """
    Lo que una transferencia tiene y un asiento no: a quién, desde dónde y por
    qué. Los asientos son el dinero; esta fila es la intención.

    `destino_externo` y `canal` (interbancaria, CCI) son del sprint 3 y no se
    crean todavía.
    """

    __tablename__ = "transfers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    transaction_id: Mapped[str] = mapped_column(
        ForeignKey("transactions.id"), unique=True, index=True
    )
    cuenta_origen: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    cuenta_destino: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    monto: Mapped[int] = mapped_column(BigInteger)
    motivo: Mapped[Optional[str]] = mapped_column(String(40), nullable=True)
    estado: Mapped[str] = mapped_column(String(12), default="confirmada")
