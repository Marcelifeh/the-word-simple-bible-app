# Upgrade Design (Proposed v1.0)

This document proposes an upgraded version of **Simple Bible App** (Flutter) and its optional **FastAPI + Postgres** backend.

The goal is to keep your current UX concept (Home + Bible + Search + Favorites, with inline commentary/audio/share) but make the system:

- More reliable (assets vs API fallbacks behave predictably)
- More consistent (same verse text cleaning everywhere)
- More scalable (full Bible + more translations without performance cliffs)
- Easier to maintain (clear boundaries, fewer “special cases”)

---

## 1) Current State (What’s already good)

### Flutter app
- Navigation: `MainShell` uses a bottom bar + **one Navigator per tab** to preserve tab state.
- State: a single `AppState` provides repositories/services via `AppScope`.
- Data sources:
  - Bible loads from **assets** when `BIBLE_API_URL` is unset.
  - Bible loads from **HTTP API** when `BIBLE_API_URL` is set.
- Storage:
  - Hive is used for settings, favorites, and cached commentaries.
- Reading experience:
  - `ReadingScreen` renders verses with expandable “Simple Explanation”, and includes Save/Audio/Share.
- Search:
  - If API is configured: uses `/search`.
  - Otherwise: builds an offline token index from chapter assets.

### Backend
- FastAPI endpoints exist for health, chapter, verse, search, commentary read, and commentary generation (`/commentary/ensure`).
- Commentary generation uses an OpenAI-compatible Chat Completions API with retry/backoff.

---

## 2) Observations / Pain Points

These are the main sources of complexity or user-facing rough edges.

### A) Text normalization is inconsistent
- Backend cleans USFM markers for `/verse` and `/chapter`, but `/search` currently returns raw text.
- Flutter also strips some USFM markers in `SearchScreen`, but not in all places.

**Impact:** the same verse can look different depending on where it’s viewed.

### B) Data availability varies (chapter assets are partial)
- Assets include some sample content (e.g., John/Psalms) for several translations.
- Many books/chapters may not exist in assets, which causes “empty chapter” experiences.

**Impact:** users think the app is broken when they pick a book that isn’t bundled.

### C) Search has two very different behaviors
- API search is substring match in Postgres.
- Offline search builds a token→verseKey map on-demand; the initial build can be heavy.

**Impact:** the first offline search can feel slow/hang; results vary by mode.

### D) A few “emergency” fallbacks creep into UI logic
- Example: a hard-coded Genesis 1:1 fallback in `ReadingScreen`.

**Impact:** makes correctness harder to reason about and can hide real data issues.

### E) Favorites are keyed only by `ref.key` (bookId.chapter.verse)
- They are not namespaced by translation.

**Impact:** a saved verse in KJV and WEB will collide (same key).

---

## 3) Target Architecture (Upgraded Design)

Keep the current folder layout (`app/`, `core/`, `data/`, `domain/`, `features/`) but tighten responsibilities.

### 3.1 Flutter: Layer responsibilities

**Domain**
- Entities stay as-is (`Verse`, `VerseRef`, `BibleTranslation`, etc.)
- Add small value types where needed (e.g., `BibleError`, `NetworkError`, `DataMissingError`).

**Data**
- Repositories remain interfaces, but introduce explicit “sources”:
  - `BibleLocalSource` (assets)
  - `BibleRemoteSource` (API)
  - `CommentaryLocalSource` (Hive + seed)
  - `CommentaryRemoteSource` (API)
- Repositories become orchestrators:
  - `BibleRepositoryImpl` decides when to use remote vs local and caches.
  - `CommentaryRepositoryImpl` decides when to generate vs read.

**Features**
- Each feature gets a controller/state object (still using `ChangeNotifier` if you want to stay simple):
  - `ReadingController` (loads chapter, manages selected verse expansion state, handles audio/share)
  - `SearchController` (parsing, searching, loading results)
  - `FavoritesController` (list, notes)

**App**
- `AppState` becomes a composition root:
  - wires controllers to repos
  - keeps user settings
  - exposes only what UI needs

> Optional: If you want a larger jump, you could adopt Riverpod for dependency injection and state management. It’s not required for the upgrade.

### 3.2 Contracts

Make these contracts explicit and stable:

- Bible API base URL (`BIBLE_API_URL`) is a server root (e.g. `http://127.0.0.1:8000`).
- Commentary API base URL (`COMMENTARY_API_URL`) can be either:
  - the server root, or
  - a direct `/commentary/ensure` URL.
- Audio API URL (`AUDIO_API_URL`) is a direct endpoint that returns `{ "url": "https://...mp3" }`.

### 3.3 Consistent Verse Text Cleaning (single source of truth)

Introduce one shared sanitizer used everywhere (asset + API + search results):

