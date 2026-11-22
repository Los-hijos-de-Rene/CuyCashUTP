"""Límite diario de pagos con QR: tabla `qr_consumo_diario`.

Acumulado por titular, moneda y día de Lima. Arranca vacía: el consumo de hoy
antes del despliegue no cuenta (como mucho, un día con el doble de cupo).
"""
from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = depends_on = None


def upgrade():
    op.create_table(
        "qr_consumo_diario",
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("moneda", sa.String(length=3), nullable=False),
        sa.Column("fecha", sa.Date(), nullable=False),
        sa.Column("consumido", sa.BigInteger(), nullable=False),
        sa.CheckConstraint("consumido >= 0", name="ck_qr_consumo_diario_no_negativo"),
        sa.CheckConstraint("moneda IN ('PEN','USD')", name="ck_qr_consumo_diario_moneda"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("user_id", "moneda", "fecha"),
    )


def downgrade():
    # Solo un acumulado: los pagos siguen en `transactions`.
    op.drop_table("qr_consumo_diario")
