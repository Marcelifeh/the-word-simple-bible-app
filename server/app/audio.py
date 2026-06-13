import os
from pathlib import Path
import httpx
from .env import load_app_env

load_app_env()

def _env(name: str, default: str | None = None) -> str | None:
    v = os.getenv(name)
    if v is None or v.strip() == "":
        return default
    return v

# Directory where generated audio files will be stored
# We'll place them in server/static to keep the server self-contained.
_SERVER_ROOT = Path(__file__).parent.parent
STATIC_DIR = _SERVER_ROOT / "static"
AUDIO_DIR = STATIC_DIR / "audio"

# Ensure directories exist at startup
STATIC_DIR.mkdir(parents=True, exist_ok=True)
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

async def generate_verse_audio(*, book_id: str, chapter: int, verse: int, text: str) -> str | None:
    """Generate audio for a verse using ElevenLabs and return the local path segment.
    
    Returns: "audio/filename.mp3" or None if failed.
    """
    api_key = _env("ELEVENLABS_API_KEY")
    voice_id = _env("ELEVENLABS_VOICE_ID", "21m00Tcm4TlvDq8ikWAM")
    
    if not api_key or api_key == "YOUR_API_KEY_HERE":
        print("ElevenLabs API Key not configured.")
        return None
        
    filename = f"{book_id}_{chapter}_{verse}.mp3"
    file_path = AUDIO_DIR / filename
    
    # Simple caching: return existing file if it exists
    if file_path.exists():
        print(f"[AUDIO] Cache hit for {filename}")
        return f"audio/{filename}"
    
    print(f"[AUDIO] Generating new audio for {filename}...")
    
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key
    }
    data = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5
        }
    }
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.post(url, json=data, headers=headers)
            response.raise_for_status()
            
            with open(file_path, "wb") as f:
                f.write(response.content)
            
            return f"audio/{filename}"
        except Exception as e:
            print(f"Error generating audio from ElevenLabs: {e}")
            return None
