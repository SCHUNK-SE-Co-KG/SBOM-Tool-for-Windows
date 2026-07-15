# SBOM Tool for Windows

**Portable Software Bill of Materials generator for installed Windows systems — CRA / BSI TR-03183-2 compliant (CycloneDX 1.6)**

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Tests](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/tests.yml/badge.svg?branch=main)
![Trivy Scan](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/trivy-scan.yml/badge.svg?branch=main)
![CVE-Scan](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/cve-scan.yml/badge.svg?branch=main)
![CodeQL](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/codeql.yml/badge.svg?branch=main)
![Release](https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows/actions/workflows/release.yml/badge.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE.svg)
![CycloneDX](https://img.shields.io/badge/CycloneDX-1.6-green.svg)

The **EU Cyber Resilience Act (CRA)** requires manufacturers to document software components, manage vulnerabilities, and maintain traceability across the product lifecycle. This tool generates a complete **SBOM** from any Windows 10/11 machine — without installation, without admin rights, and without internet access.

Developed by **SCHUNK Electronic Solutions GmbH** for internal CRA compliance workflows (machines, workstations, build images).

---

## Table of contents

- [CRA context](#cra-context)
- [Features](#features)
- [Quick start](#quick-start)
- [SBOM comparison](#sbom-comparison)
- [Project structure](#project-structure)
- [Output files](#output-files)
- [Parameters](#parameters)
- [BSI TR-03183-2 coverage](#bsi-tr-03183-2-coverage)
- [CVE monitoring (Due diligence)](#cve-monitoring-due-diligence)
- [Test suite](#test-suite)
- [Contributing](#contributing)
- [License](#license)

---

## CRA context

| CRA requirement | Tool support |
|-----------------|--------------|
| **SBOM / component documentation** (Annex I, Part II) | CycloneDX 1.6 JSON with name, version, supplier, PURL, hashes |
| **Vulnerability identification** (Art. 13) | SBOM diff comparator + automated CVE/Trivy scans of repo dependencies |
| **Traceability** | Timestamped reports, hostname-based filenames, compare baseline vs. current |
| **Due diligence on third-party components** | Daily OSV + Trivy scans via GitHub Actions |

> This tool supports SBOM **creation and comparison**. Full CRA compliance requires additional organizational processes (incident reporting, patch management, etc.).

---

## Features

| Feature | Description |
|---------|-------------|
| **Windows SBOM scan** | OS, patches, registry apps, Store apps, features, drivers |
| **CycloneDX 1.6** | BSI TR-03183-2 v2.1.0 compliant JSON output |
| **HTML report** | Sortable tables, search, DE/EN language toggle |
| **Text summary** | Compact statistics (bilingual DE/EN) |
| **SBOM compare** | 3-column diff with traffic-light status |
| **Approved differences** | Maintainable JSON rules for accepted version changes |
| **Portable** | Copy folder to USB — no install required |
| **License database** | ~370 known products mapped to SPDX IDs |

### Compare traffic lights

| Color | Meaning |
|-------|---------|
| Green | Unchanged |
| Orange | Version difference |
| Purple | Approved version difference |
| Red | Newly added |
| Gray | Removed |

---

## Quick start

### Requirements

- Windows 10 / 11
- PowerShell 5.1 (pre-installed)
- No admin rights required (driver scan may find more with admin)
- No internet required for SBOM generation

### Generate SBOM

```powershell
git clone https://github.com/SCHUNK-SE-Co-KG/SBOM-Tool-for-Windows.git
cd SBOM-Tool-for-Windows
```

**Option A:** Double-click `SBOM-Erstellen.cmd` (full scan with `-All`)

**Option B:** PowerShell

```powershell
.\Get-WindowsSBOM.ps1 -All
```

Output appears in `.\sbom-output\` (3 files per run: `.cdx.json`, `.html`, `.txt`).

---

## SBOM comparison

Compare an old baseline SBOM with a new one:

```powershell
.\Compare-WindowsSBOM.ps1 -Source1 .\sbom-output\baseline.cdx.json -Source2 .\sbom-output\current.cdx.json
```

Or double-click `SBOM-Vergleichen.cmd` and select both files.

**Maintain approved version differences:**

1. Edit `SBOM-Approved-Differences.json`, or
2. In the HTML report: click **Genehmigen** on orange rows → **Export JSON**

---

## Project structure

```
SBOM-Tool-for-Windows/
├── Get-WindowsSBOM.ps1           # Main SBOM generator (v3.0)
├── Compare-WindowsSBOM.ps1       # Compare two CycloneDX files → HTML report
├── SBOM-Erstellen.cmd            # One-click full scan (DE)
├── SBOM-Win-Create.cmd             # One-click full scan (EN filename)
├── SBOM-Vergleichen.cmd            # One-click compare launcher
├── SBOM-Vergleichen.html           # Standalone compare UI (browser)
├── SBOM-Approved-Differences.json  # Approved version rules
├── tests/                          # Pester + pytest tests
│   ├── fixtures/                   # Sample CycloneDX files
│   ├── test_sbom.ps1
│   ├── test_security.py
│   └── run_tests.bat
├── security/                       # CVE / Trivy tooling
│   ├── cve_scanner.py              # OSV API scanner
│   ├── generate_tool_sbom.py       # Tool dependency SBOM (CycloneDX 1.6)
│   ├── parse_trivy_report.py       # Trivy JSON → Markdown
│   └── reports/                    # Generated scan reports
└── .github/workflows/              # CI: tests, CVE scan, Trivy, CodeQL, release
```

---

## Output files

Per run in `sbom-output/`:

| File | Description |
|------|-------------|
| `HOSTNAME-sbom-DATE.cdx.json` | CycloneDX 1.6 (machine-readable) |
| `HOSTNAME-sbom-DATE.html` | Interactive HTML report (DE/EN) |
| `HOSTNAME-sbom-DATE.txt` | Text summary (DE/EN) |

---

## Parameters

```powershell
.\Get-WindowsSBOM.ps1                      # OS + updates + registry apps
.\Get-WindowsSBOM.ps1 -All                 # Everything (same as SBOM-Erstellen.cmd)
.\Get-WindowsSBOM.ps1 -IncludeDrivers      # Include drivers
.\Get-WindowsSBOM.ps1 -IncludeStoreApps    # Include Store apps
.\Get-WindowsSBOM.ps1 -IncludeFeatures     # Include Windows features
.\Get-WindowsSBOM.ps1 -OutputDir "C:\SBOM" # Custom output path
```

---

## BSI TR-03183-2 coverage

| Field | Status |
|-------|--------|
| Component name, version, supplier | OK |
| Distribution licences (SPDX / NOASSERTION) | OK |
| SHA-512 hash (where EXE reachable) | OK |
| Filename, executable/archive/structured properties | OK |
| Dependencies (patches/features/drivers → OS) | OK |
| PURL | OK |
| SBOM creator metadata + timestamp | OK |

---

## CVE monitoring (Due diligence)

Automated security scanning — same pattern as [TARATool](https://github.com/SCHUNK-SE-Co-KG/TARATool):

| Component | Description |
|-----------|-------------|
| `security/cve_scanner.py` | Python/OSV API scan of test + security dependencies |
| `security/generate_tool_sbom.py` | CycloneDX 1.6 SBOM of this tool's Python dependencies |
| `.github/workflows/tests.yml` | Pester, pytest, CycloneDX validation, PSScriptAnalyzer, tool SBOM |
| `.github/workflows/cve-scan.yml` | Daily scan at 06:00 UTC |
| `.github/workflows/cve-monthly-report.yml` | Monthly GitHub issue with full report |
| `.github/workflows/trivy-scan.yml` | Trivy filesystem + pip scan (CRITICAL/HIGH) |
| `.github/workflows/codeql.yml` | CodeQL static analysis (Python) |
| `.github/workflows/release.yml` | Portable ZIP on version tags (`v*`) |
| `.github/dependabot.yml` | Weekly dependency updates (pip, GitHub Actions) |

### Manual scan

```bash
pip install -r security/requirements.txt
python security/cve_scanner.py
```

Reports: `security/reports/cve_report.md`, `security/reports/trivy_report.md`

---

## Test suite

```cmd
cd tests
run_tests.bat
```

| Layer | Tests |
|-------|-------|
| Pester (Windows) | Script syntax, compare report from fixtures |
| pytest | Fixture validation, CVE scanner smoke test |

See [tests/README.md](tests/README.md) for details.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Run tests: `tests\run_tests.bat`
4. Commit and push
5. Open a Pull Request

---

## License

**GNU General Public License v3.0** — see [LICENSE](LICENSE).

```
SBOM Tool for Windows
Copyright (C) 2026 SCHUNK SE & Co. KG
```

---

## Contact

**SCHUNK Electronic Solutions GmbH**  
Am Tannwald 17, 78112 St. Georgen im Schwarzwald, Germany  
Tel. +49-7725-9166-0 · electronic-solutions@de.schunk.com  
https://www.ses-support.de
