# Tools

## Download full KJV + WEB datasets (PowerShell)

This workspace can ingest Bible JSON as a **flat verse array**:

```json
{"bookId":"john","book":"John","chapter":3,"verse":16,"text":"..."}
```

Some public datasets are published in different shapes, so you may need a conversion step.

KJV (thiagobodruk/bible):

```powershell
New-Item -ItemType Directory -Force -Path .\downloads | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json" -UseBasicParsing -OutFile .\downloads\en_kjv.json
```

WEB (recommended open alternative: WEBU, CC0; ringletech/webu-open-bible):

```powershell
New-Item -ItemType Directory -Force -Path .\downloads | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ringletech/webu-open-bible/main/json/complete-bible.json" -UseBasicParsing -OutFile .\downloads\webu_complete-bible.json
```

Convert into the flat verse-array format this repo expects:

```powershell
python tools/convert_public_bible_json.py .\downloads\en_kjv.json .\downloads\kjv_full.json
python tools/convert_public_bible_json.py .\downloads\webu_complete-bible.json .\downloads\web_full.json
```

### True WEB (official public-domain text) via USFM ZIP

If you specifically want **WEB** (not WEBU/other variants), download the official USFM files from ebible.org and convert them:

```powershell
New-Item -ItemType Directory -Force -Path .\downloads | Out-Null
Invoke-WebRequest -Uri "https://ebible.org/Scriptures/eng-web_usfm.zip" -UseBasicParsing -OutFile .\downloads\eng-web_usfm.zip

# Convert USFM ZIP -> flat verse-array JSON (for import/splitting)
python tools/convert_web_usfm_zip.py .\downloads\eng-web_usfm.zip .\downloads\web_full.json

# Optional: include extra books if the ZIP contains them
# python tools/convert_web_usfm_zip.py --include-extra-books .\downloads\eng-web_usfm.zip .\downloads\web_full.json
```

## Split a full Bible JSON into chapter files

This repository supports a fast asset format:

- `assets/data/bibles/<translation>/<bookId>/<chapter>.json`


Run the splitter on a JSON array of verses:

```powershell
python tools/split_bible_json.py path\to\kjv_full.json assets\data\bibles\kjv
python tools/split_bible_json.py path\to\web_full.json assets\data\bibles\web
```

## Generate pubspec.yaml asset entries (recommended for full datasets)

Flutter does not reliably bundle nested asset subfolders unless they are listed.
When you split the Bible into book/chapter files, run:

```powershell
python tools/generate_pubspec_assets.py
flutter pub get
```

This will inject/update a generated block in `pubspec.yaml` between:

- `# BEGIN GENERATED BIBLE ASSETS`
- `# END GENERATED BIBLE ASSETS`

## Import verses into PostgreSQL (for real data + backend)

If you are using the included backend (`server/`) with Postgres, import your full JSON file:

```powershell
$env:DATABASE_URL = "postgresql://bible:bible@localhost:5433/bible"
python tools/import_bible_to_postgres.py kjv path\to\kjv_full.json
python tools/import_bible_to_postgres.py web path\to\web_full.json
```

## Generate AI simplified commentary into PostgreSQL (verse-by-verse)

Start the backend first and set your LLM env vars on the API container/process.
Then run:

```powershell
$env:DATABASE_URL = "postgresql://bible:bible@localhost:5433/bible"
python tools/generate_commentary_to_postgres.py --translation kjv --api http://localhost:8000
```
