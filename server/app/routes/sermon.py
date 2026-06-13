from __future__ import annotations

import os
import re
import tempfile
from functools import lru_cache

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

router = APIRouter(prefix="/sermon", tags=["sermon"])


class SermonSummaryRequest(BaseModel):
    transcript: str


@lru_cache(maxsize=1)
def _whisper_model():
    try:
        from faster_whisper import WhisperModel
    except ImportError as exc:
        raise RuntimeError(
            "faster-whisper is not installed. Run `pip install faster-whisper` "
            "inside the server virtual environment."
        ) from exc

    model_name = os.getenv("SERMON_WHISPER_MODEL", "base")
    device = os.getenv("SERMON_WHISPER_DEVICE", "cpu")
    compute_type = os.getenv("SERMON_WHISPER_COMPUTE_TYPE", "int8")
    return WhisperModel(model_name, device=device, compute_type=compute_type)


@router.post("/transcribe")
async def transcribe_sermon(file: UploadFile = File(...)):
    suffix = os.path.splitext(file.filename or "sermon.m4a")[1] or ".m4a"

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    try:
        try:
            model = _whisper_model()
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=str(exc)) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Whisper model could not be loaded. The first run may need "
                    "internet access to download the model, then it will be cached."
                ),
            ) from exc

        try:
            segments_iter, info = model.transcribe(
                tmp_path,
                beam_size=5,
                vad_filter=True,
                vad_parameters={"min_silence_duration_ms": 500},
            )
        except Exception as exc:
            raise HTTPException(
                status_code=500,
                detail="Sermon audio could not be transcribed.",
            ) from exc
        segments = [
            {
                "start": round(segment.start, 2),
                "end": round(segment.end, 2),
                "text": segment.text.strip(),
            }
            for segment in segments_iter
            if segment.text.strip()
        ]
        transcript = " ".join(segment["text"] for segment in segments).strip()

        return {
            "transcript": transcript,
            "language": info.language or "unknown",
            "duration": round(info.duration or 0, 2),
            "segments": segments,
            "status": "ok",
        }
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


@router.post("/summary")
async def summarize_sermon(payload: SermonSummaryRequest):
    transcript = payload.transcript.strip()

    if not transcript:
        return {
            "summary": "",
            "error": "Transcript is empty.",
        }

    intelligence = _build_sermon_intelligence(transcript)

    return {
        "summary": _format_structured_summary(intelligence),
        **intelligence,
        "status": "ok",
    }


def _build_sermon_intelligence(transcript: str) -> dict[str, object]:
    sentences = _sentences(transcript)
    scriptures = _scripture_references(transcript)
    title = _title_from(sentences, scriptures)
    main_theme = _main_theme_from(sentences)
    key_lessons = _key_lessons_from(sentences)

    return {
        "title": title,
        "mainTheme": main_theme,
        "keyLessons": key_lessons,
        "scripturesMentioned": scriptures,
        "prayerPoints": _prayer_points_from(sentences, main_theme),
        "actionSteps": _action_steps_from(key_lessons, scriptures),
        "shortDevotional": _short_devotional_from(main_theme, key_lessons),
    }


def _sentences(text: str) -> list[str]:
    normalized = re.sub(r"\s+", " ", text).strip()
    parts = re.split(r"(?<=[.!?])\s+", normalized)
    return [part.strip() for part in parts if len(part.strip()) > 12]


def _scripture_references(text: str) -> list[str]:
    book_names = (
        r"(?:[1-3]\s*)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|"
        r"Judges|Ruth|Samuel|Kings|Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|"
        r"Proverbs|Ecclesiastes|Song of Solomon|Isaiah|Jeremiah|Lamentations|"
        r"Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|"
        r"Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|"
        r"Romans|Corinthians|Galatians|Ephesians|Philippians|Colossians|"
        r"Thessalonians|Timothy|Titus|Philemon|Hebrews|James|Peter|Jude|"
        r"Revelation)"
    )
    pattern = re.compile(
        rf"\b{book_names}\s+\d{{1,3}}(?::\d{{1,3}}(?:-\d{{1,3}})?)?\b",
        re.IGNORECASE,
    )
    found = []
    seen = set()
    for match in pattern.finditer(text):
        value = re.sub(r"\s+", " ", match.group(0)).strip()
        key = value.lower()
        if key not in seen:
            found.append(value)
            seen.add(key)
    return found[:20]


