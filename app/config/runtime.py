"""Environment-backed configuration helpers with safe local defaults."""

from __future__ import annotations

import os
from pathlib import Path


def environment_path(name: str, default: Path) -> Path:
    """Return an environment-provided path or the established default."""

    value = os.getenv(name)
    return Path(value).expanduser() if value else default


def environment_string(name: str, default: str) -> str:
    """Return an environment-provided string or the established default."""

    return os.getenv(name, default)
