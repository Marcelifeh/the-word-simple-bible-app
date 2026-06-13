"""init

Revision ID: 0001
Revises: 
Create Date: 2025-12-20

"""

from alembic import op
import sqlalchemy as sa


revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "verses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("translation", sa.String(length=16), nullable=False),
        sa.Column("book_id", sa.String(length=32), nullable=False),
        sa.Column("book", sa.String(length=64), nullable=False),
        sa.Column("chapter", sa.Integer(), nullable=False),
        sa.Column("verse", sa.Integer(), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_verses_translation_book_chapter",
        "verses",
        ["translation", "book_id", "chapter"],
    )
    op.create_index(
        "ix_verses_translation_chapter_verse",
        "verses",
        ["translation", "chapter", "verse"],
    )
    op.create_unique_constraint("uq_verse_ref", "verses", ["translation", "book_id", "chapter", "verse"])

    op.create_table(
        "commentary",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("verse_id", sa.Integer(), sa.ForeignKey("verses.id", ondelete="CASCADE"), nullable=False),
        sa.Column("style", sa.String(length=32), nullable=False, server_default="simple"),
        sa.Column("model", sa.String(length=128), nullable=False, server_default=""),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_commentary_verse_id", "commentary", ["verse_id"])
    op.create_unique_constraint("uq_commentary_verse_style", "commentary", ["verse_id", "style"])


def downgrade() -> None:
    op.drop_constraint("uq_commentary_verse_style", "commentary", type_="unique")
    op.drop_index("ix_commentary_verse_id", table_name="commentary")
    op.drop_table("commentary")

    op.drop_constraint("uq_verse_ref", "verses", type_="unique")
    op.drop_index("ix_verses_translation_chapter_verse", table_name="verses")
    op.drop_index("ix_verses_translation_book_chapter", table_name="verses")
    op.drop_table("verses")
