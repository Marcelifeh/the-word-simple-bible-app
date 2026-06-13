from __future__ import annotations

from pathlib import Path

from dotenv import load_dotenv


_LOADED = False


def load_app_env() -> None:
    """Load environment variables from server/app/.env if present.

    This is intentionally lightweight and safe to call multiple times.
    """

    global _LOADED
    if _LOADED:
        return

    # 1. Load root .env first (../../.env)
    root_env = Path(__file__).parent.parent.parent / ".env"
    if root_env.exists():
        load_dotenv(dotenv_path=root_env, override=True)

    # 2. Load local .env (server/app/.env) second, with override
    # This ensures that project-specific settings in the local .env take precedence
    # over system environment variables, which is important when switching projects.
    local_env = Path(__file__).with_name(".env")
    if local_env.exists():
        load_dotenv(dotenv_path=local_env, override=True)

    _LOADED = True
