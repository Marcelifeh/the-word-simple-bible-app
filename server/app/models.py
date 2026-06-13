from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Verse(Base):
    __tablename__ = "verses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    translation: Mapped[str] = mapped_column(String(16), nullable=False)  # kjv|web

    book_id: Mapped[str] = mapped_column(String(32), nullable=False)
    book: Mapped[str] = mapped_column(String(64), nullable=False)
    chapter: Mapped[int] = mapped_column(Integer, nullable=False)
    verse: Mapped[int] = mapped_column(Integer, nullable=False)

    text: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    commentary: Mapped[list[Commentary]] = relationship(back_populates="verse", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("translation", "book_id", "chapter", "verse", name="uq_verse_ref"),
        Index("ix_verses_translation_book_chapter", "translation", "book_id", "chapter"),
        Index("ix_verses_translation_chapter_verse", "translation", "chapter", "verse"),
        # For keyword search later you can add a GIN index on to_tsvector(text)
    )


class Commentary(Base):
    __tablename__ = "commentary"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    verse_id: Mapped[int] = mapped_column(ForeignKey("verses.id", ondelete="CASCADE"), nullable=False)

    # Simple versioning/traceability
    language: Mapped[str] = mapped_column(String(16), nullable=False, default="english")
    style: Mapped[str] = mapped_column(String(32), nullable=False, default="simple")
    model: Mapped[str] = mapped_column(String(128), nullable=False, default="")

    text: Mapped[str] = mapped_column(Text, nullable=False)
    payload_json: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    verse: Mapped[Verse] = relationship(back_populates="commentary")

    __table_args__ = (
        UniqueConstraint("verse_id", "style", "language", name="uq_commentary_verse_style_lang"),
        Index("ix_commentary_verse_id", "verse_id"),
    )
