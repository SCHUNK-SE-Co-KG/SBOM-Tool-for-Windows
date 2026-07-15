# Tests – SBOM Tool for Windows

## Overview

| Layer | Framework | Scope |
|-------|-----------|-------|
| PowerShell | [Pester](https://pester.dev/) 5+ | Script syntax, compare report generation |
| Python | pytest | Security scanner, CycloneDX validation, tool SBOM |

## Quick start (Windows)

```cmd
cd tests
run_tests.bat
```

## Manual

```cmd
pip install -r tests/requirements.txt -r ../security/requirements.txt
python -m pytest tests/test_security.py tests/test_cyclonedx.py -v

powershell -ExecutionPolicy Bypass -Command "Install-Module Pester -RequiredVersion 5.7.1 -Force -SkipPublisherCheck -Scope CurrentUser; Import-Module Pester -RequiredVersion 5.7.1 -Force; $c = New-PesterConfiguration; $c.Run.Path = 'tests/test_sbom.Tests.ps1'; Invoke-Pester -Configuration $c"
```

## Fixtures

| File | Purpose |
|------|---------|
| `fixtures/baseline.cdx.json` | Baseline SBOM for compare tests |
| `fixtures/current.cdx.json` | Changed SBOM (version diff, added, removed) |
| `fixtures/approved-differences.json` | Approved version rules for compare test |

## CI

GitHub Actions workflow `.github/workflows/tests.yml` runs on `ubuntu-latest` (Python, CycloneDX, tool SBOM) and `windows-latest` (Pester, PSScriptAnalyzer).

Other workflows: Trivy, CVE-Scan, CodeQL, Release (see root README).
