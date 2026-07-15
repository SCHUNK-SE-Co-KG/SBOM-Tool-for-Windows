#!/usr/bin/env python3
"""
Generate a CycloneDX 1.6 SBOM for this tool's Python dependencies
(tests/requirements.txt + security/requirements.txt).
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPORT_DIR = ROOT / "security" / "reports"
OUTPUT = REPORT_DIR / "tool-sbom.cdx.json"
REQ_FILES = [
    ROOT / "tests" / "requirements.txt",
    ROOT / "security" / "requirements.txt",
]


def merge_requirements() -> str:
    lines: list[str] = []
    seen: set[str] = set()
    for path in REQ_FILES:
        if not path.is_file():
            continue
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            key = line.split("#", 1)[0].strip().lower()
            if key and key not in seen:
                seen.add(key)
                lines.append(line)
    return "\n".join(lines) + "\n"


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8") as tmp:
        tmp.write(merge_requirements())
        merged = Path(tmp.name)

    cmd = [
        sys.executable,
        "-m",
        "cyclonedx_py",
        "requirements",
        str(merged),
        "--output-format",
        "JSON",
        "--sv",
        "1.6",
        "-o",
        str(OUTPUT),
    ]
    try:
        subprocess.run(cmd, check=True, cwd=ROOT)
    finally:
        merged.unlink(missing_ok=True)

    print(f"Tool SBOM written: {OUTPUT}")
    print(f"Generated: {datetime.now(timezone.utc).isoformat()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
