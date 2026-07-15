"""CycloneDX 1.6 schema validation tests."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from cyclonedx.schema import SchemaVersion
from cyclonedx.validation.json import JsonStrictValidator

ROOT = Path(__file__).resolve().parent.parent
FIXTURES = Path(__file__).resolve().parent / "fixtures"
TOOL_SBOM = ROOT / "security" / "reports" / "tool-sbom.cdx.json"
VALIDATOR = JsonStrictValidator(SchemaVersion.V1_6)


def _assert_valid_cyclonedx(path: Path) -> None:
    assert path.is_file(), f"Missing SBOM file: {path}"
    payload = path.read_text(encoding="utf-8")
    errors = VALIDATOR.validate_str(payload)
    assert errors is None, f"{path.name} failed schema validation: {errors}"


@pytest.mark.parametrize(
    "fixture_name",
    ["baseline.cdx.json", "current.cdx.json"],
)
def test_fixture_validates_against_cyclonedx_1_6(fixture_name: str) -> None:
    _assert_valid_cyclonedx(FIXTURES / fixture_name)


def test_tool_sbom_validates_when_present() -> None:
    if not TOOL_SBOM.is_file():
        pytest.skip("tool-sbom.cdx.json not generated yet")
    _assert_valid_cyclonedx(TOOL_SBOM)


def test_fixture_has_required_cyclonedx_fields() -> None:
    data = json.loads((FIXTURES / "baseline.cdx.json").read_text(encoding="utf-8"))
    assert data["bomFormat"] == "CycloneDX"
    assert data["specVersion"] == "1.6"
    assert "components" in data
    assert "metadata" in data
