from __future__ import annotations

import json
import os
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
import httpx
import re

from .db import SessionLocal
from .db import get_database_url
from .llm import generate_commentary
from .audio import generate_verse_audio, STATIC_DIR
from .models import Commentary, Verse
from .routes import sermon
import logging

logger = logging.getLogger("uvicorn.error")
from .schemas import (
    ChapterOut,
    CommentaryInsight,
    CommentaryOut,
    GenerateCommentaryRequest,
    GenerateCommentaryResponse,
    SearchOut,
    VerseOut,
    AudioRequest,
    AudioResponse,
)
from fastapi.responses import FileResponse

app = FastAPI(title="The Word App API", version="1.0.0")
app.include_router(sermon.router)

# Allow Flutter Web (and other local dev clients) to call this API.
allowed_origins = [
    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:8080",
    "http://localhost:57117",
]

production_web_origin = os.getenv("WEB_APP_ORIGIN")
if production_web_origin:
    allowed_origins.append(production_web_origin)

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve audio files with no-cache headers (prevents Chrome from replaying
# the first verse's cached audio for all subsequent verse requests).
@app.get("/static/audio/{filename}")
async def serve_audio(filename: str):
    file_path = STATIC_DIR / "audio" / filename
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Audio file not found")
    return FileResponse(
        path=str(file_path),
        media_type="audio/mpeg",
        headers={
            "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
            "Pragma": "no-cache",
            "Expires": "0",
        },
    )


def _norm_id(value: str) -> str:
    # Be forgiving about client input. Our DB stores ids like "web", "genesis".
    return (value or "").strip().lower()


def _norm_book_key(value: str) -> str:
    # Turn ids like "song_of_songs" into "song of songs" for name matching.
    return " ".join(_norm_id(value).replace("_", " ").split())


def _book_name_expr():
    # Normalize DB book names for comparisons.
    return func.lower(func.trim(Verse.book))


def _parse_commentary_insight(payload_json: str | None) -> CommentaryInsight | None:
    if payload_json is None or not payload_json.strip():
        return None
    try:
        decoded = json.loads(payload_json)
    except Exception:
        return None
    if not isinstance(decoded, dict):
        return None
    try:
        return CommentaryInsight(**decoded)
    except Exception:
        return None


def _book_id_candidates(book_id: str) -> list[str]:
    """Return plausible DB book_id variants for a client bookId.

    Some imports store abbreviated book IDs (e.g., "rom", "mat", "psa").
    The Flutter app uses full canonical ids (e.g., "romans", "matthew", "psalms").
    """

    b = _norm_id(book_id)
    if not b:
        return []

    candidates: list[str] = []

    def add(value: str) -> None:
        v = _norm_id(value)
        if v and v not in candidates:
            candidates.append(v)

    add(b)

    # e.g. psalms -> psa, song_of_songs -> son (not perfect but helps)
    collapsed = b.replace("_", "")
    if collapsed:
        add(collapsed[:3])
        add(collapsed[:4])

    # First word prefix.
    first = b.split("_", 1)[0]
    if first:
        add(first[:3])
        add(first[:4])

    # Numeric books: 1_samuel -> 1sa/1sam
    if first.isdigit() and "_" in b:
        rest = b.split("_", 1)[1].replace("_", "")
        if rest:
            add(f"{first}{rest[:2]}")
            add(f"{first}{rest[:3]}")
            add(f"{first}{rest[:4]}")

    return candidates


_RE_USFM_TAG = re.compile(r"\\[+\-]?[a-zA-Z0-9*]+")
_RE_STRONG_PIPE = re.compile(r"\|strong=\"[^\"]*\"")


def _clean_client_text(text: str) -> str:
    s = (text or "").strip()
    if not s:
        return s

    # Remove USFM footnotes/cross-refs and inline markers.
    s = re.sub(r"\\f\s+.*?\\f\*", " ", s, flags=re.DOTALL)
    s = re.sub(r"\\x\s+.*?\\x\*", " ", s, flags=re.DOTALL)
    s = _RE_USFM_TAG.sub(" ", s)
    s = _RE_STRONG_PIPE.sub("", s)

    # Fix spacing around apostrophes caused by tag stripping.
    s = re.sub(r"([\w])['\u2019]\s+([\w])", r"\1’\2", s)
    s = re.sub(r"\s+([,.;:!?])", r"\1", s)
    s = s.replace("\u00a0", " ")
    s = re.sub(r"\s+", " ", s)
    return s.strip()


def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/")
async def root() -> dict[str, str]:
    return {"name": "The Word App API", "status": "online"}


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/debug/info")
def debug_info(db=Depends(db_session)):
    """Lightweight diagnostic endpoint for local dev.

    Helps confirm the API is connected to the expected Postgres DB and that the
    verses table contains the requested translation/books.
    """

    url = get_database_url()
    # Redact password if present.
    safe_url = url
    if "://" in safe_url and "@" in safe_url:
        scheme, rest = safe_url.split("://", 1)
        if ":" in rest.split("@", 1)[0]:
            user, _pw = rest.split(":", 1)
            safe_url = f"{scheme}://{user}:***@{rest.split('@', 1)[1]}"

    total = db.execute(select(func.count()).select_from(Verse)).scalar_one()
    translations = db.execute(select(Verse.translation, func.count()).group_by(Verse.translation).order_by(Verse.translation)).all()

    commentary_total = db.execute(select(func.count()).select_from(Commentary)).scalar_one()
    commentary_by_style = db.execute(
        select(Commentary.style, func.count()).group_by(Commentary.style).order_by(Commentary.style)
    ).all()

    # A quick sample of book_id values for web (or whatever casing exists).
    web_ids = db.execute(
        select(Verse.book_id)
        .where(func.lower(Verse.translation) == "web")
        .group_by(Verse.book_id)
        .order_by(Verse.book_id)
        .limit(40)
    ).all()

    # Sanity-check for common chapters.
    romans7 = db.execute(
        select(func.count())
        .select_from(Verse)
        .where(func.lower(Verse.translation) == "web")
        .where(Verse.chapter == 7)
        .where(func.lower(func.trim(Verse.book)).like("%roman%"))
    ).scalar_one()

    psalm23 = db.execute(
        select(func.count())
        .select_from(Verse)
        .where(func.lower(Verse.translation) == "web")
        .where(Verse.chapter == 23)
        .where(func.lower(func.trim(Verse.book)).like("%psalm%"))
    ).scalar_one()

    return {
        "database_url": safe_url,
        "verses_total": int(total),
        "commentary_total": int(commentary_total),
        "commentary_by_style": [{"style": s, "count": int(c)} for (s, c) in commentary_by_style],
        "translations": [{"translation": t, "count": int(c)} for (t, c) in translations],
        "web_book_ids_sample": [b for (b,) in web_ids],
        "web_romans7_count_by_bookname": int(romans7),
        "web_psalm23_count_by_bookname": int(psalm23),
    }


@app.get("/verse", response_model=VerseOut)
def get_verse(translation: str, bookId: str, chapter: int, verse: int, db=Depends(db_session)):
    translation = _norm_id(translation)
    bookId = _norm_id(bookId)
    book_ids = _book_id_candidates(bookId)
    stmt = select(Verse).where(
        func.lower(Verse.translation) == translation,
        func.lower(Verse.book_id).in_(book_ids) if book_ids else func.lower(Verse.book_id) == bookId,
        Verse.chapter == chapter,
        Verse.verse == verse,
    )
    row = db.execute(stmt).scalar_one_or_none()
    if row is None:
        # Fallback for datasets that use abbreviated book_id values (e.g., "rom")
        # while the client sends full ids (e.g., "romans").
        book_key = _norm_book_key(bookId)
        stmt2 = select(Verse).where(
            func.lower(Verse.translation) == translation,
            (
                (_book_name_expr() == book_key)
                | (_book_name_expr().like(f"{book_key}%"))
                | (_book_name_expr().like(f"%{book_key}%"))
            ),
            Verse.chapter == chapter,
            Verse.verse == verse,
        )
        row = db.execute(stmt2).scalar_one_or_none()
        if row is None:
            raise HTTPException(status_code=404, detail="Verse not found")

    return VerseOut(
        translation=row.translation,
        bookId=row.book_id,
        book=row.book,
        chapter=row.chapter,
        verse=row.verse,
        text=_clean_client_text(row.text),
    )


@app.get("/chapter", response_model=ChapterOut)
def get_chapter(translation: str, bookId: str, chapter: int, db=Depends(db_session)):
    translation = _norm_id(translation)
    bookId = _norm_id(bookId)
    book_ids = _book_id_candidates(bookId)
    stmt = (
        select(Verse)
        .where(
            func.lower(Verse.translation) == translation,
            func.lower(Verse.book_id).in_(book_ids) if book_ids else func.lower(Verse.book_id) == bookId,
            Verse.chapter == chapter,
        )
        .order_by(Verse.verse.asc())
    )
    verses = db.execute(stmt).scalars().all()
    if not verses:
        book_key = _norm_book_key(bookId)
        stmt2 = (
            select(Verse)
            .where(
                func.lower(Verse.translation) == translation,
                (
                    (_book_name_expr() == book_key)
                    | (_book_name_expr().like(f"{book_key}%"))
                    | (_book_name_expr().like(f"%{book_key}%"))
                ),
                Verse.chapter == chapter,
            )
            .order_by(Verse.verse.asc())
        )
        verses = db.execute(stmt2).scalars().all()
        if not verses:
            raise HTTPException(status_code=404, detail="Chapter not found")

    first = verses[0]
    return ChapterOut(
        translation=translation,
        bookId=first.book_id,
        book=first.book,
        chapter=chapter,
        verses=[
            VerseOut(
                translation=v.translation,
                bookId=v.book_id,
                book=v.book,
                chapter=v.chapter,
                verse=v.verse,
                text=_clean_client_text(v.text),
            )
            for v in verses
        ],
    )


@app.get("/search", response_model=SearchOut)
def search(translation: str, q: str, limit: int = 50, db=Depends(db_session)):
    translation = _norm_id(translation)
    query = (q or "").strip()
    if not query:
        return SearchOut(translation=translation, q=q, verses=[])

    # Simple MVP keyword search. For performance later: add tsvector + GIN.
    stmt = (
        select(Verse)
        .where(func.lower(Verse.translation) == translation)
        .where(Verse.text.ilike(f"%{query}%"))
        .limit(min(max(limit, 1), 200))
    )
    verses = db.execute(stmt).scalars().all()

    return SearchOut(
        translation=translation,
        q=q,
        verses=[
            VerseOut(
                translation=v.translation,
                bookId=v.book_id,
                book=v.book,
                chapter=v.chapter,
                verse=v.verse,
                text=_clean_client_text(v.text),
            )
            for v in verses
        ],
    )


@app.get("/commentary", response_model=CommentaryOut)
def get_commentary(translation: str, bookId: str, chapter: int, verse: int, style: str = "simple", db=Depends(db_session)):
    translation = _norm_id(translation)
    bookId = _norm_id(bookId)
    stmt = select(Verse).where(
        func.lower(Verse.translation) == translation,
        func.lower(Verse.book_id) == bookId,
        Verse.chapter == chapter,
        Verse.verse == verse,
    )
    v = db.execute(stmt).scalar_one_or_none()
    if v is None:
        book_key = _norm_book_key(bookId)
        stmt2 = select(Verse).where(
            func.lower(Verse.translation) == translation,
            (
                (_book_name_expr() == book_key)
                | (_book_name_expr().like(f"{book_key}%"))
                | (_book_name_expr().like(f"%{book_key}%"))
            ),
            Verse.chapter == chapter,
            Verse.verse == verse,
        )
        v = db.execute(stmt2).scalar_one_or_none()
        if v is None:
            raise HTTPException(status_code=404, detail="Verse not found")

    stmt_c = select(Commentary).where(Commentary.verse_id == v.id, Commentary.style == style)
    c = db.execute(stmt_c).scalar_one_or_none()
    if c is None:
        raise HTTPException(status_code=404, detail="Commentary not found")

    return CommentaryOut(
        translation=translation,
        bookId=bookId,
        chapter=chapter,
        verse=verse,
        style=style,
        text=c.text,
        insight=_parse_commentary_insight(c.payload_json),
    )


@app.post("/commentary/ensure", response_model=GenerateCommentaryResponse)
async def ensure_commentary(req: GenerateCommentaryRequest, db=Depends(db_session)):
    req.translation = _norm_id(req.translation)
    req.bookId = _norm_id(req.bookId)
    stmt = select(Verse).where(
        func.lower(Verse.translation) == req.translation,
        func.lower(Verse.book_id) == req.bookId,
        Verse.chapter == req.chapter,
        Verse.verse == req.verse,
    )
    v = db.execute(stmt).scalar_one_or_none()
    if v is None:
        book_key = _norm_book_key(req.bookId)
        stmt2 = select(Verse).where(
            func.lower(Verse.translation) == req.translation,
            (
                (_book_name_expr() == book_key)
                | (_book_name_expr().like(f"{book_key}%"))
                | (_book_name_expr().like(f"%{book_key}%"))
            ),
            Verse.chapter == req.chapter,
            Verse.verse == req.verse,
        )
        v = db.execute(stmt2).scalar_one_or_none()
        if v is None:
            raise HTTPException(status_code=404, detail="Verse not found")

    stmt_c = select(Commentary).where(
        Commentary.verse_id == v.id,
        Commentary.style == req.style,
        Commentary.language == req.language,
    )
    existing = db.execute(stmt_c).scalar_one_or_none()
    if existing is not None and not getattr(req, "overwrite", False):
        return GenerateCommentaryResponse(
            explanation=existing.text,
            insight=_parse_commentary_insight(existing.payload_json),
            stored=False,
        )

    try:
        explanation, insight, model = await generate_commentary(
            book=v.book,
            chapter=v.chapter,
            verse=v.verse,
            text=v.text,
        )
    except httpx.HTTPStatusError as e:
        status = e.response.status_code
        if status == 429:
            raise HTTPException(status_code=429, detail=f"LLM rate-limited: {e}")
        raise HTTPException(status_code=502, detail=f"LLM upstream error ({status}): {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM generation failed: {e}")

    payload_json = json.dumps(insight, ensure_ascii=False, separators=(",", ":"))
    c = Commentary(
        verse_id=v.id,
        style=req.style,
        language=req.language,
        model=model,
        text=explanation,
        payload_json=payload_json,
    )
    if existing is not None:
        existing.text = explanation
        existing.model = model
        existing.payload_json = payload_json
    else:
        db.add(c)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        # Another request may have stored it; refetch.
        stmt_c2 = select(Commentary).where(
            Commentary.verse_id == v.id,
            Commentary.style == req.style,
            Commentary.language == req.language,
        )
        again = db.execute(stmt_c2).scalar_one_or_none()
        if again is None:
            raise HTTPException(status_code=500, detail="Failed to store commentary")
        return GenerateCommentaryResponse(
            explanation=again.text,
            insight=_parse_commentary_insight(again.payload_json),
            stored=False,
        )

    return GenerateCommentaryResponse(
        explanation=explanation,
        insight=CommentaryInsight(**insight),
        stored=True,
    )


@app.post("/audio", response_model=AudioResponse)
async def get_audio(from_req: Request, req: AudioRequest, db=Depends(db_session)):
    # Debug logging
    logger.info(f"[AUDIO] Request: translation={req.translation}, bookId={req.bookId}, chapter={req.chapter}, verse={req.verse}")
    
    # 1. Fetch verse text
    stmt = select(Verse).where(
        func.lower(Verse.translation) == _norm_id(req.translation),
        func.lower(Verse.book_id) == _norm_id(req.bookId),
        Verse.chapter == req.chapter,
        Verse.verse == req.verse,
    )
    v = db.execute(stmt).scalar_one_or_none()
    if v is None:
        # Try candidate matching if direct fails (casing/underscores)
        book_ids = _book_id_candidates(req.bookId)
        logger.info(f"[AUDIO] First lookup failed, trying candidates: {book_ids}")
        stmt2 = select(Verse).where(
            func.lower(Verse.translation) == _norm_id(req.translation),
            func.lower(Verse.book_id).in_(book_ids),
            Verse.chapter == req.chapter,
            Verse.verse == req.verse,
        )
        v = db.execute(stmt2).scalar_one_or_none()
        if v is None:
            logger.info(f"[AUDIO] Verse not found in database!")
            raise HTTPException(status_code=404, detail="Verse not found")

    # 2. Generate or fetch cached audio
    text = _clean_client_text(v.text)
    logger.info(f"[AUDIO] Verse text for {v.book_id} {v.chapter}:{v.verse}: \"{text[:50]}...\"")
    path_segment = await generate_verse_audio(
        book_id=v.book_id, chapter=v.chapter, verse=v.verse, text=text
    )

    if not path_segment:
        raise HTTPException(
            status_code=500, detail="Failed to generate audio (is API key set?)"
        )

    # 3. Return absolute URL
    base = str(from_req.base_url).rstrip("/")
    final_url = f"{base}/static/{path_segment}"
    logger.info(f"[AUDIO] Returning URL: {final_url}")
    return AudioResponse(url=final_url)
