# Simple Bible App (Flutter)

This workspace contains a starter Flutter UI plus the data/offline/audio scaffolding needed for the next upgrades:

- Real Bible data via JSON assets (MVP: KJV + WEB)
- Translation switch (KJV/WEB bundled; others require licensed data)
- Simplified commentary storage (AI-ready)
- Offline favorites + notes (Hive)
- Audio Bible hook (Polly/OpenVoice-ready via backend)

## Run (once Flutter is installed)

```powershell
flutter pub get
flutter run
```

## Data files (MVP)

- Bundled sample data lives in:
  - `assets/data/bibles/kjv_sample.json`
  - `assets/data/bibles/web_sample.json`
  - `assets/data/commentary/sample_commentary.json`

To use full KJV/WEB data, keep the same JSON shape and either:

1. Replace `*_sample.json` with full verse lists, or
2. Split by chapter and update the asset paths in `lib/data/bible/bible_asset_paths.dart`.

## AI commentary (optional)

Set a backend endpoint (your server) that returns simplified commentary:

- Build/run with:

```powershell
flutter run --dart-define=COMMENTARY_API_URL=https://your-server.example/commentary
```

Expected response:

```json
{ "explanation": "1-2 sentence simple explanation..." }
```

## Audio (optional)

Polly/OpenVoice require a backend to generate audio. Configure:

```powershell
flutter run --dart-define=AUDIO_API_URL=https://your-server.example/audio
```

Your backend can return either a signed MP3 URL or raw bytes; see `lib/data/audio/remote_audio_bible_service.dart`.
