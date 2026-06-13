from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request


def _get(url: str, timeout: float = 10.0) -> tuple[int, str]:
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return resp.status, resp.read().decode("utf-8", errors="replace")


def _post_json(url: str, payload: dict, timeout: float = 120.0) -> tuple[int, str]:
    req = urllib.request.Request(
        url=url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, resp.read().decode("utf-8", errors="replace")


def main() -> None:
    base = "http://127.0.0.1:8000"
    payloads = [
        {"translation": "kjv", "bookId": "ezekiel", "chapter": 7, "verse": 18, "style": "insight_premium_v2"},
        {"translation": "kjv", "bookId": "judges", "chapter": 2, "verse": 13, "style": "insight_premium_v2"},
        {"translation": "web", "bookId": "numbers", "chapter": 16, "verse": 45, "style": "insight_premium_v2"},
    ]

    try:
        status, body = _get(f"{base}/health")
        print(f"health: {status} {body}")
    except Exception as e:  # noqa: BLE001
        print(f"health_check_failed: {e}")
        sys.exit(2)

    for p in payloads:
        ref = f"{p['translation']} {p['bookId']} {p['chapter']}:{p['verse']}"
        try:
            status, body = _post_json(f"{base}/commentary/ensure", p)
            print(f"OK {ref} -> {status} {body[:200]}")
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="replace")
            print(f"FAIL {ref} -> {e.code} {body[:400]}")
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {ref} -> {e}")
        time.sleep(0.2)


if __name__ == "__main__":
    main()
