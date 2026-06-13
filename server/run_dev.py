from __future__ import annotations

import os
from pathlib import Path

import uvicorn


def main() -> None:
    server_dir = Path(__file__).resolve().parent
    app_dir = server_dir / "app"

    uvicorn.run(
        "app.main:app",
        host=os.getenv("BIBLE_API_HOST", "127.0.0.1"),
        port=int(os.getenv("BIBLE_API_PORT", "8000")),
        reload=True,
        reload_dirs=[str(app_dir)],
    )


if __name__ == "__main__":
    main()
