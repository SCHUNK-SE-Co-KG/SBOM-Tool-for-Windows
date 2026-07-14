"""Python tests for security tooling."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FIXTURES = Path(__file__).resolve().parent / "fixtures"


def test_baseline_fixture_structure():
    data = json.loads((FIXTURES / "baseline.cdx.json").read_text(encoding="utf-8"))
    assert data["bomFormat"] == "CycloneDX"
    assert data["specVersion"] == "1.6"
    assert len(data["components"]) >= 3


def test_current_fixture_has_expected_diffs():
    baseline = json.loads((FIXTURES / "baseline.cdx.json").read_text(encoding="utf-8"))
    current = json.loads((FIXTURES / "current.cdx.json").read_text(encoding="utf-8"))
    b_names = {c["name"] for c in baseline["components"]}
    c_names = {c["name"] for c in current["components"]}
    assert "Legacy Tool" in b_names - c_names
    assert "New Application" in c_names - b_names


def test_cve_scanner_runs_json_only():
    result = subprocess.run(
        [sys.executable, str(ROOT / "security" / "cve_scanner.py"), "--json-only"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=60,
    )
    assert result.returncode in (0, 1)
    payload = json.loads(result.stdout)
    assert payload["repository"] == "SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows"
    assert "dependencies_scanned" in payload
