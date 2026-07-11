"""Add commentary language and structured payload.

Revision ID: 0002
Revises: 0001
"""

from alembic import op
import sqlalchemy as sa


revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "commentary",
        sa.Column(
            "language",
            sa.String(length=16),
            nullable=False,
            server_default="english",
        ),
    )
    op.add_column(
        "commentary",
        sa.Column("payload_json", sa.Text(), nullable=True),
    )
    op.drop_constraint(
        "uq_commentary_verse_style",
        "commentary",
        type_="unique",
    )
    op.create_unique_constraint(
        "uq_commentary_verse_style_lang",
        "commentary",
        ["verse_id", "style", "language"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_commentary_verse_style_lang",
        "commentary",
        type_="unique",
    )
    op.create_unique_constraint(
        "uq_commentary_verse_style",
        "commentary",
        ["verse_id", "style"],
    )
    op.drop_column("commentary", "payload_json")
    op.drop_column("commentary", "language")
