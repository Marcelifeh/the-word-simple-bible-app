# Simple Bible Backend (PostgreSQL + AI Commentary)

This folder provides a small backend that:

- Stores Bible verses (KJV/WEB) in PostgreSQL
- Generates and stores simplified commentary verse-by-verse using an OpenAI-compatible API
- Serves the Flutter app via HTTP endpoints

## 1) Start Postgres + API (Docker)

```powershell
cd server
docker compose up --build
```

API runs at `http://localhost:8000`.

## Fresh Start (Local PostgreSQL, no Docker)

If you have PostgreSQL installed on your machine, you can reset everything and re-import **WEB + KJV** from official USFM ZIP sources.

1) Set your local DB URL in `server/app/.env` (recommended) **or** pass it on the command line.

Example for local Postgres (adjust user/password/db/port):

```dotenv
DATABASE_URL=postgresql+psycopg://postgres:YOUR_PASSWORD@localhost:5432/bible
```

2) Reset schema + download + convert + import:

From the repo root:

```powershell
& "C:\Users\hp\The_word_simple_bible_app\server\.venv\Scripts\python.exe" "C:\Users\hp\The_word_simple_bible_app\tools\reset_reimport_local_postgres.py" --database-url postgresql://postgres:YOUR_PASSWORD@localhost:5432/bible
```

This will:
- Drop and recreate tables using `server/schema.sql`
- Download WEB + KJV USFM zips into `downloads/`
- Convert them into `downloads/web_flat.json` and `downloads/kjv_flat.json`
- Import both translations into Postgres

3) Start the API locally:

```powershell
cd server
\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

For local development with reload on Windows, use the project runner. It watches
only `server/app` instead of the whole `server` folder, avoiding slow reload
startup caused by scanning `.venv` and generated static files:

```powershell
cd server
.\start_dev.ps1
```

Equivalent direct command:

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload --reload-dir app
```

4) Regenerate commentary (this uses your LLM API key; start with a limit first):

```powershell
& "C:\Users\hp\The_word_simple_bible_app\server\.venv\Scripts\python.exe" "C:\Users\hp\The_word_simple_bible_app\tools\generate_commentary_to_postgres.py" --translation web --api http://127.0.0.1:8000 --limit 200 --sleep 0.2
```

## 2) Run migrations (optional but recommended)

For MVP the API also runs `create_all()` at startup, but migrations are included.

```powershell
cd server
$env:DATABASE_URL = "postgresql+psycopg://bible:bible@localhost:5433/bible"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
alembic -c alembic.ini upgrade head
```

## 3) Import real KJV/WEB JSON

The importer expects a JSON array like:

```json
{"bookId":"john","book":"John","chapter":3,"verse":16,"text":"..."}
```

Run:

```powershell
$env:DATABASE_URL = "postgresql://bible:bible@localhost:5433/bible"
python ..\tools\import_bible_to_postgres.py kjv ..\path\to\kjv_full.json
python ..\tools\import_bible_to_postgres.py web ..\path\to\web_full.json
```

## 4) Enable AI generation

Set env vars for the API container or your local run.

This repo will automatically load `server/app/.env` if it exists (recommended for local dev).

- `LLM_API_KEY` (required)
- `LLM_BASE_URL` (default `https://api.openai.com/v1`)
- `LLM_MODEL` (default `gpt-4o-mini`, or use `gpt-4.1-mini`)

Security note: never commit `.env` files with secrets.

Then the API endpoint below will generate + store commentary:

- `POST /commentary/ensure`

## 5) Connect Flutter to Postgres-backed API

Run Flutter with:

```powershell
flutter run -d chrome --dart-define=BIBLE_API_URL=http://localhost:8000 --dart-define=COMMENTARY_API_URL=http://localhost:8000/commentary/ensure
```

Notes:
- If `BIBLE_API_URL` is not set, the app falls back to loading verses from assets.
- If `COMMENTARY_API_URL` is not set, the app uses the local Hive + seed fallback.