- `BibleTextSanitizer.clean(String)`

Rules:
- Remove USFM tags and WordLink markers
- Normalize whitespace
- Keep punctuation readable

Backend should also apply the same cleaning to **all** verse outputs (`/verse`, `/chapter`, `/search`).

---

## 4) Proposed Roadmap (Phased)

## 4.1 Decisions (Locked In)

These choices guide the rest of the upgrade.

- **Offline-first (now):** assets are the primary Bible source. The app must remain fully usable without any server.
- **API-first (later):** we will add an optional mode where the server becomes the primary Bible/search source (useful for smaller app sizes and quicker updates).
- **Non-English translations:** treat them like English ones (full dataset), subject to licensing/permissions.
- **Search:** “smart” search with ranking + stemming.

### Phase 0 (1–2 hours): Consistency + correctness
- Backend: apply verse cleaning to `/search` results.
- Flutter: centralize verse text cleaning and use it in Search + Reading.
- Favorites: namespace storage key by translation (e.g., `web:john.3.16`).

### Phase 1 (1–2 days): Data availability clarity
- Add a clear “data not bundled” message when a chapter is missing in assets.
- Remove any hard-coded emergency verse fallback.
- Improve asset structure tooling:
  - chapter-per-file is already supported; lean into it for full Bible.

### Phase 1.5 (1–3 days): Full datasets for non-English translations
- Adopt the same chapter-per-file asset layout for every included translation:
  - `assets/data/bibles/<translation>/<bookId>/<chapter>.json`
- Add/extend tooling to validate:
  - All books/chapter counts match the canonical catalog
  - JSON schema matches `Verse.fromJson` expectations
  - Spot-check sampling output for display

Notes:
- Some translations are not freely redistributable. “Full dataset” is feasible only for translations you have permission to bundle (or that are public domain / permissively licensed). If a translation is licensed, the technical plan shifts to download-on-first-run or API-only for that translation.

### Phase 2 (2–4 days): Search improvements

#### Phase 2A (Offline-first): Smart offline search

Goal: ranked results + stemming without requiring the API.

Implementation options (pick one):

1) **SQLite FTS (preferred for ranking):** build an on-device database with FTS and use BM25 ranking.
   - Pros: strong ranking, good performance, scalable.
   - Cons: adds complexity (especially for Flutter Web).

2) **Custom inverted index (Dart):** persist a token→posting list index (and token positions) and compute a BM25-like score in Dart.
   - Pros: works without native SQLite; predictable.
   - Cons: more code; needs careful memory/storage tuning.

Stemming plan:
- Use language-aware stemming where available (Snowball-style) and fall back to “no stemming” per-language if needed.
- For English, Porter stemming is usually sufficient.

Deliverables:
- Background build + progress marker (avoid “first search is slow”).
- Ranked top-N results.
- Consistent tokenization and verse-text cleaning.

#### Phase 2B (API mode): Smart server search

Goal: when the API is enabled, server search becomes best-in-class and consistent with offline.

- PostgreSQL FTS:
  - `tsvector` column + GIN index
  - `plainto_tsquery` / `websearch_to_tsquery`
  - Rank with `ts_rank_cd` (or similar)
- Optional: language-specific dictionaries/configurations for stemming.
- Return ranked results with a score and consistent verse cleaning.

### Phase 3 (2–4 days): Commentary & audio reliability
- Commentary:
  - Add “loading / retry” states per verse expansion.
  - Add exponential backoff on the client as well.
- Audio:
  - Add stop/pause behavior and short-term caching of URLs.

### Phase 4 (ongoing): Quality
- Add focused tests:
  - sanitizer unit tests
  - search parser tests
  - repository contract tests (asset parsing shapes)

---

## 5) Quick Wins I can implement next (pick 1–3)

1) Backend: clean verse text in `/search` responses (match `/chapter` behavior).
2) Flutter: add `BibleTextSanitizer` and use it everywhere verses are displayed.
3) Favorites: include translation in Hive key to avoid collisions.
4) Remove the Genesis 1:1 hard-coded emergency fallback and show a proper “missing data” message.

---

## 6) Open Questions (to lock the upgrade scope)

Locked decisions:
- Offline-first now; API-first later.
- Non-English translations should be full datasets (where licensing allows).
- Search should be smart (ranked + stemming).

One remaining practical question:
- Do you need **Flutter Web** to support the same smart offline search (true offline), or is “smart offline search” primarily for Android/iOS/desktop while Web can use API search when available?

Decision:
- **Smart offline search targets Android/iOS/desktop.**
- **Flutter Web can rely on API search when available.** If the API is not available on Web, use a basic fallback (current token index or simple substring scan) or show a clear “Search requires server on Web” message, depending on the desired UX.
