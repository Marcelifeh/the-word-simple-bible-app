from __future__ import annotations

from pydantic import BaseModel, Field


class VerseRef(BaseModel):
    translation: str = Field(..., examples=["kjv", "web"])
    bookId: str
    chapter: int
    verse: int


class VerseOut(BaseModel):
    translation: str
    bookId: str
    book: str
    chapter: int
    verse: int
    text: str


class ChapterOut(BaseModel):
    translation: str
    bookId: str
    book: str
    chapter: int
    verses: list[VerseOut]


class SearchOut(BaseModel):
    translation: str
    q: str
    verses: list[VerseOut]


class CommentaryInsight(BaseModel):
    understanding: str
    deepInsight: str
    keyTruth: str
    reflection: str
    styleVersion: int = 2


class CommentaryOut(BaseModel):
    translation: str
    bookId: str
    chapter: int
    verse: int
    style: str
    text: str
    insight: CommentaryInsight | None = None


class GenerateCommentaryRequest(BaseModel):
    translation: str
    bookId: str
    chapter: int
    verse: int
    style: str = "simple"
    language: str = "english"
    overwrite: bool = False


class GenerateCommentaryResponse(BaseModel):
    explanation: str
    insight: CommentaryInsight | None = None
    stored: bool


class AudioRequest(BaseModel):
    translation: str
    bookId: str
    chapter: int
    verse: int


class AudioResponse(BaseModel):
    url: str
