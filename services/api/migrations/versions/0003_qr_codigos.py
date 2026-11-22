"""QR estático y token corto: tabla `qr_codigos`.

Los QR dejan de llevar los datos del cobro dentro del token: el token es una
referencia firmada a esta tabla. Los QR emitidos con el formato anterior (que
caducaban en minutos) dejan de aceptarse al desplegar.
"""
from alembic import op
import sqlalchemy as sa

revision = "0003"
down_revision = "0002"
branch_labels = depends_on = None


def upgrade():
    op.create_table(
        "qr_codigos",
        sa.Column("id", sa.String(length=22), nullable=False),
        sa.Column("cuenta_id", sa.String(length=36), nullable=False),
        sa.Column("tipo", sa.String(length=10), nullable=False),
        sa.Column("monto", sa.BigInteger(), nullable=True),
        sa.Column("concepto", sa.String(length=40), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("estado", sa.String(length=10), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revocado_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("tipo IN ('estatico','dinamico')", name="ck_qr_codigos_tipo"),
        sa.CheckConstraint("estado IN ('activo','revocado')", name="ck_qr_codigos_estado"),
        sa.CheckConstraint(
            "(tipo = 'estatico' AND monto IS NULL AND expires_at IS NULL)"
            " OR (tipo = 'dinamico' AND monto > 0 AND expires_at IS NOT NULL)",
            name="ck_qr_codigos_forma",
        ),
        sa.CheckConstraint(
            "(estado = 'revocado') = (revocado_at IS NOT NULL)",
            name="ck_qr_codigos_revocado_at",
        ),
        sa.ForeignKeyConstraint(["cuenta_id"], ["accounts.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_qr_codigos_cuenta_id"), "qr_codigos", ["cuenta_id"], unique=False)
    op.create_index(
        "ux_qr_codigos_un_estatico_activo",
        "qr_codigos",
        ["cuenta_id"],
        unique=True,
        sqlite_where=sa.text("tipo = 'estatico' AND estado = 'activo'"),
        postgresql_where=sa.text("tipo = 'estatico' AND estado = 'activo'"),
    )


def downgrade():
    # Solo tiene QR, no dinero: los pagos quedan en `transactions`/`transfers`.
    op.drop_index("ux_qr_codigos_un_estatico_activo", table_name="qr_codigos")
    op.drop_index(op.f("ix_qr_codigos_cuenta_id"), table_name="qr_codigos")
    op.drop_table("qr_codigos")
