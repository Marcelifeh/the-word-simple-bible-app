import asyncio
import json
import os
import random

import httpx

from .env import load_app_env


load_app_env()


def _env(name: str, default: str | None = None) -> str | None:
    v = os.getenv(name)
    if v is None or v.strip() == "":
        return default
    return v


def _extract_json_payload(content: str) -> dict[str, object]:
    text = (content or "").strip()
    if not text:
        raise RuntimeError("Empty LLM response")

    if text.startswith("```"):
        text = text.strip()
        if text.startswith("```json"):
            text = text[len("```json"):]
        elif text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise RuntimeError("LLM response was not valid JSON")
        decoded = json.loads(text[start : end + 1])

    if not isinstance(decoded, dict):
        raise RuntimeError("LLM response JSON must be an object")
    return decoded


def _normalize_insight_payload(payload: dict[str, object]) -> dict[str, object]:
    normalized: dict[str, object] = {}
    for key in ("understanding", "deepInsight", "keyTruth", "reflection"):
        value = str(payload.get(key, "") or "").strip()
        if not value:
            raise RuntimeError(f"LLM response missing required field: {key}")
        normalized[key] = value

    try:
        normalized["styleVersion"] = int(payload.get("styleVersion") or 2)
    except Exception as exc:
        raise RuntimeError("LLM response styleVersion must be an integer") from exc

    return normalized


def render_commentary_text(insight: dict[str, object]) -> str:
    return "\n".join(
        [
            f"🕊 Understanding\n{insight['understanding']}",
            f"🔥 Deep Insight\n{insight['deepInsight']}",
            f"✨ Key Truth\n{insight['keyTruth']}",
            f"🌱 Reflection\n{insight['reflection']}",
        ]
    )


def build_prompt(*, book: str, chapter: int, verse: int, text: str) -> str:
    # Premium insight format = concise, spiritually grounded, mobile-friendly.
    return (
        "Write a spiritually reflective Bible insight for mobile reading in plain English. "
        "Return valid JSON only. Use exactly these camelCase keys: understanding, deepInsight, keyTruth, reflection, styleVersion. "
        "Do not add markdown fences, headings, bullets, numbering, intro, or outro. "
        "Keep the tone warm, spiritually grounded, emotionally intelligent, and concise. "
        "Do not sound preachy, academic, sermon-like, or generic. Avoid cliches and motivational filler. "
        "Use a consistent voice: address the reader as 'you' when needed, and do not switch to 'we/us/our'. "
        "When referring to the person in the verse, name them specifically when known (for example: the psalmist, Jesus, Paul). "
        "Use correct gendered pronouns for known individuals instead of vague plurals. "
        "Length rules: Understanding must be 1-2 short sentences, about 25-40 words total. "
        "Deep Insight must be 2 concise reflective sentences, about 35-55 words total. "
        "Key Truth must be one short line, about 6-14 words. "
        "Reflection must be one powerful sentence, about 10-18 words. "
        "Explain the verse plainly first, then reveal the deeper spiritual truth, then give a single-line takeaway, then end with an invitation or self-examining response. "
        "Set styleVersion to 2. "
        "Do not mention that you are an AI.\n\n"
        f"Reference: {book} {chapter}:{verse}\n"
        f"Verse: {text}\n"
    )


async def generate_commentary(*, book: str, chapter: int, verse: int, text: str) -> tuple[str, dict[str, object], str]:
    """Generate commentary using an OpenAI-compatible Chat Completions API.

    Returns: (rendered_text, structured_payload, model_used)
    """
    base_url = _env("LLM_BASE_URL", "https://api.openai.com/v1")
    api_key = _env("LLM_API_KEY")
    model = _env("LLM_MODEL", "gpt-4o-mini")
    max_retries = int(_env("LLM_MAX_RETRIES", "6") or "6")
    base_sleep = float(_env("LLM_RETRY_BASE_SECONDS", "1.0") or "1.0")
    max_sleep = float(_env("LLM_RETRY_MAX_SECONDS", "30.0") or "30.0")

    if not api_key:
        raise RuntimeError("LLM_API_KEY is not set")

    prompt = build_prompt(book=book, chapter=chapter, verse=verse, text=text)

    async with httpx.AsyncClient(base_url=base_url, timeout=60.0) as client:
        last_exc: Exception | None = None
        for attempt in range(max_retries + 1):
            try:
                res = await client.post(
                    "/chat/completions",
                    headers={"Authorization": f"Bearer {api_key}"},
                    json={
                        "model": model,
                        "messages": [
                            {
                                "role": "system",
                                "content": (
                                    "You write spiritually reflective Bible insights that feel warm, concise, and clear on mobile. "
                                    "Always return valid JSON with the required camelCase keys only. "
                                    "Keep a consistent second-person singular voice ('you') when direct address is useful. "
                                    "Never switch to 'we/us/our'."
                                ),
                            },
                            {"role": "user", "content": prompt},
                        ],
                        "temperature": 0.4,
                    },
                )
                res.raise_for_status()
                data = res.json()
                break
            except httpx.HTTPStatusError as e:
                last_exc = e
                status = e.response.status_code

                # Retry on rate limits and transient upstream errors.
                retryable = status in {408, 409, 425, 429, 500, 502, 503, 504}
                if not retryable or attempt >= max_retries:
                    raise

                retry_after = 0.0
                ra = e.response.headers.get("retry-after")
                if ra:
                    try:
                        retry_after = float(ra)
                    except Exception:
                        retry_after = 0.0

                # Exponential backoff + jitter, capped.
                sleep_for = max(retry_after, min(max_sleep, base_sleep * (2**attempt)))
                sleep_for = sleep_for * (1.0 + random.random() * 0.2)
                await asyncio.sleep(sleep_for)
            except (httpx.ReadTimeout, httpx.ConnectTimeout, httpx.ConnectError) as e:
                last_exc = e
                if attempt >= max_retries:
                    raise
                sleep_for = min(max_sleep, base_sleep * (2**attempt))
                sleep_for = sleep_for * (1.0 + random.random() * 0.2)
                await asyncio.sleep(sleep_for)
        else:
            # Defensive: should not reach here.
            if last_exc:
                raise last_exc
            raise RuntimeError("LLM request failed")

    content = (
        data.get("choices", [{}])[0]
        .get("message", {})
        .get("content", "")
    )
    insight = _normalize_insight_payload(_extract_json_payload(content or ""))

    return render_commentary_text(insight), insight, model
