# Tests – SBOM Tool for Windows

## Overview

| Layer | Framework | Scope |
|-------|-----------|-------|
| PowerShell | [Pester](https://pester.dev/) 5+ | Script syntax, compare report generation |
| Python | pytest | Security scanner, JSON fixtures |

## Quick start (Windows)

```cmd
cd tests
run_tests.bat
```

## Manual

```cmd
pip install -r tests/requirements.txt -r ../security/requirements.txt
python -m pytest tests/test_security.py -v

powershell -ExecutionPolicy Bypass -Command "Install-Module Pester -Force; Invoke-Pester tests/test_sbom.ps1"
```

## Fixtures

| File | Purpose |
|------|---------|
| `fixtures/baseline.cdx.json` | Baseline SBOM for compare tests |
| `fixtures/current.cdx.json` | Changed SBOM (version diff, added, removed) |
| `fixtures/approved-differences.json` | Approved version rules for compare test |

## CI

GitHub Actions workflow `.github/workflows/tests.yml` runs on `ubuntu-latest` (Python) and `windows-latest` (Pester).