def _title_from(sentences: list[str], scriptures: list[str]) -> str:
    if scriptures:
        return f"Sermon Reflection on {scriptures[0]}"
    if not sentences:
        return "Sermon Reflection"
    first = re.sub(r"[^A-Za-z0-9 ,'-]", "", sentences[0])
    words = first.split()
    return " ".join(words[:8]) or "Sermon Reflection"


def _main_theme_from(sentences: list[str]) -> str:
    if not sentences:
        return "The sermon calls listeners to reflect on God's Word and respond in faith."
    strongest = _ranked_sentences(sentences, limit=1)[0]
    return strongest.rstrip(".!?") + "."


def _key_lessons_from(sentences: list[str]) -> list[str]:
    ranked = _ranked_sentences(sentences, limit=5)
    lessons = [sentence.rstrip(".!?") + "." for sentence in ranked[:5]]
    if lessons:
        return lessons
    return ["Receive God's Word with faith and put it into practice."]


def _prayer_points_from(sentences: list[str], main_theme: str) -> list[str]:
    prayer_sentences = [
        sentence.rstrip(".!?") + "."
        for sentence in sentences
        if re.search(r"\b(pray|prayer|lord|help us|father|spirit)\b", sentence, re.I)
    ]
    if prayer_sentences:
        return prayer_sentences[:3]
    return [
        "Ask God for grace to obey the message with humility.",
        f"Pray for the Holy Spirit to make this truth personal: {main_theme}",
    ]


def _action_steps_from(key_lessons: list[str], scriptures: list[str]) -> list[str]:
    steps = []
    if scriptures:
        steps.append(f"Read and meditate on {scriptures[0]} this week.")
    steps.append("Write one concrete obedience step from the sermon.")
    if key_lessons:
        steps.append(f"Discuss this lesson with someone you trust: {key_lessons[0]}")
    return steps[:4]


def _short_devotional_from(main_theme: str, key_lessons: list[str]) -> str:
    lesson = key_lessons[0] if key_lessons else main_theme
    return (
        f"Today, pause over this truth: {main_theme} "
        f"Let it move beyond listening into worship, prayer, and obedience. "
        f"Carry this lesson with you: {lesson}"
    )


def _ranked_sentences(sentences: list[str], limit: int) -> list[str]:
    keywords = (
        "god",
        "jesus",
        "christ",
        "lord",
        "spirit",
        "faith",
        "grace",
        "pray",
        "prayer",
        "scripture",
        "word",
        "obedience",
        "love",
        "forgive",
        "truth",
        "kingdom",
    )

    def score(sentence: str) -> tuple[int, int]:
        lower = sentence.lower()
        keyword_score = sum(1 for keyword in keywords if keyword in lower)
        length_score = min(len(sentence), 180)
        return keyword_score, length_score

    ranked = sorted(sentences, key=score, reverse=True)
    return ranked[:limit]


def _format_structured_summary(intelligence: dict[str, object]) -> str:
    def section_list(title: str, values: object) -> str:
        if not isinstance(values, list) or not values:
            return f"{title}:\n- None detected"
        return f"{title}:\n" + "\n".join(f"- {value}" for value in values)

    return "\n\n".join(
        [
            str(intelligence["title"]),
            f"Main Theme:\n{intelligence['mainTheme']}",
            section_list("Key Lessons", intelligence["keyLessons"]),
            section_list("Scriptures Mentioned", intelligence["scripturesMentioned"]),
            section_list("Prayer Points", intelligence["prayerPoints"]),
            section_list("Action Steps", intelligence["actionSteps"]),
            f"Short Devotional:\n{intelligence['shortDevotional']}",
        ]
    )
