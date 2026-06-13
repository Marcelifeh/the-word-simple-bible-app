from __future__ import annotations

import json
import urllib.request

BASE = "http://127.0.0.1:8000"


def main() -> None:
    with urllib.request.urlopen(f"{BASE}/health", timeout=10) as r:
        print("health", r.status, r.read().decode("utf-8", errors="replace"))

    with urllib.request.urlopen(
        f"{BASE}/chapter?translation=kjv&bookId=romans&chapter=8", timeout=20
    ) as r:
        data = json.loads(r.read().decode("utf-8", errors="replace"))
        v0 = data["verses"][0]
        print("chapter_first_verse", v0["bookId"], f"{v0['chapter']}:{v0['verse']}")

    payload = {"translation": "kjv", "bookId": "romans", "chapter": 8, "verse": 1, "style": "insight_premium_v2"}
    req = urllib.request.Request(
        f"{BASE}/commentary/ensure",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as r:
        out = json.loads(r.read().decode("utf-8", errors="replace"))
        print("commentary_stored", out.get("stored"))


if __name__ == "__main__":
    main()
